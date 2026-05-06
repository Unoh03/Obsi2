#!/usr/bin/env bash

# Zzaphub Log Stack Setup Script 5.6
#
# 목적:
#   Loki 로그 서버와 Promtail 로그 수집 에이전트를 설치/설정한다.
#   한 파일에서 loki, promtail, all, status 모드를 지원한다.
#
# 실행 예시:
#   Log 서버에 Loki만 설치:
#     sudo bash './log-stack(5.6).sh' loki
#
#   Log 서버에 Loki + Promtail 함께 설치:
#     sudo env ROLE=log HOST_NAME=log-server bash './log-stack(5.6).sh' all
#
#   WEB 서버에 Promtail만 설치:
#     sudo env ROLE=web HOST_NAME=web1 bash './log-stack(5.6).sh' promtail
#
#   상태 확인:
#     bash './log-stack(5.6).sh' status
#
# 기본 토폴로지:
#   Log/Loki 서버: 192.168.3.3, NAT 역할 IP 1.2.3.3
#   Monitor/Grafana 서버: 192.168.3.4
#   기본 Promtail push URL: http://1.2.3.3:3100/loki/api/v1/push
#
# 주의:
#   UFW와 라우터 ACL은 자동 변경하지 않는다.
#   방화벽/ACL은 status 출력의 안내를 보고 별도로 확인한다.

set -Eeuo pipefail
IFS=$'\n\t'

MODE="${1:-}"

LOKI_VERSION="${LOKI_VERSION:-2.9.0}"
LOKI_URL="${LOKI_URL:-http://1.2.3.3:3100}"
LOKI_PUSH_URL="${LOKI_PUSH_URL:-${LOKI_URL%/}/loki/api/v1/push}"
LOKI_DATA_DIR="${LOKI_DATA_DIR:-/var/lib/loki}"
LOKI_CONFIG="${LOKI_CONFIG:-/etc/loki/loki-config.yaml}"
LOKI_SERVICE_FILE="${LOKI_SERVICE_FILE:-/etc/systemd/system/loki.service}"
LOKI_BIND_ADDR="${LOKI_BIND_ADDR:-0.0.0.0}"
LOKI_HTTP_PORT="${LOKI_HTTP_PORT:-3100}"
LOKI_GRPC_PORT="${LOKI_GRPC_PORT:-9096}"

PROMTAIL_CONFIG="${PROMTAIL_CONFIG:-/etc/promtail/promtail-config.yaml}"
PROMTAIL_SERVICE_FILE="${PROMTAIL_SERVICE_FILE:-/etc/systemd/system/promtail.service}"
PROMTAIL_DATA_DIR="${PROMTAIL_DATA_DIR:-/var/lib/promtail}"
PROMTAIL_POSITIONS_FILE="${PROMTAIL_POSITIONS_FILE:-${PROMTAIL_DATA_DIR}/positions.yaml}"
PROMTAIL_HTTP_PORT="${PROMTAIL_HTTP_PORT:-9080}"

ROLE="${ROLE:-}"
HOST_NAME="${HOST_NAME:-$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo unknown-host)}"
EXTRA_LOG_PATHS="${EXTRA_LOG_PATHS:-}"

BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/zzaphub-log-stack}"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_ROOT}/${RUN_ID}"

log() {
    echo "[INFO] $*"
}

warn() {
    echo "[WARN] $*" >&2
}

die() {
    echo "[ERROR] $*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage:
  sudo bash './log-stack(5.6).sh' loki
  sudo env ROLE=web HOST_NAME=web1 bash './log-stack(5.6).sh' promtail
  sudo env ROLE=log HOST_NAME=log-server bash './log-stack(5.6).sh' all
  bash './log-stack(5.6).sh' status

Modes:
  loki      Install and configure Loki only.
  promtail  Install and configure Promtail only.
  all       Install and configure both Loki and Promtail.
  status    Show installed binaries, services, ports, config files, and UFW status.

Environment:
  LOKI_VERSION       Default: 2.9.0
  LOKI_URL           Default: http://1.2.3.3:3100
  LOKI_PUSH_URL      Default: ${LOKI_URL}/loki/api/v1/push
  LOKI_DATA_DIR      Default: /var/lib/loki
  ROLE               web|lb|db|dns|monitor|log|generic
  HOST_NAME          Default: hostname -s
  EXTRA_LOG_PATHS    Comma-separated extra log globs, e.g. /app/logs/*.log,/opt/app/*.out
EOF
}

require_root() {
    if [ "${EUID}" -ne 0 ]; then
        die "root 권한이 필요합니다. 예: sudo bash '$0' ${MODE}"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

normalize_role() {
    local value="${1:-generic}"
    value="$(printf '%s' "${value}" | tr '[:upper:]' '[:lower:]')"

    case "${value}" in
        web|lb|db|dns|monitor|log|generic)
            printf '%s' "${value}"
            ;;
        *)
            die "ROLE 값은 web, lb, db, dns, monitor, log, generic 중 하나여야 합니다. 현재 값: ${value}"
            ;;
    esac
}

sanitize_name() {
    printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-'
}

validate_yaml_value() {
    local name="$1"
    local value="$2"

    case "${value}" in
        *\"*|*$'\n'*|*$'\r'*)
            die "${name} 값에는 큰따옴표나 줄바꿈을 넣을 수 없습니다: ${value}"
            ;;
    esac
}

prepare_backup_dir() {
    install -d -m 700 -o root -g root "${BACKUP_DIR}"
}

backup_name() {
    local path="$1"
    printf '%s' "${path#/}" | tr '/ ' '__' | tr -c 'A-Za-z0-9._-' '_'
}

backup_file() {
    local path="$1"
    local target

    [ -e "${path}" ] || return 0

    prepare_backup_dir
    target="${BACKUP_DIR}/$(backup_name "${path}").bak"
    cp -a "${path}" "${target}"
    chown root:root "${target}" 2>/dev/null || true
    chmod 600 "${target}" 2>/dev/null || true
    log "백업 생성: ${target}"
}

install_packages() {
    log "필수 패키지를 설치합니다."
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl unzip wget
}

install_release_binary() {
    local name="$1"
    local zip_name="$2"
    local binary_name="$3"
    local url="$4"
    local tmp_dir

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' EXIT
    log "${name} ${LOKI_VERSION} 다운로드: ${url}"

    (
        cd "${tmp_dir}"
        wget -O "${zip_name}" "${url}"
        unzip -o "${zip_name}"
        install -m 755 "${binary_name}" "/usr/local/bin/${name}"
    )

    rm -rf "${tmp_dir}"
    trap - EXIT
    "/usr/local/bin/${name}" --version || warn "${name} 버전 확인 명령이 실패했습니다."
}

install_loki_binary() {
    install_release_binary \
        "loki" \
        "loki-linux-amd64.zip" \
        "loki-linux-amd64" \
        "https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip"
}

install_promtail_binary() {
    install_release_binary \
        "promtail" \
        "promtail-linux-amd64.zip" \
        "promtail-linux-amd64" \
        "https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/promtail-linux-amd64.zip"
}

write_loki_config() {
    log "Loki 설정을 작성합니다: ${LOKI_CONFIG}"
    install -d -m 755 "$(dirname "${LOKI_CONFIG}")"
    install -d -m 755 \
        "${LOKI_DATA_DIR}" \
        "${LOKI_DATA_DIR}/chunks" \
        "${LOKI_DATA_DIR}/rules" \
        "${LOKI_DATA_DIR}/rules-temp" \
        "${LOKI_DATA_DIR}/tsdb-index" \
        "${LOKI_DATA_DIR}/tsdb-cache" \
        "${LOKI_DATA_DIR}/compactor"

    backup_file "${LOKI_CONFIG}"

    cat > "${LOKI_CONFIG}" <<EOF
auth_enabled: false

server:
  http_listen_address: ${LOKI_BIND_ADDR}
  http_listen_port: ${LOKI_HTTP_PORT}
  grpc_listen_port: ${LOKI_GRPC_PORT}

common:
  instance_addr: 127.0.0.1
  path_prefix: ${LOKI_DATA_DIR}
  storage:
    filesystem:
      chunks_directory: ${LOKI_DATA_DIR}/chunks
      rules_directory: ${LOKI_DATA_DIR}/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

query_range:
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 100

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

storage_config:
  tsdb_shipper:
    active_index_directory: ${LOKI_DATA_DIR}/tsdb-index
    cache_location: ${LOKI_DATA_DIR}/tsdb-cache

compactor:
  working_directory: ${LOKI_DATA_DIR}/compactor

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h

ruler:
  storage:
    type: local
    local:
      directory: ${LOKI_DATA_DIR}/rules
  rule_path: ${LOKI_DATA_DIR}/rules-temp
  alertmanager_url: http://localhost:9093
EOF
}

write_loki_service() {
    log "Loki systemd 서비스를 작성합니다: ${LOKI_SERVICE_FILE}"
    backup_file "${LOKI_SERVICE_FILE}"

    cat > "${LOKI_SERVICE_FILE}" <<EOF
[Unit]
Description=Loki log aggregation service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/loki -config.file=${LOKI_CONFIG}
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
}

LOG_JOBS=()
LOG_PATHS=()

add_log_target() {
    local job="$1"
    local path="$2"
    local i

    [ -n "${path}" ] || return 0
    validate_yaml_value "로그 경로" "${path}"

    for i in "${!LOG_PATHS[@]}"; do
        if [ "${LOG_JOBS[$i]}:${LOG_PATHS[$i]}" = "${job}:${path}" ]; then
            return 0
        fi
    done

    LOG_JOBS+=("${job}")
    LOG_PATHS+=("${path}")
}

build_promtail_targets() {
    local role="$1"
    local extra
    local extra_path

    LOG_JOBS=()
    LOG_PATHS=()

    add_log_target "varlogs" "/var/log/*.log"
    add_log_target "syslog" "/var/log/syslog"

    case "${role}" in
        web)
            add_log_target "nginx" "/var/log/nginx/*.log"
            add_log_target "tomcat" "/opt/tomcat/tomcat-10/logs/*.log"
            add_log_target "tomcat" "/opt/tomcat/tomcat-10/logs/catalina.out"
            ;;
        lb)
            add_log_target "nginx" "/var/log/nginx/*.log"
            ;;
        db)
            add_log_target "mysql" "/var/log/mysql/*.log"
            add_log_target "mariadb" "/var/log/mariadb/*.log"
            ;;
        dns)
            add_log_target "bind" "/var/log/bind/*.log"
            add_log_target "named" "/var/log/named/*.log"
            ;;
        monitor)
            add_log_target "grafana" "/var/log/grafana/*.log"
            add_log_target "prometheus" "/var/log/prometheus/*.log"
            add_log_target "loki" "/var/log/loki/*.log"
            ;;
        log)
            add_log_target "loki" "/var/log/loki/*.log"
            ;;
        generic)
            ;;
    esac

    if [ -n "${EXTRA_LOG_PATHS}" ]; then
        extra="${EXTRA_LOG_PATHS}"
        while [ -n "${extra}" ]; do
            if [[ "${extra}" == *,* ]]; then
                extra_path="${extra%%,*}"
                extra="${extra#*,}"
            else
                extra_path="${extra}"
                extra=""
            fi
            add_log_target "extra" "${extra_path}"
        done
    fi
}

write_promtail_job() {
    local config_file="$1"
    local job_name="$2"
    local job_label="$3"
    local role_label="$4"
    local path="$5"

    cat >> "${config_file}" <<EOF
  - job_name: "${job_name}"
    static_configs:
      - targets:
          - localhost
        labels:
          job: "${job_label}"
          host: "${HOST_NAME}"
          role: "${role_label}"
          __path__: "${path}"
EOF
}

write_promtail_config() {
    local role="$1"
    local role_safe
    local job_safe
    local i
    local index

    role_safe="$(sanitize_name "${role}")"
    validate_yaml_value "HOST_NAME" "${HOST_NAME}"
    validate_yaml_value "ROLE" "${role_safe}"
    validate_yaml_value "LOKI_PUSH_URL" "${LOKI_PUSH_URL}"

    build_promtail_targets "${role}"

    log "Promtail 설정을 작성합니다: ${PROMTAIL_CONFIG}"
    install -d -m 755 "$(dirname "${PROMTAIL_CONFIG}")" "${PROMTAIL_DATA_DIR}"
    backup_file "${PROMTAIL_CONFIG}"

    cat > "${PROMTAIL_CONFIG}" <<EOF
server:
  http_listen_port: ${PROMTAIL_HTTP_PORT}
  grpc_listen_port: 0

positions:
  filename: ${PROMTAIL_POSITIONS_FILE}

clients:
  - url: "${LOKI_PUSH_URL}"

scrape_configs:
EOF

    index=0
    for i in "${!LOG_PATHS[@]}"; do
        index=$((index + 1))
        job_safe="$(sanitize_name "${LOG_JOBS[$i]}")"
        write_promtail_job \
            "${PROMTAIL_CONFIG}" \
            "${role_safe}-${job_safe}-${index}" \
            "${LOG_JOBS[$i]}" \
            "${role_safe}" \
            "${LOG_PATHS[$i]}"
    done
}

write_promtail_service() {
    log "Promtail systemd 서비스를 작성합니다: ${PROMTAIL_SERVICE_FILE}"
    backup_file "${PROMTAIL_SERVICE_FILE}"

    cat > "${PROMTAIL_SERVICE_FILE}" <<EOF
[Unit]
Description=Promtail log shipping service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/promtail -config.file=${PROMTAIL_CONFIG}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
}

reload_and_restart_service() {
    local service_name="$1"

    log "systemd 반영 및 ${service_name} 재시작"
    systemctl daemon-reload
    systemctl enable "${service_name}"
    systemctl restart "${service_name}"
    systemctl --no-pager --full status "${service_name}" || true
}

print_firewall_note() {
    echo
    log "UFW/라우터 ACL은 자동 변경하지 않았습니다."
    if command_exists ufw; then
        echo "[INFO] 현재 UFW 상태:"
        ufw status || true
    else
        warn "ufw 명령을 찾지 못했습니다."
    fi

    cat <<'EOF'
[INFO] Loki 3100/tcp 접근이 막히면 Log 서버에서 아래 범위를 검토하세요.
       예시는 참고용이며, 실제 적용은 팀 ACL/UFW 정책에 맞춰 별도로 수행하세요.

  sudo ufw allow from 1.2.2.0/24 to any port 3100 proto tcp
  sudo ufw allow from 192.168.3.0/24 to any port 3100 proto tcp

[INFO] 라우터 ACL도 C APP/LB/WEB -> B Log(1.2.3.3:3100) 흐름을 허용해야 합니다.
EOF
}

install_loki() {
    install_packages
    install_loki_binary
    write_loki_config
    write_loki_service
    reload_and_restart_service "loki.service"
    print_firewall_note
}

install_promtail() {
    local role

    if [ -z "${ROLE}" ]; then
        ROLE="generic"
    fi
    role="$(normalize_role "${ROLE}")"

    install_packages
    install_promtail_binary
    write_promtail_config "${role}"
    write_promtail_service
    reload_and_restart_service "promtail.service"

    log "Promtail role=${role}, host=${HOST_NAME}, push=${LOKI_PUSH_URL}"
}

install_all() {
    if [ -z "${ROLE}" ]; then
        ROLE="log"
    fi

    install_packages
    install_loki_binary
    install_promtail_binary
    write_loki_config
    write_loki_service
    write_promtail_config "$(normalize_role "${ROLE}")"
    write_promtail_service

    log "systemd 반영 및 Loki/Promtail 재시작"
    systemctl daemon-reload
    systemctl enable loki.service promtail.service
    systemctl restart loki.service
    systemctl restart promtail.service
    systemctl --no-pager --full status loki.service || true
    systemctl --no-pager --full status promtail.service || true
    print_firewall_note
}

show_service_state() {
    local service_name="$1"

    if command_exists systemctl; then
        echo "[INFO] ${service_name}: $(systemctl is-active "${service_name}" 2>/dev/null || true)"
        systemctl --no-pager --full status "${service_name}" 2>/dev/null | sed -n '1,8p' || true
    else
        warn "systemctl 명령을 찾지 못했습니다."
    fi
}

show_status() {
    echo "[INFO] log-stack status"
    echo "[INFO] Loki URL: ${LOKI_URL}"
    echo "[INFO] Loki push URL: ${LOKI_PUSH_URL}"
    echo "[INFO] Host label: ${HOST_NAME}"
    echo

    if command_exists loki; then
        loki --version || true
    else
        warn "loki 바이너리를 찾지 못했습니다."
    fi

    if command_exists promtail; then
        promtail --version || true
    else
        warn "promtail 바이너리를 찾지 못했습니다."
    fi

    echo
    [ -f "${LOKI_CONFIG}" ] && echo "[INFO] Loki config exists: ${LOKI_CONFIG}" || warn "Loki config 없음: ${LOKI_CONFIG}"
    [ -f "${PROMTAIL_CONFIG}" ] && echo "[INFO] Promtail config exists: ${PROMTAIL_CONFIG}" || warn "Promtail config 없음: ${PROMTAIL_CONFIG}"

    echo
    show_service_state "loki.service"
    echo
    show_service_state "promtail.service"

    echo
    if command_exists ss; then
        echo "[INFO] 3100/9080 listen 확인:"
        ss -lntp 2>/dev/null | grep -E ':(3100|9080)[[:space:]]' || true
    else
        warn "ss 명령을 찾지 못했습니다."
    fi

    echo
    if command_exists curl; then
        echo "[INFO] Loki local ready endpoint 확인:"
        curl -fsS "http://127.0.0.1:${LOKI_HTTP_PORT}/ready" || true
        echo
        echo "[INFO] Loki configured URL ready endpoint 확인:"
        curl -fsS "${LOKI_URL%/}/ready" || true
        echo
    else
        warn "curl 명령을 찾지 못했습니다."
    fi

    print_firewall_note
}

main() {
    case "${MODE}" in
        loki)
            require_root
            install_loki
            ;;
        promtail)
            require_root
            install_promtail
            ;;
        all)
            require_root
            install_all
            ;;
        status)
            show_status
            ;;
        -h|--help|help|"")
            usage
            ;;
        *)
            usage
            die "알 수 없는 모드입니다: ${MODE}"
            ;;
    esac
}

main "$@"
