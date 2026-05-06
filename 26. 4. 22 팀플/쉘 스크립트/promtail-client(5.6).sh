#!/usr/bin/env bash

# Promtail client interactive setup script 5.6
#
# 목적:
#   각 서버에서 Promtail만 설치/설정한다.
#   Loki 서버 설정은 건드리지 않는다.
#
# 실행 대상:
#   WEB, LB, DB, DNS, Monitor 등 로그를 Loki로 보낼 서버.
#
# 기본 Loki push URL:
#   http://1.2.3.3:3100/loki/api/v1/push
#
# 실행:
#   sudo bash './promtail-client(5.6).sh'
#
# 핵심 원칙:
#   host, job_name, job label, __path__는 서버마다 다르므로 자동 추정하지 않는다.
#   실행 중 사용자가 입력한 값으로 설정 파일을 만들고, 반영 전 미리 보여준다.

set -Eeuo pipefail
IFS=$'\n\t'

PROMTAIL_VERSION="${PROMTAIL_VERSION:-2.9.0}"
DEFAULT_LOKI_PUSH_URL="${LOKI_PUSH_URL:-http://1.2.3.3:3100/loki/api/v1/push}"
PROMTAIL_BIN="${PROMTAIL_BIN:-/usr/local/bin/promtail}"
PROMTAIL_CONFIG="${PROMTAIL_CONFIG:-/etc/promtail/promtail-config.yaml}"
PROMTAIL_SERVICE="${PROMTAIL_SERVICE:-/etc/systemd/system/promtail.service}"
POSITIONS_FILE="${POSITIONS_FILE:-/tmp/positions.yaml}"
BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/zzaphub-promtail-client}"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${BACKUP_ROOT}/${RUN_ID}"

HOST_LABEL=""
LOKI_PUSH_URL=""
INCLUDE_SYSTEM_LOGS=""
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

usage() {
    cat <<'EOF'
Usage:
  sudo bash './promtail-client(5.6).sh'
  bash './promtail-client(5.6).sh' --help

Environment overrides:
  PROMTAIL_VERSION    Default: 2.9.0
  LOKI_PUSH_URL       Default: http://1.2.3.3:3100/loki/api/v1/push
  PROMTAIL_CONFIG     Default: /etc/promtail/promtail-config.yaml
  POSITIONS_FILE      Default: /tmp/positions.yaml
EOF
}

require_root() {
    if [ "${EUID}" -ne 0 ]; then
        die "root 권한이 필요합니다. 예: sudo bash '$0'"
    fi
}

require_interactive() {
    if [ ! -t 0 ]; then
        die "이 스크립트는 실행 중 값을 직접 입력해야 합니다. 대화형 터미널에서 실행하세요."
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

ask() {
    local prompt="$1"
    local default_value="${2:-}"
    local answer

    if [ -n "${default_value}" ]; then
        read -r -p "${prompt} [${default_value}]: " answer
        printf '%s' "${answer:-${default_value}}"
    else
        read -r -p "${prompt}: " answer
        printf '%s' "${answer}"
    fi
}

ask_required() {
    local prompt="$1"
    local default_value="${2:-}"
    local answer

    while true; do
        answer="$(ask "${prompt}" "${default_value}")"
        if [ -n "${answer}" ]; then
            printf '%s' "${answer}"
            return 0
        fi
        warn "빈 값은 사용할 수 없습니다."
    done
}

ask_yes_no() {
    local prompt="$1"
    local default_value="${2:-y}"
    local answer

    while true; do
        answer="$(ask "${prompt} (y/n)" "${default_value}")"
        case "$(printf '%s' "${answer}" | tr '[:upper:]' '[:lower:]')" in
            y|yes)
                return 0
                ;;
            n|no)
                return 1
                ;;
            *)
                warn "y 또는 n으로 입력하세요."
                ;;
        esac
    done
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
            die "job_name은 영문/숫자/점/밑줄/하이픈만 권장합니다. 현재 값: ${value}"
            ;;
    esac
}

validate_loki_push_url() {
    local value="$1"

    case "${value}" in
        http://*/loki/api/v1/push|https://*/loki/api/v1/push)
            ;;
        *)
            die "Loki push URL 형식이 이상합니다: ${value}"
            ;;
    esac
}

loki_ready_url() {
    local push_url="$1"
    printf '%s' "${push_url%/loki/api/v1/push}/ready"
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
        warn "서비스가 아직 로그를 만들지 않았거나 경로가 틀렸을 수 있습니다."
    fi
}

collect_inputs() {
    local default_host
    local service_job_name
    local service_job_label
    local service_log_path

    default_host="$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo server)"

    echo
    echo "=== Promtail 설정 입력 ==="
    LOKI_PUSH_URL="$(ask_required "Loki push URL" "${DEFAULT_LOKI_PUSH_URL}")"
    validate_loki_push_url "${LOKI_PUSH_URL}"

    HOST_LABEL="$(ask_required "Grafana/Loki에서 구분할 host 라벨 예: web1, db1, dns1" "${default_host}")"
    validate_label_value "host label" "${HOST_LABEL}"

    if ask_yes_no "공통 시스템 로그 /var/log/*.log 를 수집할까요?" "y"; then
        INCLUDE_SYSTEM_LOGS="1"
        add_job "system" "varlogs" "/var/log/*.log"
        check_log_path_glob "/var/log/*.log"
    else
        INCLUDE_SYSTEM_LOGS="0"
    fi

    echo
    echo "서비스별 로그를 추가로 입력할 수 있습니다."
    echo "예: job_name=nginx, job_label=nginx-log, path=/var/log/nginx/*.log"
    echo "예: job_name=bind,  job_label=dns-log,   path=/var/log/named/*.log"
    echo

    if [ "${INCLUDE_SYSTEM_LOGS}" = "1" ]; then
        if ! ask_yes_no "nginx/mysql/bind 같은 서비스별 로그 경로를 추가할까요?" "y"; then
            return 0
        fi
    fi

    while true; do
        service_job_name="$(ask_required "서비스 job_name 예: nginx, mysql, bind")"
        validate_job_name "${service_job_name}"

        service_job_label="$(ask_required "Grafana에서 볼 job 라벨" "${service_job_name}-log")"
        validate_label_value "job label" "${service_job_label}"

        service_log_path="$(ask_required "수집할 실제 로그 경로 glob 예: /var/log/nginx/*.log")"
        validate_label_value "log path" "${service_log_path}"
        check_log_path_glob "${service_log_path}"

        add_job "${service_job_name}" "${service_job_label}" "${service_log_path}"

        if ! ask_yes_no "서비스별 로그 경로를 더 추가할까요?" "n"; then
            break
        fi
    done
}

write_config_to() {
    local output_file="$1"
    local i

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
          __path__: "${LOG_PATHS[$i]}"

EOF
    done
}

preview_config() {
    local preview_file="$1"

    write_config_to "${preview_file}"

    echo
    echo "=== 생성될 Promtail 설정 미리보기 ==="
    sed -n '1,220p' "${preview_file}"
    echo "=== 미리보기 끝 ==="
    echo
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

    log "Promtail v${PROMTAIL_VERSION} 다운로드"
    if ! (
        cd "${temp_dir}"
        wget -O promtail-linux-amd64.zip "https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip"
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

    log "Promtail 설정 디렉토리 생성"
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

check_loki_connection() {
    local ready_url

    ready_url="$(loki_ready_url "${LOKI_PUSH_URL}")"

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

post_check() {
    echo
    echo "=== 설치 후 확인 ==="
    check_loki_connection

    echo
    echo "[INFO] 테스트 로그를 남기려면 아래 명령을 실행하세요."
    echo "  logger \"Hello Loki Test from ${HOST_LABEL}\""
    echo
    echo "[INFO] Grafana Explore에서 아래 쿼리로 확인하세요."
    echo "  {host=\"${HOST_LABEL}\"}"
    echo
}

main() {
    local preview_file

    case "${1:-}" in
        -h|--help|help)
            usage
            exit 0
            ;;
        "")
            ;;
        *)
            usage
            die "지원하지 않는 인자입니다: $1"
            ;;
    esac

    require_root
    require_interactive

    preview_file="$(mktemp)"
    trap 'rm -f "${preview_file}"' EXIT

    collect_inputs
    preview_config "${preview_file}"

    if ! ask_yes_no "이 설정으로 Promtail을 설치/반영할까요?" "y"; then
        warn "사용자 취소. 아무 파일도 변경하지 않았습니다."
        exit 0
    fi

    install_promtail_binary
    write_promtail_files "${preview_file}"
    start_service
    post_check
}

main "$@"
