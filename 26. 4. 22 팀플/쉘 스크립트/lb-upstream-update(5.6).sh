#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# =====================================================
# LB WEB upstream 갱신 스크립트 (5.6)
#
# 목적:
# - WEB 장애 후 새 WEB 서버를 투입했을 때 LB1/LB2의 nginx upstream을 빠르게 갱신한다.
# - 기존 LB.sh는 WEB1/WEB2를 고정으로 넣기 때문에, WEB3 같은 새 서버를 넣으려면 설정 수정이 필요하다.
#
# 실행 위치:
# - LB1, LB2 각각에서 실행한다.
# - WEB/NFS/DB 서버에서 실행하지 않는다.
#
# 실행 예시:
#   sudo bash 'lb-upstream-update(5.6).sh' 192.168.2.3 192.168.2.4
#   sudo bash 'lb-upstream-update(5.6).sh' 192.168.2.4 192.168.2.8
#
# 의미:
# - 첫 번째 예시는 기본 WEB1/WEB2 구성이다.
# - 두 번째 예시는 WEB1 장애 후 WEB2와 새 WEB3(예: 192.168.2.8)를 사용한다는 뜻이다.
#
# 주의:
# - 이 스크립트는 새 WEB 서버를 만들지 않는다.
# - 새 WEB 서버 내부 세팅은 web-recover(5.6).sh에서 수행한다.
# - 이 스크립트는 LB nginx 설정만 바꾸고 reload한다.
# =====================================================

VIP="${VIP:-192.168.2.10}"
CONFIG_FILE="${CONFIG_FILE:-/etc/nginx/conf.d/load-balancer.conf}"
BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/zzaphub-lb-upstream}"
RUN_ID="$(date +%Y%m%d-%H%M%S)"

DEFAULT_WEB1="${DEFAULT_WEB1:-192.168.2.3}"
DEFAULT_WEB2="${DEFAULT_WEB2:-192.168.2.4}"
WEB_PORT="${WEB_PORT:-8080}"

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
        die "root 권한이 필요합니다. 예: sudo bash '$0' 192.168.2.3 192.168.2.4"
    fi
}

normalize_web_node() {
    local raw="$1"
    local host
    local port

    case "${raw}" in
        *:*)
            host="${raw%:*}"
            port="${raw##*:}"
            ;;
        *)
            host="${raw}"
            port="${WEB_PORT}"
            ;;
    esac

    if ! [[ "${host}" =~ ^192\.168\.2\.[0-9]{1,3}$ ]]; then
        die "WEB IP는 C Zone 192.168.2.x 형식이어야 합니다: ${raw}"
    fi

    if ! [[ "${port}" =~ ^[0-9]+$ ]] || [ "${port}" -lt 1 ] || [ "${port}" -gt 65535 ]; then
        die "WEB port가 올바르지 않습니다: ${raw}"
    fi

    echo "${host}:${port}"
}

build_web_nodes() {
    local node

    if [ "$#" -eq 0 ]; then
        set -- "${DEFAULT_WEB1}" "${DEFAULT_WEB2}"
    fi

    if [ "$#" -lt 1 ]; then
        die "최소 1개 이상의 WEB IP가 필요합니다."
    fi

    for node in "$@"; do
        normalize_web_node "${node}"
    done
}

backup_config() {
    local backup_path

    [ -e "${CONFIG_FILE}" ] || return 0

    install -d -m 700 -o root -g root "${BACKUP_ROOT}"
    backup_path="${BACKUP_ROOT}/$(basename "${CONFIG_FILE}").${RUN_ID}.bak"
    cp -a "${CONFIG_FILE}" "${backup_path}"
    chmod 600 "${backup_path}" 2>/dev/null || true
    chown root:root "${backup_path}" 2>/dev/null || true

    echo "${backup_path}"
}

write_nginx_config() {
    local nodes=("$@")
    local node

    log "nginx upstream 설정을 작성합니다: ${CONFIG_FILE}"
    backup_path="$(backup_config || true)"
    if [ -n "${backup_path:-}" ]; then
        log "기존 설정 백업: ${backup_path}"
    fi

    {
        echo "upstream backend_nodes {"
        for node in "${nodes[@]}"; do
            echo "    server ${node} max_fails=2 fail_timeout=5s;"
        done
        echo "}"
        echo
        echo "server {"
        echo "    listen 80;"
        echo "    server_name _;"
        echo
        echo "    location / {"
        echo "        proxy_pass http://backend_nodes;"
        echo
        echo "        proxy_connect_timeout 3s;"
        echo "        proxy_send_timeout 30s;"
        echo "        proxy_read_timeout 30s;"
        echo "        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;"
        echo
        echo "        proxy_set_header Host \$host;"
        echo "        proxy_set_header X-Real-IP \$remote_addr;"
        echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
        echo "        proxy_set_header X-Forwarded-Proto \$scheme;"
        echo "    }"
        echo "}"
    } > "${CONFIG_FILE}"
}

reload_nginx() {
    nginx -t
    systemctl reload nginx
}

print_result() {
    local nodes=("$@")

    echo "[SUCCESS] LB upstream 갱신 완료"
    echo "[INFO] VIP: ${VIP}"
    echo "[INFO] 활성 WEB upstream:"
    printf '       %s\n' "${nodes[@]}"
    echo "[INFO] 확인 명령:"
    echo "       nginx -T | grep -A20 'upstream backend_nodes'"
    echo "       curl -I http://${VIP}"
    echo "       systemctl status nginx --no-pager"
    echo "[INFO] 장애 복구 후 원래 WEB을 다시 넣으려면 LB1/LB2 양쪽에서 다시 실행하세요."
}

main() {
    local nodes_text
    local nodes

    require_root

    mapfile -t nodes < <(build_web_nodes "$@")
    nodes_text="$(printf '%s ' "${nodes[@]}")"

    log "적용할 WEB upstream: ${nodes_text}"
    write_nginx_config "${nodes[@]}"
    reload_nginx
    print_result "${nodes[@]}"
}

main "$@"

