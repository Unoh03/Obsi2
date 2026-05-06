#!/usr/bin/env bash

# WEB 보안 패치 스크립트 4.30.1
#
# 목적:
#   기존 WEB 설치 스크립트(web.sh)는 Tomcat이 풀어낸 boot 애플리케이션의
#   application.properties 안에 DB URL/ID/PW를 직접 써 넣는다.
#   이 스크립트는 그 값을 /etc/zzaphub-db.env 로 옮기고,
#   application.properties 에는 ${DB_URL}, ${DB_USER}, ${DB_PASSWORD}
#   변수명만 남긴다.
#
# 중요한 한계:
#   /etc/zzaphub-db.env 는 "숨기는" 파일이 아니라 "권한으로 보호하는" 파일이다.
#   root 권한 또는 Tomcat 실행 권한을 완전히 빼앗기면 공격자가 DB 접속을 악용할 수 있다.
#   그래도 Git, WAR, application.properties 에 비밀번호를 평문으로 박아두는 것보다는
#   훨씬 낫고, 현재 프로젝트에서 바로 실현 가능한 1차 보안 패치다.
#
# 실행 대상:
#   WEB1, WEB2 같은 Tomcat WEB 서버.
#
# 기본 동작:
#   1. Tomcat boot 애플리케이션의 application.properties 를 찾는다.
#   2. spring.datasource.url / username / password 값을 읽는다.
#   3. /etc/zzaphub-db.env 가 없으면 해당 값을 옮겨 적는다.
#   4. application.properties 는 환경변수 placeholder 로 바꾼다.
#   5. tomcat.service 에 systemd drop-in 으로 EnvironmentFile 을 연결한다.
#   6. boot.war 가 있으면 WAR 안의 application.properties 도 같은 내용으로 갱신한다.
#   7. Tomcat을 재시작해 변경을 반영한다.
#
# 재실행 안전성:
#   이미 적용된 항목은 건너뛴다.
#   기존 파일은 /var/backups/zzaphub-web-secure 아래에 백업한다.
#   백업 파일에는 기존 DB 비밀번호가 들어 있을 수 있으므로 root만 읽게 chmod 600 한다.

set -Eeuo pipefail
IFS=$'\n\t'

SERVICE_NAME="${SERVICE_NAME:-tomcat.service}"
TOMCAT_HOME="${TOMCAT_HOME:-/opt/tomcat/tomcat-10}"
APP_CONTEXT="${APP_CONTEXT:-boot}"

PROP_FILE="${PROP_FILE:-${TOMCAT_HOME}/webapps/${APP_CONTEXT}/WEB-INF/classes/application.properties}"
WAR_FILE="${WAR_FILE:-${TOMCAT_HOME}/webapps/${APP_CONTEXT}.war}"

ENV_FILE="${ENV_FILE:-/etc/zzaphub-db.env}"
DROPIN_DIR="${DROPIN_DIR:-/etc/systemd/system/${SERVICE_NAME}.d}"
DROPIN_FILE="${DROPIN_FILE:-${DROPIN_DIR}/10-zzaphub-db-env.conf}"

BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/zzaphub-web-secure}"
RUN_ID="$(date +%Y%m%d-%H%M%S)"

# 기본은 Tomcat 재시작까지 수행한다.
# 점검만 하고 싶으면 RESTART_TOMCAT=0 으로 실행한다.
RESTART_TOMCAT="${RESTART_TOMCAT:-1}"

# 기본은 boot.war 도 같이 갱신한다.
# WAR 갱신을 피하고 싶으면 UPDATE_WAR=0 으로 실행한다.
UPDATE_WAR="${UPDATE_WAR:-1}"

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

make_backup_dir() {
    install -d -m 700 -o root -g root "${BACKUP_ROOT}"
}

safe_backup_name() {
    local file_path="$1"
    basename "${file_path}" | tr -c 'A-Za-z0-9._-' '_'
}

backup_file() {
    local file_path="$1"
    local backup_path

    [ -e "${file_path}" ] || return 0

    backup_path="${BACKUP_ROOT}/$(safe_backup_name "${file_path}").${RUN_ID}.bak"
    cp -a "${file_path}" "${backup_path}"
    chown root:root "${backup_path}" 2>/dev/null || true
    chmod 600 "${backup_path}" 2>/dev/null || true

    echo "${backup_path}"
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
    local value="$1"

    case "${value}" in
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

    if [[ "${value}" == *$'\n'* ]]; then
        die "환경파일 값에 줄바꿈이 들어 있습니다. ${ENV_FILE} 을 수동으로 작성해야 합니다."
    fi

    if [[ "${value}" == *"'"* ]]; then
        die "환경파일 값에 작은따옴표가 들어 있습니다. ${ENV_FILE} 을 수동으로 작성해야 합니다."
    fi

    printf "'%s'" "${value}"
}

env_has_var() {
    local key="$1"

    [ -f "${ENV_FILE}" ] && grep -Eq "^[[:space:]]*${key}=" "${ENV_FILE}"
}

append_env_var_from_property() {
    local env_key="$1"
    local prop_value="$2"

    if env_has_var "${env_key}"; then
        log "${ENV_FILE} 에 ${env_key} 가 이미 있습니다. 값은 출력하지 않습니다."
        return 0
    fi

    if [ -z "${prop_value}" ] || is_placeholder "${prop_value}"; then
        warn "${env_key} 값을 기존 application.properties 에서 가져올 수 없습니다."
        return 1
    fi

    printf '%s=%s\n' "${env_key}" "$(quote_env_value "${prop_value}")" >> "${ENV_FILE}"
    log "${ENV_FILE} 에 ${env_key} 를 저장했습니다. 값은 출력하지 않습니다."
}

create_env_template_if_missing() {
    if [ -f "${ENV_FILE}" ]; then
        return 0
    fi

    install -m 600 -o root -g root /dev/null "${ENV_FILE}"
    cat > "${ENV_FILE}" <<'EOF'
# zzaphub DB connection secrets
# 이 파일은 root만 읽을 수 있어야 합니다.
# 값은 작은따옴표로 감싸서 입력합니다.
#
# 예시:
# DB_URL='jdbc:mariadb://DB서버IP:3306/DB이름'
# DB_USER='DB계정'
# DB_PASSWORD='DB비밀번호'
EOF
    chmod 600 "${ENV_FILE}"
    chown root:root "${ENV_FILE}" 2>/dev/null || true
    log "${ENV_FILE} 템플릿을 만들었습니다."
}

ensure_env_file() {
    local db_url="$1"
    local db_user="$2"
    local db_password="$3"
    local missing=0

    create_env_template_if_missing
    backup_file "${ENV_FILE}" >/dev/null || true

    append_env_var_from_property "DB_URL" "${db_url}" || missing=1
    append_env_var_from_property "DB_USER" "${db_user}" || missing=1
    append_env_var_from_property "DB_PASSWORD" "${db_password}" || missing=1

    chmod 600 "${ENV_FILE}"
    chown root:root "${ENV_FILE}" 2>/dev/null || true

    if [ "${missing}" -ne 0 ]; then
        die "${ENV_FILE} 에 DB_URL, DB_USER, DB_PASSWORD 를 직접 채운 뒤 다시 실행하세요."
    fi
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
    local backup_path

    if properties_already_secure; then
        log "application.properties 는 이미 환경변수 placeholder 를 사용합니다."
        return 0
    fi

    backup_path="$(backup_file "${PROP_FILE}")"
    log "application.properties 백업 생성: ${backup_path}"

    set_property "spring.datasource.url" "${EXPECTED_DB_URL}" "${PROP_FILE}"
    set_property "spring.datasource.username" "${EXPECTED_DB_USER}" "${PROP_FILE}"
    set_property "spring.datasource.password" "${EXPECTED_DB_PASSWORD}" "${PROP_FILE}"

    log "application.properties 의 DB 접속정보를 환경변수 placeholder 로 변경했습니다."
}

write_systemd_dropin() {
    local backup_path=""

    if ! command -v systemctl >/dev/null 2>&1; then
        die "systemctl 을 찾을 수 없습니다. 이 스크립트는 systemd 기반 WEB 서버를 대상으로 합니다."
    fi

    if ! systemctl cat "${SERVICE_NAME}" >/dev/null 2>&1; then
        die "${SERVICE_NAME} 을 찾을 수 없습니다. Tomcat service 이름이 다르면 SERVICE_NAME=... 로 지정하세요."
    fi

    install -d -m 755 -o root -g root "${DROPIN_DIR}"

    if [ -f "${DROPIN_FILE}" ] && grep -Fq "EnvironmentFile=${ENV_FILE}" "${DROPIN_FILE}"; then
        log "systemd drop-in 이 이미 ${ENV_FILE} 을 참조합니다."
        return 0
    fi

    if [ -f "${DROPIN_FILE}" ]; then
        backup_path="$(backup_file "${DROPIN_FILE}")"
        log "기존 systemd drop-in 백업 생성: ${backup_path}"
    fi

    cat > "${DROPIN_FILE}" <<EOF
[Service]
EnvironmentFile=${ENV_FILE}
EOF

    chmod 644 "${DROPIN_FILE}"
    chown root:root "${DROPIN_FILE}" 2>/dev/null || true

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
    local backup_path

    if [ "${UPDATE_WAR}" != "1" ]; then
        warn "UPDATE_WAR=0 이므로 boot.war 갱신을 건너뜁니다."
        return 0
    fi

    if [ ! -f "${WAR_FILE}" ]; then
        warn "${WAR_FILE} 이 없습니다. 배포된 폴더만 수정했습니다."
        return 0
    fi

    if ! command -v jar >/dev/null 2>&1; then
        warn "jar 명령을 찾을 수 없어 ${WAR_FILE} 갱신을 건너뜁니다. JDK 설치 후 다시 실행하세요."
        return 0
    fi

    backup_path="$(backup_file "${WAR_FILE}")"
    log "boot.war 백업 생성: ${backup_path}"

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

restart_tomcat_if_requested() {
    if [ "${RESTART_TOMCAT}" != "1" ]; then
        warn "RESTART_TOMCAT=0 이므로 Tomcat 재시작은 하지 않았습니다."
        warn "수동 반영: sudo systemctl daemon-reload && sudo systemctl restart ${SERVICE_NAME}"
        return 0
    fi

    systemctl daemon-reload
    systemctl restart "${SERVICE_NAME}"
    log "Tomcat 재시작 완료: ${SERVICE_NAME}"
}

verify_result() {
    local failed=0

    [ "$(get_property "spring.datasource.url" "${PROP_FILE}")" = "${EXPECTED_DB_URL}" ] || failed=1
    [ "$(get_property "spring.datasource.username" "${PROP_FILE}")" = "${EXPECTED_DB_USER}" ] || failed=1
    [ "$(get_property "spring.datasource.password" "${PROP_FILE}")" = "${EXPECTED_DB_PASSWORD}" ] || failed=1

    env_has_var "DB_URL" || failed=1
    env_has_var "DB_USER" || failed=1
    env_has_var "DB_PASSWORD" || failed=1

    [ -f "${DROPIN_FILE}" ] && grep -Fq "EnvironmentFile=${ENV_FILE}" "${DROPIN_FILE}" || failed=1

    if [ "${failed}" -ne 0 ]; then
        die "검증 실패. 백업 위치를 확인하세요: ${BACKUP_ROOT}"
    fi

    log "검증 완료: properties placeholder, env 파일, systemd drop-in 이 준비되었습니다."
    log "secret 값은 출력하지 않았습니다."
    log "rollback 참고: ${BACKUP_ROOT} 의 백업 파일을 원래 위치로 복사한 뒤 systemctl daemon-reload/restart 를 수행하세요."
}

main() {
    require_root
    make_backup_dir

    log "WEB 보안 패치 시작"
    log "대상 properties: ${PROP_FILE}"
    log "대상 env 파일: ${ENV_FILE}"

    [ -f "${PROP_FILE}" ] || die "${PROP_FILE} 을 찾을 수 없습니다. Tomcat이 boot.war 를 아직 풀지 않았거나 APP_CONTEXT/TOMCAT_HOME 이 다릅니다."

    local db_url
    local db_user
    local db_password

    db_url="$(get_property "spring.datasource.url" "${PROP_FILE}")"
    db_user="$(get_property "spring.datasource.username" "${PROP_FILE}")"
    db_password="$(get_property "spring.datasource.password" "${PROP_FILE}")"

    ensure_env_file "${db_url}" "${db_user}" "${db_password}"
    secure_application_properties
    write_systemd_dropin
    update_war_if_present
    restart_tomcat_if_requested
    verify_result

    log "WEB DB 접속정보 하드코딩 제거 작업이 끝났습니다."
}

main "$@"
