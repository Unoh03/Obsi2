#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# =====================================================
# WEB 통합 설치/재구축 스크립트 (5.6)
#
# 목적:
# - WEB1/WEB2 최초 구축 또는 신규 WEB3 투입 시, WEB 서버를 빠르게 서비스 가능한 상태로 만든다.
# - Tomcat 설치, boot.war 배포, DB secret 분리, NFS upload mount, 기본 검증을 한 번에 수행한다.
#
# 실행 위치:
# - 새로 만든 WEB 서버 또는 재구축할 WEB 서버 안에서 실행한다.
# - LB 서버, NFS 서버, DB 서버에서 실행하지 않는다.
#
# 필요한 파일:
# - 이 스크립트와 같은 디렉터리에 boot.war 가 있어야 한다.
# - 같은 디렉터리에 web-nfs(5.6).sh 가 있으면 NFS mount를 맡긴다.
# - 같은 디렉터리에 promtail-client-auto(5.6).sh 가 있으면 WEB 로그 수집 설정을 맡긴다.
#
# 실행 예시:
#   sudo DB_URL='jdbc:mariadb://1.2.3.1:3306/care' DB_USER='web' DB_PASSWORD='값은직접입력' bash 'web(5.6).sh'
#
# 이미 /etc/zzaphub-db.env 가 준비되어 있다면:
#   sudo bash 'web(5.6).sh'
#
# 중요한 한계:
# - 이 스크립트는 AWS Auto Scaling처럼 VM을 새로 생성하지 않는다.
# - 새 서버 생성, IP 할당, LB upstream 변경은 사람이 하거나 별도 자동화가 해야 한다.
# - 이 스크립트의 목표는 "WEB 서버 안의 표준 세팅을 재현 가능하게 만드는 것"이다.
# =====================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

TOMCAT_VER="${TOMCAT_VER:-10.1.54}"
TOMCAT_BASE_URL="${TOMCAT_BASE_URL:-https://downloads.apache.org/tomcat/tomcat-10}"
TOMCAT_DOWNLOAD_URL="${TOMCAT_DOWNLOAD_URL:-${TOMCAT_BASE_URL}/v${TOMCAT_VER}/bin/apache-tomcat-${TOMCAT_VER}.tar.gz}"
TOMCAT_USER="${TOMCAT_USER:-tomcat}"
TOMCAT_GROUP="${TOMCAT_GROUP:-tomcat}"
TOMCAT_BASE="${TOMCAT_BASE:-/opt/tomcat}"
TOMCAT_HOME="${TOMCAT_HOME:-${TOMCAT_BASE}/tomcat-10}"
SERVICE_NAME="${SERVICE_NAME:-tomcat.service}"
APP_CONTEXT="${APP_CONTEXT:-boot}"

WAR_SOURCE="${WAR_SOURCE:-${SCRIPT_DIR}/boot.war}"
NFS_SCRIPT="${NFS_SCRIPT:-${SCRIPT_DIR}/web-nfs(5.6).sh}"
PROMTAIL_SCRIPT="${PROMTAIL_SCRIPT:-${SCRIPT_DIR}/promtail-client-auto(5.6).sh}"

ENV_FILE="${ENV_FILE:-/etc/zzaphub-db.env}"
PROP_FILE="${PROP_FILE:-${TOMCAT_HOME}/webapps/${APP_CONTEXT}/WEB-INF/classes/application.properties}"
WAR_FILE="${WAR_FILE:-${TOMCAT_HOME}/webapps/${APP_CONTEXT}.war}"
DROPIN_DIR="${DROPIN_DIR:-/etc/systemd/system/${SERVICE_NAME}.d}"
DROPIN_FILE="${DROPIN_FILE:-${DROPIN_DIR}/10-zzaphub-db-env.conf}"
NFS_VIP="${NFS_VIP:-192.168.2.50}"
MOUNT_DIR="${MOUNT_DIR:-${TOMCAT_HOME}/webapps/upload}"

RUN_SECURE="${RUN_SECURE:-1}"
UPDATE_WAR="${UPDATE_WAR:-1}"
RUN_NFS="${RUN_NFS:-1}"
NFS_REQUIRED="${NFS_REQUIRED:-0}"
RUN_PROMTAIL="${RUN_PROMTAIL:-1}"
PROMTAIL_REQUIRED="${PROMTAIL_REQUIRED:-0}"
PROMTAIL_PRESET="${PROMTAIL_PRESET:-web}"
PROMTAIL_HOST_LABEL="${PROMTAIL_HOST_LABEL:-}"
ALLOW_UFW="${ALLOW_UFW:-1}"
FORCE_REDEPLOY="${FORCE_REDEPLOY:-0}"

BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/zzaphub-web-integrated}"
RUN_ID="$(date +%Y%m%d-%H%M%S)"

EXPECTED_DB_URL='${DB_URL}'
EXPECTED_DB_USER='${DB_USER}'
EXPECTED_DB_PASSWORD='${DB_PASSWORD}'

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
        die "root 권한이 필요합니다. 예: sudo bash '$0'"
    fi
}

backup_path_for() {
    local path="$1"
    local base

    base="$(basename "${path}" | tr -c 'A-Za-z0-9._-' '_')"
    echo "${BACKUP_ROOT}/${base}.${RUN_ID}.bak"
}

backup_file_or_dir() {
    local path="$1"
    local backup_path

    [ -e "${path}" ] || return 0

    install -d -m 700 -o root -g root "${BACKUP_ROOT}"
    backup_path="$(backup_path_for "${path}")"

    if [ -d "${path}" ] && [ ! -L "${path}" ]; then
        cp -a "${path}" "${backup_path}"
    else
        cp -a "${path}" "${backup_path}"
    fi

    chown -R root:root "${backup_path}" 2>/dev/null || true
    chmod -R go-rwx "${backup_path}" 2>/dev/null || true
    echo "${backup_path}"
}

contains_bad_env_chars() {
    local value="$1"

    [[ "${value}" == *$'\n'* ]] || [[ "${value}" == *"'"* ]]
}

get_property() {
    local key="$1"
    local file_path="$2"

    awk -F= -v key="${key}" '
        {
            lhs=$1
            gsub(/^[ \t]+|[ \t]+$/, "", lhs)
            if (lhs == key) {
                sub(/^[^=]*=/, "")
                sub(/\r$/, "")
                print
                exit
            }
        }
    ' "${file_path}"
}

is_placeholder() {
    case "$1" in
        '${DB_URL}'|'${DB_USER}'|'${DB_PASSWORD}')
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

quote_env_value() {
    local value="$1"

    if contains_bad_env_chars "${value}"; then
        die "환경파일 값에 작은따옴표 또는 줄바꿈이 있습니다. ${ENV_FILE} 을 직접 작성하세요."
    fi

    printf "'%s'" "${value}"
}

env_has_var() {
    local key="$1"

    [ -f "${ENV_FILE}" ] && grep -Eq "^[[:space:]]*${key}=" "${ENV_FILE}"
}

env_file_has_all_db_vars() {
    [ -f "${ENV_FILE}" ] &&
    grep -Eq '^[[:space:]]*DB_URL=' "${ENV_FILE}" &&
    grep -Eq '^[[:space:]]*DB_USER=' "${ENV_FILE}" &&
    grep -Eq '^[[:space:]]*DB_PASSWORD=' "${ENV_FILE}"
}

append_env_var_if_missing() {
    local env_key="$1"
    local env_value="$2"

    if env_has_var "${env_key}"; then
        log "${ENV_FILE} 에 ${env_key} 가 이미 있습니다. 값은 출력하지 않습니다."
        return 0
    fi

    if [ -z "${env_value}" ] || is_placeholder "${env_value}"; then
        return 1
    fi

    printf '%s=%s\n' "${env_key}" "$(quote_env_value "${env_value}")" >> "${ENV_FILE}"
    log "${ENV_FILE} 에 ${env_key} 를 저장했습니다. 값은 출력하지 않습니다."
}

ensure_secret_env_file() {
    local db_url="${DB_URL:-}"
    local db_user="${DB_USER:-}"
    local db_password="${DB_PASSWORD:-}"
    local missing=0

    if env_file_has_all_db_vars; then
        log "${ENV_FILE} 가 이미 준비되어 있습니다. secret 값은 출력하지 않습니다."
        chmod 600 "${ENV_FILE}" || true
        chown root:root "${ENV_FILE}" 2>/dev/null || true
        return 0
    fi

    if [ -f "${PROP_FILE}" ]; then
        db_url="${db_url:-$(get_property "spring.datasource.url" "${PROP_FILE}")}"
        db_user="${db_user:-$(get_property "spring.datasource.username" "${PROP_FILE}")}"
        db_password="${db_password:-$(get_property "spring.datasource.password" "${PROP_FILE}")}"
    fi

    install -d -m 755 -o root -g root "$(dirname "${ENV_FILE}")"

    if [ -e "${ENV_FILE}" ]; then
        log "기존 env 파일 백업: $(backup_file_or_dir "${ENV_FILE}")"
    fi

    if [ ! -f "${ENV_FILE}" ]; then
        cat > "${ENV_FILE}" <<EOF
# zzaphub DB connection secrets
# 이 파일은 Git에 올리지 않는다.
EOF
    fi

    append_env_var_if_missing "DB_URL" "${db_url}" || missing=1
    append_env_var_if_missing "DB_USER" "${db_user}" || missing=1
    append_env_var_if_missing "DB_PASSWORD" "${db_password}" || missing=1

    chmod 600 "${ENV_FILE}"
    chown root:root "${ENV_FILE}" 2>/dev/null || true

    if [ "${missing}" -ne 0 ]; then
        die "${ENV_FILE} 에 DB_URL, DB_USER, DB_PASSWORD 를 채울 수 없습니다. 환경변수로 넘기거나 파일을 직접 작성하세요."
    fi

    log "${ENV_FILE} 을 생성했습니다. secret 값은 출력하지 않습니다."
}

set_property() {
    local key="$1"
    local value="$2"
    local file_path="$3"
    local tmp_file

    tmp_file="$(mktemp)"

    awk -F= -v key="${key}" -v value="${value}" '
        BEGIN { done = 0 }
        {
            lhs=$1
            gsub(/^[ \t]+|[ \t]+$/, "", lhs)

            if (lhs == key) {
                if (done == 0) {
                    print key "=" value
                    done = 1
                }
                next
            }

            print
        }
        END {
            if (done == 0) {
                print key "=" value
            }
        }
    ' "${file_path}" > "${tmp_file}"

    cat "${tmp_file}" > "${file_path}"
    rm -f "${tmp_file}"
}

properties_already_secure() {
    [ "$(get_property "spring.datasource.url" "${PROP_FILE}")" = "${EXPECTED_DB_URL}" ] &&
    [ "$(get_property "spring.datasource.username" "${PROP_FILE}")" = "${EXPECTED_DB_USER}" ] &&
    [ "$(get_property "spring.datasource.password" "${PROP_FILE}")" = "${EXPECTED_DB_PASSWORD}" ]
}

secure_application_properties() {
    if properties_already_secure; then
        log "application.properties 는 이미 환경변수 placeholder 를 사용합니다."
        return 0
    fi

    log "application.properties 백업: $(backup_file_or_dir "${PROP_FILE}")"

    set_property "spring.datasource.url" "${EXPECTED_DB_URL}" "${PROP_FILE}"
    set_property "spring.datasource.username" "${EXPECTED_DB_USER}" "${PROP_FILE}"
    set_property "spring.datasource.password" "${EXPECTED_DB_PASSWORD}" "${PROP_FILE}"

    log "application.properties 의 DB 접속정보를 환경변수 placeholder 로 변경했습니다."
}

write_systemd_dropin() {
    install -d -m 755 -o root -g root "${DROPIN_DIR}"

    if [ -f "${DROPIN_FILE}" ] && grep -Fq "EnvironmentFile=${ENV_FILE}" "${DROPIN_FILE}"; then
        log "systemd drop-in 이 이미 ${ENV_FILE} 을 참조합니다."
        return 0
    fi

    if [ -f "${DROPIN_FILE}" ]; then
        log "기존 systemd drop-in 백업: $(backup_file_or_dir "${DROPIN_FILE}")"
    fi

    cat > "${DROPIN_FILE}" <<EOF
[Service]
EnvironmentFile=${ENV_FILE}
EOF
    chmod 644 "${DROPIN_FILE}"

    log "Tomcat systemd drop-in 작성: ${DROPIN_FILE}"
}

cleanup_tmp_dir() {
    local tmp_dir="$1"

    case "${tmp_dir}" in
        /tmp/*|/var/tmp/*)
            rm -rf -- "${tmp_dir}"
            ;;
        *)
            warn "임시 디렉터리 경로가 예상 밖이라 삭제하지 않습니다: ${tmp_dir}"
            ;;
    esac
}

update_war_if_present() {
    local tmp_dir

    if [ "${UPDATE_WAR}" != "1" ]; then
        warn "UPDATE_WAR=0 이므로 boot.war 내부 properties 갱신을 건너뜁니다."
        return 0
    fi

    if [ ! -f "${WAR_FILE}" ]; then
        warn "${WAR_FILE} 이 없습니다. 배포된 폴더만 수정했습니다."
        return 0
    fi

    if ! command -v jar >/dev/null 2>&1; then
        warn "jar 명령을 찾을 수 없어 ${WAR_FILE} 갱신을 건너뜁니다."
        return 0
    fi

    log "boot.war 백업: $(backup_file_or_dir "${WAR_FILE}")"

    tmp_dir="$(mktemp -d)"
    mkdir -p "${tmp_dir}/WEB-INF/classes"
    cp "${PROP_FILE}" "${tmp_dir}/WEB-INF/classes/application.properties"

    (
        cd "${tmp_dir}"
        jar uf "${WAR_FILE}" WEB-INF/classes/application.properties
    )

    cleanup_tmp_dir "${tmp_dir}"
    log "boot.war 내부 application.properties 도 placeholder 버전으로 갱신했습니다."
}

restart_tomcat_after_secure_patch() {
    systemctl daemon-reload
    systemctl restart "${SERVICE_NAME}"
    log "Tomcat 재시작 완료: ${SERVICE_NAME}"
}

verify_secure_patch() {
    local failed=0

    [ "$(get_property "spring.datasource.url" "${PROP_FILE}")" = "${EXPECTED_DB_URL}" ] || failed=1
    [ "$(get_property "spring.datasource.username" "${PROP_FILE}")" = "${EXPECTED_DB_USER}" ] || failed=1
    [ "$(get_property "spring.datasource.password" "${PROP_FILE}")" = "${EXPECTED_DB_PASSWORD}" ] || failed=1
    env_file_has_all_db_vars || failed=1
    [ -f "${DROPIN_FILE}" ] && grep -Fq "EnvironmentFile=${ENV_FILE}" "${DROPIN_FILE}" || failed=1

    if [ "${failed}" -ne 0 ]; then
        die "DB secret 내장 통합 검증 실패"
    fi

    log "DB secret 분리 검증 완료"
}

install_packages() {
    log "필수 패키지를 설치합니다."
    apt update
    apt install -y openjdk-17-jdk curl wget tar
}

ensure_tomcat_user() {
    if id "${TOMCAT_USER}" >/dev/null 2>&1; then
        log "${TOMCAT_USER} 계정이 이미 있습니다."
        return 0
    fi

    log "${TOMCAT_USER} 전용 계정을 생성합니다."
    useradd -r -m -U -d "${TOMCAT_BASE}" -s /bin/false "${TOMCAT_USER}"
}

install_tomcat_if_needed() {
    local tarball
    local tmp_dir
    local extracted_dir

    if [ -x "${TOMCAT_HOME}/bin/startup.sh" ]; then
        log "Tomcat이 이미 설치되어 있습니다: ${TOMCAT_HOME}"
        return 0
    fi

    if [ -e "${TOMCAT_HOME}" ]; then
        die "${TOMCAT_HOME} 이 이미 있지만 Tomcat 설치로 보이지 않습니다. 수동 확인 후 정리하세요."
    fi

    log "Tomcat ${TOMCAT_VER} 를 설치합니다."
    install -d -m 755 -o "${TOMCAT_USER}" -g "${TOMCAT_GROUP}" "${TOMCAT_BASE}"

    tmp_dir="$(mktemp -d)"
    tarball="${tmp_dir}/apache-tomcat-${TOMCAT_VER}.tar.gz"
    extracted_dir="${TOMCAT_BASE}/apache-tomcat-${TOMCAT_VER}"

    log "Tomcat download URL: ${TOMCAT_DOWNLOAD_URL}"
    wget -O "${tarball}" "${TOMCAT_DOWNLOAD_URL}"
    tar -xf "${tarball}" -C "${TOMCAT_BASE}"
    mv "${extracted_dir}" "${TOMCAT_HOME}"
    chown -R "${TOMCAT_USER}:${TOMCAT_GROUP}" "${TOMCAT_HOME}"
    rm -rf -- "${tmp_dir}"
}

write_tomcat_service() {
    local service_file="/etc/systemd/system/${SERVICE_NAME}"

    if [ -f "${service_file}" ]; then
        log "기존 ${SERVICE_NAME} 백업: $(backup_file_or_dir "${service_file}")"
    fi

    log "${SERVICE_NAME} systemd 서비스를 작성합니다."
    cat > "${service_file}" <<EOF
[Unit]
Description=Tomcat 10 servlet container
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=${TOMCAT_USER}
Group=${TOMCAT_GROUP}
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/"
ExecStart=${TOMCAT_HOME}/bin/startup.sh
ExecStop=${TOMCAT_HOME}/bin/shutdown.sh
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF

    chmod 644 "${service_file}"
    systemctl daemon-reload
    systemctl enable "${SERVICE_NAME}"
}

deploy_war() {
    local target_war="${TOMCAT_HOME}/webapps/${APP_CONTEXT}.war"
    local app_dir="${TOMCAT_HOME}/webapps/${APP_CONTEXT}"

    [ -f "${WAR_SOURCE}" ] || die "WAR 파일을 찾을 수 없습니다: ${WAR_SOURCE}"

    systemctl stop "${SERVICE_NAME}" 2>/dev/null || true

    if [ -f "${target_war}" ]; then
        log "기존 WAR 백업: $(backup_file_or_dir "${target_war}")"
    fi

    if [ -d "${app_dir}" ] && [ "${FORCE_REDEPLOY}" = "1" ]; then
        log "기존 배포 디렉터리 백업: $(backup_file_or_dir "${app_dir}")"
        rm -rf -- "${app_dir}"
    elif [ -d "${app_dir}" ]; then
        warn "${app_dir} 이 이미 있습니다. 완전 재배포가 필요하면 FORCE_REDEPLOY=1 로 실행하세요."
    fi

    log "boot.war 를 배포합니다: ${target_war}"
    cp "${WAR_SOURCE}" "${target_war}"
    chown "${TOMCAT_USER}:${TOMCAT_GROUP}" "${target_war}"

    install -d -m 755 -o "${TOMCAT_USER}" -g "${TOMCAT_GROUP}" "${TOMCAT_HOME}/webapps"
    systemctl start "${SERVICE_NAME}"
}

wait_for_app_properties() {
    local prop_file="${TOMCAT_HOME}/webapps/${APP_CONTEXT}/WEB-INF/classes/application.properties"
    local waited=0
    local max_wait="${APP_EXPAND_WAIT:-60}"

    log "Tomcat이 WAR를 풀 때까지 기다립니다: ${prop_file}"

    while ! test -f "${prop_file}"; do
        sleep 1
        waited=$((waited + 1))
        echo "[INFO] application.properties 대기 중... (${waited}/${max_wait}s)"

        if [ "${waited}" -ge "${max_wait}" ]; then
            die "${prop_file} 을 찾지 못했습니다. Tomcat 로그를 확인하세요: journalctl -u ${SERVICE_NAME} -n 100 --no-pager"
        fi
    done
}

run_secure_patch() {
    if [ "${RUN_SECURE}" != "1" ]; then
        warn "RUN_SECURE=0 이므로 DB secret 분리를 건너뜁니다."
        return 0
    fi

    [ -f "${PROP_FILE}" ] || die "${PROP_FILE} 을 찾을 수 없습니다. Tomcat이 boot.war 를 아직 풀지 않았거나 APP_CONTEXT/TOMCAT_HOME 이 다릅니다."
    ensure_secret_env_file
    secure_application_properties
    write_systemd_dropin
    update_war_if_present
    restart_tomcat_after_secure_patch
    verify_secure_patch
}

run_nfs_mount() {
    if [ "${RUN_NFS}" != "1" ]; then
        warn "RUN_NFS=0 이므로 NFS upload mount를 건너뜁니다."
        return 0
    fi

    if [ ! -f "${NFS_SCRIPT}" ]; then
        if [ "${NFS_REQUIRED}" = "1" ]; then
            die "web-nfs 스크립트를 찾을 수 없습니다: ${NFS_SCRIPT}"
        fi

        warn "web-nfs 스크립트를 찾을 수 없어 NFS mount를 건너뜁니다: ${NFS_SCRIPT}"
        warn "NFS mount까지 필수로 보려면 web-nfs(5.6).sh를 같은 위치에 두거나 NFS_REQUIRED=1로 실행하세요."
        return 0
    fi

    log "NFS VIP upload mount 스크립트를 실행합니다."
    NFS_VERSION="${NFS_VERSION:-4}" bash "${NFS_SCRIPT}" "${NFS_VIP}"

    if ! findmnt --target "${MOUNT_DIR}" >/dev/null 2>&1; then
        die "${MOUNT_DIR} 가 mount되지 않았습니다."
    fi
}

run_promtail_client() {
    if [ "${RUN_PROMTAIL}" != "1" ]; then
        warn "RUN_PROMTAIL=0 이므로 Promtail 로그 수집 설정을 건너뜁니다."
        return 0
    fi

    if [ ! -f "${PROMTAIL_SCRIPT}" ]; then
        if [ "${PROMTAIL_REQUIRED}" = "1" ]; then
            die "Promtail 자동 설정 스크립트를 찾을 수 없습니다: ${PROMTAIL_SCRIPT}"
        fi

        warn "Promtail 자동 설정 스크립트를 찾을 수 없어 건너뜁니다: ${PROMTAIL_SCRIPT}"
        return 0
    fi

    log "Promtail WEB preset 설정을 실행합니다."

    if PROMTAIL_PRESET="${PROMTAIL_PRESET}" \
        HOST_LABEL="${PROMTAIL_HOST_LABEL}" \
        ROLE_LABEL="web" \
        TOMCAT_HOME="${TOMCAT_HOME}" \
        LOKI_PUSH_URL="${LOKI_PUSH_URL:-http://1.2.3.3:3100/loki/api/v1/push}" \
        bash "${PROMTAIL_SCRIPT}"; then
        log "Promtail WEB preset 설정이 끝났습니다."
        return 0
    fi

    if [ "${PROMTAIL_REQUIRED}" = "1" ]; then
        die "Promtail WEB preset 설정 실패"
    fi

    warn "Promtail WEB preset 설정 실패. WEB 서비스 자체는 계속 검증합니다."
}

open_firewall_if_requested() {
    if [ "${ALLOW_UFW}" != "1" ]; then
        warn "ALLOW_UFW=0 이므로 UFW 8080/tcp 허용을 건너뜁니다."
        return 0
    fi

    if command -v ufw >/dev/null 2>&1; then
        ufw allow 8080/tcp || true
    else
        warn "ufw 명령을 찾지 못했습니다. 방화벽은 수동 확인하세요."
    fi
}

verify_web() {
    local local_ip

    log "WEB 통합 설치/재구축 결과를 검증합니다."
    systemctl is-active --quiet "${SERVICE_NAME}" || die "${SERVICE_NAME} 이 active 상태가 아닙니다."

    if command -v ss >/dev/null 2>&1; then
        ss -ltn | grep -q ':8080 ' || warn "8080 listen 상태를 ss에서 확인하지 못했습니다."
    fi

    if command -v curl >/dev/null 2>&1; then
        curl -fsS --max-time 5 "http://127.0.0.1:8080/" >/dev/null || warn "http://127.0.0.1:8080/ 확인 실패. 애플리케이션 context가 /${APP_CONTEXT} 일 수 있습니다."
        curl -fsS --max-time 5 "http://127.0.0.1:8080/${APP_CONTEXT}/" >/dev/null || warn "http://127.0.0.1:8080/${APP_CONTEXT}/ 확인 실패. 애플리케이션 상태를 수동 확인하세요."
    fi

    local_ip="$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.2\./ {print $4; exit}' | cut -d/ -f1 || true)"

    echo "[SUCCESS] WEB 통합 설치/재구축 스크립트가 끝났습니다."
    echo "[INFO] 이 서버의 C Zone IP: ${local_ip:-unknown}"
    echo "[INFO] 확인 명령:"
    echo "       systemctl status ${SERVICE_NAME} --no-pager"
    echo "       curl http://127.0.0.1:8080/"
    echo "       curl http://127.0.0.1:8080/${APP_CONTEXT}/"
    echo "       findmnt --target ${MOUNT_DIR}"
    echo "       ls -l ${ENV_FILE}"
    echo "[INFO] LB 반영 주의:"
    echo "       새 WEB IP가 기존 WEB1/WEB2 IP가 아니면 LB1/LB2의 /etc/nginx/conf.d/load-balancer.conf upstream을 수정해야 합니다."
    echo "       수정 후 LB1/LB2에서 실행: sudo nginx -t && sudo systemctl reload nginx"
}

main() {
    require_root

    log "WEB 통합 설치/재구축 시작"
    log "SCRIPT_DIR=${SCRIPT_DIR}"
    log "WAR_SOURCE=${WAR_SOURCE}"
    log "TOMCAT_DOWNLOAD_URL=${TOMCAT_DOWNLOAD_URL}"
    log "TOMCAT_HOME=${TOMCAT_HOME}"
    log "ENV_FILE=${ENV_FILE}"
    log "NFS_VIP=${NFS_VIP}"
    log "RUN_PROMTAIL=${RUN_PROMTAIL}, PROMTAIL_PRESET=${PROMTAIL_PRESET}"

    install_packages
    ensure_tomcat_user
    install_tomcat_if_needed
    write_tomcat_service
    deploy_war
    wait_for_app_properties
    run_secure_patch
    run_nfs_mount
    run_promtail_client
    open_firewall_if_requested
    verify_web
}

main "$@"
