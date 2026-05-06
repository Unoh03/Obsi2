#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# =====================================================
# Promtail client non-interactive preset setup script 5.6
#
# 목적:
# - promtail-client(5.6).sh 원본은 대화형 설정용으로 그대로 둔다.
# - 이 파일은 web(5.6).sh 같은 통합 스크립트에서 멈춤 없이 호출하기 위한 비대화형 버전이다.
# - 서버 역할별 preset으로 Promtail 설정을 만들고 Loki로 로그를 보낸다.
#
# 실행 예시:
#   sudo PROMTAIL_PRESET=web bash 'promtail-client-auto(5.6).sh'
#   sudo PROMTAIL_PRESET=lb HOST_LABEL=lb1 bash 'promtail-client-auto(5.6).sh'
#
# 기본 Loki push URL:
#   http://1.2.3.3:3100/loki/api/v1/push
#
# 지원 preset:
# - web: system log + Tomcat log
# - lb: system log + nginx log
# - dns: system log + bind/named log 후보
# - db: system log + mysql/mariadb log 후보
# - nfs: system log + nfs-ha sync log
# - system: /var/log/*.log 만 수집
#
# 원본 보존 원칙:
# - promtail-client(5.6).sh는 수정하지 않는다.
# - 자동화가 필요한 곳에서는 이 파일을 호출한다.
# =====================================================

PROMTAIL_VERSION="${PROMTAIL_VERSION:-2.9.0}"
PROMTAIL_DOWNLOAD_URL="${PROMTAIL_DOWNLOAD_URL:-https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip}"
LOKI_PUSH_URL="${LOKI_PUSH_URL:-http://1.2.3.3:3100/loki/api/v1/push}"

PROMTAIL_PRESET="${PROMTAIL_PRESET:-system}"
HOST_LABEL="${HOST_LABEL:-$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo server)}"
ROLE_LABEL="${ROLE_LABEL:-${PROMTAIL_PRESET}}"

PROMTAIL_BIN="${PROMTAIL_BIN:-/usr/local/bin/promtail}"
PROMTAIL_CONFIG="${PROMTAIL_CONFIG:-/etc/promtail/promtail-config.yaml}"
PROMTAIL_SERVICE="${PROMTAIL_SERVICE:-/etc/systemd/system/promtail.service}"
POSITIONS_FILE="${POSITIONS_FILE:-/var/lib/promtail/positions.yaml}"

TOMCAT_HOME="${TOMCAT_HOME:-/opt/tomcat/tomcat-10}"
BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/zzaphub-promtail-client-auto}"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_ROOT}/${RUN_ID}"

INSTALL_NODE_EXPORTER="${INSTALL_NODE_EXPORTER:-1}"
CHECK_LOKI_READY="${CHECK_LOKI_READY:-1}"

JOB_NAMES=()
JOB_LABELS=()
LOG_PATHS=()

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

require_root() {
    if [ "${EUID}" -ne 0 ]; then
        die "root 권한이 필요합니다. 예: sudo PROMTAIL_PRESET=web bash '$0'"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

validate_label_value() {
    local name="$1"
    local value="$2"

    case "${value}" in
        *\"*|*$'\n'*|*$'\r'*)
            die "${name} 값에는 큰따옴표나 줄바꿈을 넣을 수 없습니다: ${value}"
            ;;
    esac
}

validate_job_name() {
    local value="$1"

    case "${value}" in
        *[!A-Za-z0-9._-]*|"")
            die "job_name은 영문/숫자/점/밑줄/하이픈만 사용합니다. 현재 값: ${value}"
            ;;
    esac
}

validate_loki_push_url() {
    case "$1" in
        http://*/loki/api/v1/push|https://*/loki/api/v1/push)
            ;;
        *)
            die "Loki push URL 형식이 이상합니다: $1"
            ;;
    esac
}

loki_ready_url() {
    printf '%s' "${LOKI_PUSH_URL%/loki/api/v1/push}/ready"
}

add_job() {
    local job_name="$1"
    local job_label="$2"
    local log_path="$3"

    validate_job_name "${job_name}"
    validate_label_value "job label" "${job_label}"
    validate_label_value "log path" "${log_path}"

    JOB_NAMES+=("${job_name}")
    JOB_LABELS+=("${job_label}")
    LOG_PATHS+=("${log_path}")
}

check_log_path_glob() {
    local log_path="$1"

    if compgen -G "${log_path}" >/dev/null; then
        log "로그 경로 확인됨: ${log_path}"
    else
        warn "현재 매칭되는 로그 파일이 없습니다: ${log_path}"
        warn "서비스가 아직 로그를 만들지 않았거나 경로가 다를 수 있습니다."
    fi
}

backup_file() {
    local file_path="$1"
    local backup_path

    [ -e "${file_path}" ] || return 0

    install -d -m 700 -o root -g root "${BACKUP_DIR}"
    backup_path="${BACKUP_DIR}/$(printf '%s' "${file_path#/}" | tr '/ ' '__').bak"
    cp -a "${file_path}" "${backup_path}"
    chmod 600 "${backup_path}" 2>/dev/null || true
    log "기존 파일 백업: ${backup_path}"
}

add_common_system_logs() {
    add_job "system" "varlogs" "/var/log/*.log"
}

collect_preset_jobs() {
    case "${PROMTAIL_PRESET}" in
        web)
            add_common_system_logs
            add_job "tomcat" "tomcat-log" "${TOMCAT_HOME}/logs/*.log"
            add_job "tomcat_out" "tomcat-out" "${TOMCAT_HOME}/logs/catalina.out"
            ;;
        lb)
            add_common_system_logs
            add_job "nginx" "nginx-log" "/var/log/nginx/*.log"
            ;;
        dns)
            add_common_system_logs
            add_job "bind" "dns-log" "/var/log/bind/*.log"
            add_job "named" "named-log" "/var/log/named/*.log"
            ;;
        db)
            add_common_system_logs
            add_job "mysql" "mysql-log" "/var/log/mysql/*.log"
            add_job "mariadb" "mariadb-log" "/var/log/mysql/error.log"
            ;;
        nfs)
            add_common_system_logs
            add_job "nfs_ha_sync" "nfs-ha-sync" "/var/log/nfs-ha-sync.log"
            ;;
        system)
            add_common_system_logs
            ;;
        *)
            die "지원하지 않는 PROMTAIL_PRESET입니다: ${PROMTAIL_PRESET}"
            ;;
    esac

    if [ -n "${PROMTAIL_EXTRA_LOGS:-}" ]; then
        add_extra_logs "${PROMTAIL_EXTRA_LOGS}"
    fi
}

add_extra_logs() {
    local spec_string="$1"
    local old_ifs="$IFS"
    local spec
    local job_name
    local job_label
    local log_path

    IFS=';'
    for spec in ${spec_string}; do
        IFS="${old_ifs}"
        [ -n "${spec}" ] || continue

        job_name="${spec%%:*}"
        spec="${spec#*:}"
        job_label="${spec%%:*}"
        log_path="${spec#*:}"

        if [ -z "${job_name}" ] || [ -z "${job_label}" ] || [ -z "${log_path}" ] || [ "${job_label}" = "${log_path}" ]; then
            die "PROMTAIL_EXTRA_LOGS 형식은 job_name:job_label:/path/*.log;... 입니다."
        fi

        add_job "${job_name}" "${job_label}" "${log_path}"
        IFS=';'
    done
    IFS="${old_ifs}"
}

write_config_to() {
    local output_file="$1"
    local i

    install -d -m 755 "$(dirname "${POSITIONS_FILE}")"

    cat > "${output_file}" <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: ${POSITIONS_FILE}

clients:
  - url: "${LOKI_PUSH_URL}"

scrape_configs:
EOF

    for i in "${!JOB_NAMES[@]}"; do
        cat >> "${output_file}" <<EOF
  - job_name: "${JOB_NAMES[$i]}"
    static_configs:
      - targets:
          - localhost
        labels:
          job: "${JOB_LABELS[$i]}"
          host: "${HOST_LABEL}"
          role: "${ROLE_LABEL}"
          __path__: "${LOG_PATHS[$i]}"

EOF
    done
}

install_promtail_binary() {
    local temp_dir

    log "패키지 설치: unzip wget"
    apt update
    apt install -y unzip wget

    if command_exists promtail; then
        log "기존 Promtail 확인:"
        promtail --version || true
    fi

    temp_dir="$(mktemp -d)"

    log "Promtail v${PROMTAIL_VERSION} 다운로드: ${PROMTAIL_DOWNLOAD_URL}"
    if ! (
        cd "${temp_dir}"
        wget -O promtail-linux-amd64.zip "${PROMTAIL_DOWNLOAD_URL}"
        unzip -o promtail-linux-amd64.zip
        install -m 755 promtail-linux-amd64 "${PROMTAIL_BIN}"
    ); then
        rm -rf "${temp_dir}"
        die "Promtail 다운로드 또는 설치에 실패했습니다."
    fi

    rm -rf "${temp_dir}"

    log "Promtail 설치 확인:"
    "${PROMTAIL_BIN}" --version
}

write_promtail_files() {
    local config_tmp="$1"

    log "Promtail 설정 디렉터리 생성"
    install -d -m 755 "$(dirname "${PROMTAIL_CONFIG}")"

    backup_file "${PROMTAIL_CONFIG}"
    cp "${config_tmp}" "${PROMTAIL_CONFIG}"
    chmod 644 "${PROMTAIL_CONFIG}"
    log "설정 파일 작성: ${PROMTAIL_CONFIG}"

    backup_file "${PROMTAIL_SERVICE}"
    cat > "${PROMTAIL_SERVICE}" <<EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=root
ExecStart=${PROMTAIL_BIN} -config.file=${PROMTAIL_CONFIG}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 "${PROMTAIL_SERVICE}"
    log "systemd 서비스 작성: ${PROMTAIL_SERVICE}"
}

install_node_exporter_if_requested() {
    if [ "${INSTALL_NODE_EXPORTER}" != "1" ]; then
        warn "INSTALL_NODE_EXPORTER=0 이므로 node_exporter 설치를 건너뜁니다."
        return 0
    fi

    log "Prometheus node_exporter를 설치/시작합니다."
    apt install -y prometheus-node-exporter
    systemctl enable --now prometheus-node-exporter
    systemctl restart prometheus-node-exporter
}

check_loki_connection() {
    local ready_url

    if [ "${CHECK_LOKI_READY}" != "1" ]; then
        warn "CHECK_LOKI_READY=0 이므로 Loki /ready 확인을 건너뜁니다."
        return 0
    fi

    ready_url="$(loki_ready_url)"

    log "Loki 연결 확인: ${ready_url}"
    if wget -qO- --timeout=5 "${ready_url}" >/dev/null 2>&1; then
        log "Loki /ready 응답 확인됨"
    else
        warn "Loki /ready 확인 실패"
        warn "Loki 서버 상태, B-R/C-R ACL, Log 서버 방화벽 3100/tcp를 확인해야 합니다."
    fi
}

start_service() {
    log "Promtail 서비스 반영 및 시작"
    systemctl daemon-reload
    systemctl enable promtail
    systemctl restart promtail
    systemctl --no-pager --full status promtail || true
}

print_result() {
    echo "[SUCCESS] Promtail 자동 preset 설정 완료"
    echo "[INFO] preset=${PROMTAIL_PRESET}, host=${HOST_LABEL}, role=${ROLE_LABEL}"
    echo "[INFO] Loki push URL=${LOKI_PUSH_URL}"
    echo "[INFO] 확인 명령:"
    echo "       systemctl status promtail --no-pager"
    echo "       tail -n 50 /var/log/syslog | grep promtail"
    echo "       logger \"Hello Loki Test from ${HOST_LABEL}\""
    echo "[INFO] Grafana Explore query:"
    echo "       {host=\"${HOST_LABEL}\"}"
    echo "       {role=\"${ROLE_LABEL}\"}"
}

main() {
    local config_tmp
    local path

    require_root
    validate_loki_push_url "${LOKI_PUSH_URL}"
    validate_label_value "host label" "${HOST_LABEL}"
    validate_label_value "role label" "${ROLE_LABEL}"

    log "Promtail 자동 설정 시작"
    log "PROMTAIL_PRESET=${PROMTAIL_PRESET}"
    log "HOST_LABEL=${HOST_LABEL}"
    log "LOKI_PUSH_URL=${LOKI_PUSH_URL}"

    collect_preset_jobs

    for path in "${LOG_PATHS[@]}"; do
        check_log_path_glob "${path}"
    done

    config_tmp="$(mktemp)"
    trap 'rm -f "${config_tmp}"' EXIT

    write_config_to "${config_tmp}"
    install_promtail_binary
    write_promtail_files "${config_tmp}"
    start_service
    install_node_exporter_if_requested
    check_loki_connection
    print_result
}

main "$@"

