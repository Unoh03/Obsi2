#!/bin/bash
set -euo pipefail

# =====================================================
# Charlie C Zone NFS HA 서버 설정 스크립트 (5.6)
#
# 이 스크립트의 목적:
# - NFS1/NFS2 두 서버에 같은 NFS 서버 구성을 만든다.
# - keepalived로 NFS VIP(192.168.2.50)를 한쪽 서버가 가지게 한다.
# - WEB 서버는 NFS1/NFS2 실제 IP가 아니라 VIP만 mount하게 만든다.
# - VIP를 가진 NFS 서버가 원본 역할을 하고, rsync로 반대편 NFS에 파일을 복제한다.
#
# 처음 읽는 사람을 위한 큰 흐름:
# 1. 현재 서버가 NFS1인지 NFS2인지 IP로 판별한다.
# 2. NFS 서버 패키지, keepalived, rsync, SSH, cron을 설치한다.
# 3. /share_directory를 NFS export로 공개한다.
# 4. keepalived가 감시할 NFS health check 스크립트를 만든다.
# 5. VIP를 가진 서버만 peer 서버로 rsync하는 동기화 스크립트를 만든다.
# 6. cron이 1분마다 동기화 스크립트를 실행하게 등록한다.
# 7. keepalived가 VIP를 붙이고, 현재 VIP 소유자만 원본 NFS처럼 동작한다.
#
# 핵심 개념:
# - WEB 서버는 항상 192.168.2.50:/share_directory만 mount한다.
# - 실제 VIP 소유자는 NFS1일 수도 있고 NFS2일 수도 있다.
# - VIP 소유자만 rsync 원본이 된다.
# - BACKUP 노드에서도 cron은 실행되지만, 스크립트 첫 부분에서 VIP가 없으면 바로 종료한다.
#
# 고정 구성:
# - NFS1: 192.168.2.5
# - NFS2: 192.168.2.6
# - NFS VIP: 192.168.2.50
# - 공유 디렉터리: /share_directory
# - NFS 허용 대역: 192.168.2.0/24
#
# 4.28.2에서 유지한 것:
# - 192.168.2.0/24 대역에 NFS export 제공
# - keepalived를 이용한 VIP 장애조치
# - NFS 서비스 상태 확인 health check
# - NFS/VRRP 관련 UFW 규칙
#
# 4.29.1에서 추가/변경한 것:
# - rsync 기반 자동 파일 복제를 추가한다.
# - 현재 VIP를 가진 노드만 peer 노드로 동기화한다.
# - cron으로 1분마다 동기화 스크립트를 실행한다.
# - 자동 삭제 동기화는 기본으로 끈다.
#   이유: failover 직전 반대편에 복제되지 않은 최신 파일을 복구 과정에서 지울 수 있기 때문이다.
# - 삭제 동기화가 꼭 필요하면 설치 후 충분히 검증하고 SYNC_DELETE_OPT="--delete-delay"를 직접 설정한다.
#
# 중요한 한계:
# - 이 구성은 편의 우선 실습 모드다.
# - 로컬 sync 계정(nfs1 또는 nfs2)이 없으면 자동 생성한다.
# - 실습 편의를 위해 NFS export 범위를 넓게 두고 /share_directory 권한도 777로 둔다.
# - rsync 파일 복제이며, DRBD 같은 블록 단위 복제가 아니다.
# - split-brain을 완전히 해결하지 않는다.
# - 자동 rsync는 SSH key 로그인 설정이 끝나야 동작한다.
# - keepalived는 nopreempt를 사용하므로 장애 복구 후 원래 노드가 VIP를 자동으로 다시 가져가지 않는다.
#
# 일반 실행:
#   bash 'nfs-ha(5.6).sh'
#
# 역할을 수동 지정해야 할 때:
#   IFACE=ens37 bash 'nfs-ha(5.6).sh' MASTER
#   IFACE=ens37 bash 'nfs-ha(5.6).sh' BACKUP
# =====================================================

# 두 NFS 서버의 실제 IP다. 이 IP로 현재 서버가 NFS1인지 NFS2인지 판별한다.
NFS1_IP="192.168.2.5"
NFS2_IP="192.168.2.6"

# rsync/SSH 동기화에 사용할 로컬 계정명이다.
# NFS1에서는 nfs1 계정, NFS2에서는 nfs2 계정을 사용한다.
NFS1_USER="${NFS1_USER:-nfs1}"
NFS2_USER="${NFS2_USER:-nfs2}"

# WEB 서버가 mount할 고정 NFS 서비스 IP다.
# 장애조치가 일어나면 이 VIP가 NFS1 또는 NFS2 중 살아 있는 쪽으로 이동한다.
VIP="192.168.2.50"

# keepalived VRRP 그룹 번호와 인증 문자열이다.
# NFS1/NFS2가 같은 VRID/AUTH_PASS를 써야 같은 VIP 그룹으로 동작한다.
VRID="50"
AUTH_PASS="nfs-ha"

# 실제 NFS로 export할 디렉터리와 허용 클라이언트 대역이다.
SHARE_DIR="/share_directory"
EXPORT_NET="192.168.2.0/24"
EXPORT_LINE="${SHARE_DIR} ${EXPORT_NET}(rw,sync,no_subtree_check)"

# 서버에 생성할 자동 동기화 스크립트, 로그, cron 파일 위치다.
SYNC_SCRIPT="/usr/local/bin/nfs_ha_sync.sh"
SYNC_LOG="/var/log/nfs-ha-sync.log"
CRON_FILE="/etc/cron.d/nfs-ha-sync"
LOCK_FILE="/tmp/nfs-ha-sync.lock"

# 기본값은 삭제 동기화 OFF다.
# 값이 비어 있으면 rsync가 삭제를 전파하지 않는다.
# SYNC_DELETE_OPT="--delete-delay"를 주면 삭제도 peer로 전파한다.
# 삭제 동기화를 기본으로 끄는 이유:
# - 장애 직전 NFS1에만 최신 파일이 생겼는데 NFS2로 아직 복제되지 않았을 수 있다.
# - 그 상태에서 NFS2가 VIP를 가져가면 NFS2는 자기 상태를 최신 원본으로 착각할 수 있다.
# - 이후 삭제 동기화가 켜진 상태로 NFS1에 rsync하면 NFS1에만 있던 최신 파일이 지워질 수 있다.
# - 그래서 삭제는 자동화보다 사람이 양쪽 파일 상태를 확인한 뒤 수동으로 켜는 쪽이 안전하다.
DELETE_OPT="${SYNC_DELETE_OPT:-}"

# 공유 디렉터리 파일시스템 사용률이 이 값 이상이면 경고를 출력한다.
DISK_WARN_PERCENT="${DISK_WARN_PERCENT:-85}"

echo "[INFO] NFS HA server setup started."
echo "[INFO] VIP=${VIP}, NFS1=${NFS1_IP}, NFS2=${NFS2_IP}, Share=${SHARE_DIR}"

# =====================================================
# 1. 인터페이스, 로컬 IP, 역할, 동기화 상대를 판별한다.
# =====================================================
echo "[STEP 1/9] Checking interface, local role, and sync peer."

# ROLE과 PRIORITY는 인자로 받을 수 있다.
# 인자가 없으면 현재 서버 IP를 보고 자동으로 정한다.
ROLE="${1:-}"
PRIORITY="${2:-}"

# IFACE는 192.168.2.x 주소가 붙은 네트워크 인터페이스다.
# 사용자가 IFACE=ens37처럼 직접 지정하지 않으면 자동 탐색한다.
IFACE="${IFACE:-}"

if [ -z "$IFACE" ]; then
    IFACE="$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.2\./ {print $2; exit}')"
fi

if [ -z "$IFACE" ]; then
    echo "[ERROR] Could not find an interface with a 192.168.2.0/24 address."
    echo "        Example: IFACE=ens37 bash 'nfs-ha(5.6).sh' MASTER"
    exit 1
fi

# 현재 인터페이스에 붙은 IP가 NFS1/NFS2 중 어느 것인지 확인한다.
# 여기서 값이 안 나오면 이 서버는 이 스크립트가 예상한 NFS 서버가 아니다.
LOCAL_IP="$(ip -o -4 addr show dev "$IFACE" | awk '{print $4}' | cut -d/ -f1 | grep -E '^192\.168\.2\.(5|6)$' | head -n 1 || true)"

case "$LOCAL_IP" in
    "$NFS1_IP")
        # NFS1은 기본 MASTER 후보이며 우선순위를 더 높게 둔다.
        DEFAULT_ROLE="MASTER"
        DEFAULT_PRIORITY="150"
        LOCAL_SYNC_USER="$NFS1_USER"
        PEER_IP="$NFS2_IP"
        PEER_SYNC_USER="$NFS2_USER"
        ;;
    "$NFS2_IP")
        # NFS2는 기본 BACKUP 후보이며 우선순위를 낮게 둔다.
        DEFAULT_ROLE="BACKUP"
        DEFAULT_PRIORITY="100"
        LOCAL_SYNC_USER="$NFS2_USER"
        PEER_IP="$NFS1_IP"
        PEER_SYNC_USER="$NFS1_USER"
        ;;
    *)
        echo "[ERROR] Current IP does not match NFS1 or NFS2."
        echo "        Expected ${NFS1_IP} or ${NFS2_IP} on ${IFACE}."
        exit 1
        ;;
esac

# 인자로 ROLE/PRIORITY를 주지 않았으면 IP 기준 기본값을 사용한다.
ROLE="${ROLE:-$DEFAULT_ROLE}"
PRIORITY="${PRIORITY:-$DEFAULT_PRIORITY}"

# 사용자가 master/backUP처럼 입력해도 MASTER/BACKUP으로 통일한다.
ROLE="$(echo "$ROLE" | tr '[:lower:]' '[:upper:]')"

case "$ROLE" in
    MASTER|BACKUP)
        ;;
    *)
        echo "[ERROR] ROLE must be MASTER or BACKUP."
        exit 1
        ;;
esac

ensure_local_sync_user() {
    # rsync는 root가 아니라 nfs1/nfs2 전용 계정으로 실행한다.
    # 계정이 이미 있으면 아무것도 하지 않는다.
    # root로 rsync를 바로 돌리면 편하기는 하지만, SSH key와 파일 복제 권한이 너무 커진다.
    # 그래서 실습 편의와 최소 권한 사이의 타협점으로 nfs1/nfs2 전용 계정을 쓴다.
    if id "$LOCAL_SYNC_USER" >/dev/null 2>&1; then
        return
    fi

    # 편의 우선 모드라서 계정이 없으면 자동으로 만든다.
    # 단, 상대 서버에 public key를 등록하는 ssh-copy-id는 사람이 직접 해야 한다.
    # ssh-copy-id는 상대 서버 비밀번호 입력이 필요할 수 있으므로 완전 자동화하지 않는다.
    echo "[INFO] Local sync user '${LOCAL_SYNC_USER}' does not exist. Creating it for convenience mode."
    sudo useradd -m -s /bin/bash "$LOCAL_SYNC_USER"
}

ensure_local_sync_user

echo "[INFO] Interface=${IFACE}, Local_IP=${LOCAL_IP}, Role=${ROLE}, Priority=${PRIORITY}"
echo "[INFO] Sync direction when VIP is local: ${LOCAL_SYNC_USER}@${LOCAL_IP} -> ${PEER_SYNC_USER}@${PEER_IP}"
echo "[INFO] Convenience mode keeps export ${EXPORT_NET} and chmod 777 on ${SHARE_DIR}."
if [ -n "$DELETE_OPT" ]; then
    echo "[INFO] Sync delete policy: ${DELETE_OPT}"
else
    echo "[INFO] Sync delete policy: disabled by default. Set SYNC_DELETE_OPT='--delete-delay' only after manual validation."
fi

# =====================================================
# 2. 필요한 패키지를 설치한다.
# =====================================================
echo "[STEP 2/9] Installing NFS, keepalived, rsync, SSH, and cron packages."

# nfs-kernel-server: NFS 서버 역할
# keepalived: VIP 장애조치
# rsync: NFS1/NFS2 파일 복제
# openssh-client/server: nfs1/nfs2 계정 간 SSH key 동기화
# cron: 1분마다 자동 동기화 스크립트 실행
sudo apt update
sudo apt install -y nfs-kernel-server keepalived rsync openssh-client openssh-server cron

# SSH와 cron은 자동 sync의 기반 서비스다.
# enable은 부팅 후 자동 시작, restart는 현재 세션에서 바로 적용하기 위한 것이다.
sudo systemctl enable ssh cron || true
sudo systemctl restart ssh || true

# =====================================================
# 3. NFS 공유 디렉터리를 준비한다.
# =====================================================
echo "[STEP 3/9] Preparing NFS shared directory."

# /share_directory가 없으면 만든다.
sudo mkdir -p "$SHARE_DIR"

# nobody:nogroup은 NFS의 익명/공유 접근에서 흔히 쓰는 소유자다.
sudo chown nobody:nogroup "$SHARE_DIR"

# 편의 우선 실습 모드라 777을 사용한다.
# 운영 보안 기준으로는 너무 넓은 권한이므로 Tomcat 전용 UID/GID 방식이 더 안전하다.
sudo chmod 777 "$SHARE_DIR"

# =====================================================
# 4. NFS export를 등록한다.
# =====================================================
echo "[STEP 4/9] Registering NFS export."

# 같은 공유 디렉터리에 대한 기존 /etc/exports 줄을 먼저 제거한다.
# 재실행할 때 중복 export가 쌓이는 것을 막기 위한 처리다.
sudo sed -i "\|^${SHARE_DIR}[[:space:]]|d" /etc/exports

# 새 export 줄을 추가한다.
# rw: 읽기/쓰기 허용
# sync: 쓰기 요청을 안정적으로 처리한 뒤 응답
# no_subtree_check: 하위 디렉터리 export 검사로 인한 문제를 줄임
echo "$EXPORT_LINE" | sudo tee -a /etc/exports > /dev/null

# /etc/exports 변경사항을 현재 NFS 서버에 반영한다.
sudo exportfs -arv

# =====================================================
# 5. keepalived health check 스크립트를 만든다.
# =====================================================
echo "[STEP 5/9] Creating keepalived health check script."

# keepalived는 이 스크립트를 주기적으로 실행한다.
# 실패하면 해당 노드는 NFS 서비스가 정상이라고 보기 어렵기 때문에 VIP를 놓을 수 있다.
sudo tee /usr/local/bin/check_nfs.sh > /dev/null << 'EOF'
#!/bin/sh
SHARE_DIR="/share_directory"

# NFS 서버 데몬이 살아 있는지 확인한다.
systemctl is-active --quiet nfs-kernel-server

# 공유 디렉터리가 존재하고 쓰기 가능한지 확인한다.
test -d "$SHARE_DIR" || exit 1
test -w "$SHARE_DIR" || exit 1

# 실제 파일 생성/삭제가 가능한지 확인한다.
touch "$SHARE_DIR/.nfs-healthcheck" || exit 1
rm -f "$SHARE_DIR/.nfs-healthcheck" || exit 1

# NFS export 목록에 공유 디렉터리가 실제로 등록되어 있는지 확인한다.
exportfs -v | awk -v dir="$SHARE_DIR" '$1 == dir {found=1} END {exit !found}' || exit 1
EOF
sudo chmod 755 /usr/local/bin/check_nfs.sh

# =====================================================
# 6. 자동 rsync 동기화 스크립트를 만든다.
# - cron이 로컬 NFS sync 계정(nfs1 또는 nfs2)으로 실행한다.
# - 이 서버가 VIP를 가진 경우에만 동작한다.
# - 상대 서버 계정으로 SSH key 로그인이 가능해야 한다.
# =====================================================
echo "[STEP 6/9] Creating NFS sync script."

# sync 계정의 홈 디렉터리를 찾아 SSH key 저장 디렉터리를 준비한다.
LOCAL_HOME="$(getent passwd "$LOCAL_SYNC_USER" | cut -d: -f6)"
sudo -u "$LOCAL_SYNC_USER" mkdir -p "${LOCAL_HOME}/.ssh"
sudo chmod 700 "${LOCAL_HOME}/.ssh"

# sync 계정에 ed25519 SSH key가 없으면 새로 만든다.
# 이 key의 public key를 상대 서버에 ssh-copy-id로 등록해야 자동 rsync가 된다.
if [ ! -f "${LOCAL_HOME}/.ssh/id_ed25519" ]; then
    echo "[INFO] Creating SSH key for ${LOCAL_SYNC_USER}."
    sudo -u "$LOCAL_SYNC_USER" ssh-keygen -t ed25519 -N "" -f "${LOCAL_HOME}/.ssh/id_ed25519"
fi

# cron으로 실행되는 rsync 로그 파일이다.
# 편의상 누구나 쓸 수 있게 666으로 두지만, 운영 보안 기준으로는 더 제한하는 것이 맞다.
sudo touch "$SYNC_LOG"
sudo chmod 666 "$SYNC_LOG"

# 실제 자동 동기화 스크립트를 /usr/local/bin/nfs_ha_sync.sh에 생성한다.
# 이 파일은 cron에서 1분마다 실행된다.
# 주의:
# - 여기서 만드는 파일은 이 설치 스크립트와 별개의 "운영 중 실행되는 스크립트"다.
# - 아래 EOF 안의 값들은 설치 시점의 VIP, IFACE, peer IP를 박아서 저장한다.
# - 나중에 IP나 계정이 바뀌면 이 설치 스크립트를 다시 돌리거나 해당 파일을 직접 수정해야 한다.
sudo tee "$SYNC_SCRIPT" > /dev/null << EOF
#!/bin/bash
set -u

# 설치 시점에 계산된 값들을 동기화 스크립트 안에 고정한다.
VIP="${VIP}"
IFACE="${IFACE}"
SHARE_DIR="${SHARE_DIR}"
PEER="${PEER_SYNC_USER}@${PEER_IP}"
SYNC_LOG="${SYNC_LOG}"
LOCK_FILE="${LOCK_FILE}"
DELETE_OPT="${DELETE_OPT}"

log() {
    # cron 환경에서는 화면이 없으므로 모든 상태를 로그 파일에 남긴다.
    echo "\$(date -Is) \$*" >> "\$SYNC_LOG"
}

# 이 서버가 VIP를 가지고 있지 않으면 원본 노드가 아니므로 아무것도 하지 않는다.
# 이 조건 덕분에 NFS1/NFS2가 동시에 서로 덮어쓰는 상황을 줄인다.
if ! ip addr show dev "\$IFACE" | grep -q "\$VIP"; then
    exit 0
fi

# VIP를 가지고 있어도 NFS 서버 데몬이 죽어 있으면 복제하지 않는다.
if ! systemctl is-active --quiet nfs-kernel-server; then
    log "skip: nfs-kernel-server is not active"
    exit 0
fi

# 상대 서버에 SSH key로 비밀번호 없이 접속 가능한지 확인한다.
# 실패하면 rsync를 시도하지 않고 로그만 남긴다.
if ! ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "\$PEER" "test -d \"\$SHARE_DIR\""; then
    log "skip: SSH key login or remote share is not ready for \$PEER:\$SHARE_DIR"
    exit 0
fi

# flock은 이전 rsync가 아직 끝나지 않았는데 다음 rsync가 겹쳐 실행되는 것을 막는다.
# rsync -rltv는 파일/디렉터리/시간 정보를 복제한다.
# --no-owner --no-group --no-perms는 상대 서버에서 소유자/권한 충돌을 줄이기 위한 편의 우선 설정이다.
# DELETE_OPT는 기본 빈 값이므로 삭제 동기화가 꺼져 있다.
# 이 rsync는 "현재 VIP 소유 NFS -> peer NFS" 한 방향이다.
# 양방향 실시간 충돌 해결 도구가 아니므로, 양쪽에서 동시에 다른 파일을 수정하는 구조에는 맞지 않는다.
if ! flock -n "\$LOCK_FILE" rsync -rltv \$DELETE_OPT --no-owner --no-group --no-perms --omit-dir-times \\
    "\${SHARE_DIR}/" "\${PEER}:\${SHARE_DIR}/" >> "\$SYNC_LOG" 2>&1; then
    log "warn: sync failed or previous sync is still running"
fi
EOF

sudo chmod 755 "$SYNC_SCRIPT"

sync_ready() {
    # 현재 로컬 sync 계정이 상대 서버에 비밀번호 없이 접속할 수 있는지 확인한다.
    # ssh-copy-id가 끝나지 않았으면 여기서 실패한다.
    sudo -u "$LOCAL_SYNC_USER" ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 \
        "${PEER_SYNC_USER}@${PEER_IP}" "test -d '${SHARE_DIR}' -a -w '${SHARE_DIR}'"
}

print_disk_status() {
    # 공유 디렉터리가 위치한 파일시스템 사용률을 확인한다.
    # 디스크가 꽉 차면 upload와 rsync가 모두 실패할 수 있다.
    DISK_USAGE="$(df -P "$SHARE_DIR" 2>/dev/null | awk 'NR == 2 {gsub("%", "", $5); print $5}' || true)"
    echo "[INFO] Disk usage for ${SHARE_DIR}:"
    df -h "$SHARE_DIR" || true

    if [ -n "$DISK_USAGE" ] && [ "$DISK_USAGE" -ge "$DISK_WARN_PERCENT" ]; then
        echo "[WARN] ${SHARE_DIR} filesystem usage is ${DISK_USAGE}%."
        echo "[WARN] Upload and rsync can fail when this filesystem becomes full."
    fi
}

print_ufw_status() {
    # UFW가 켜져 있으면 NFS/SSH/VRRP 관련 허용 상태를 사람이 확인할 수 있게 출력한다.
    echo "[INFO] UFW status relevant to NFS/VRRP/SSH:"
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw status verbose || true
    else
        echo "[INFO] ufw command not found."
    fi
}

print_sync_log_status() {
    # 최근 rsync 로그를 보여준다.
    # skip/warn/failed/denied 같은 단어가 있으면 자동 동기화가 아직 준비되지 않았을 수 있다.
    echo "[INFO] Recent sync log:"
    if [ -s "$SYNC_LOG" ]; then
        tail -n 30 "$SYNC_LOG" || true
        if tail -n 50 "$SYNC_LOG" | grep -Eiq 'warn:|skip:|error|failed|denied|timeout'; then
            echo "[WARN] Recent sync log contains warnings or failures. Check ${SYNC_LOG}."
        fi
    else
        echo "[INFO] ${SYNC_LOG} has no entries yet."
    fi
}

# =====================================================
# 7. cron 자동 실행을 등록한다.
# =====================================================
echo "[STEP 7/9] Registering cron job for automatic sync."

# /etc/cron.d/nfs-ha-sync 파일을 만들어 매분 sync 스크립트를 실행한다.
# 실제 sync 스크립트 안에서 VIP 소유 여부를 확인하므로 BACKUP 노드에서는 실행되어도 바로 종료된다.
sudo tee "$CRON_FILE" > /dev/null << EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
* * * * * ${LOCAL_SYNC_USER} ${SYNC_SCRIPT}
EOF
sudo chmod 644 "$CRON_FILE"
sudo systemctl restart cron || true

# =====================================================
# 8. keepalived VIP 장애조치를 설정한다.
# =====================================================
echo "[STEP 8/9] Writing keepalived configuration."

# keepalived 설정 파일을 새로 작성한다.
# state는 일부러 BACKUP으로 고정한다.
# 실제 MASTER/BACKUP 결정은 priority와 VRRP 선출로 처리한다.
# 이렇게 하면 설정 파일의 state 글자보다 priority와 현재 상태가 더 중요해진다.
# NFS1은 기본 priority 150, NFS2는 기본 priority 100이므로 정상 시작 시 NFS1이 VIP 후보가 된다.
# 단, nopreempt가 있으므로 장애 후 복구된 NFS1이 VIP를 자동으로 다시 빼앗지는 않는다.
sudo tee /etc/keepalived/keepalived.conf > /dev/null << EOF
global_defs {
    router_id NFS_${ROLE}
    enable_script_security
    script_user root
}

vrrp_script chk_nfs {
    script "/usr/local/bin/check_nfs.sh"
    interval 2
    fall 2
    rise 2
}

vrrp_instance VI_NFS {
    state BACKUP
    interface ${IFACE}
    virtual_router_id ${VRID}
    priority ${PRIORITY}
    advert_int 1
    # nopreempt:
    # 장애났던 높은 priority 노드가 복구되어도 VIP를 자동으로 다시 빼앗지 않는다.
    # 자동 failback으로 인한 불필요한 흔들림을 줄이기 위한 설정이다.
    nopreempt
    authentication {
        auth_type PASS
        auth_pass ${AUTH_PASS}
    }
    virtual_ipaddress {
        ${VIP}/24
    }
    track_script {
        chk_nfs
    }
}
EOF

# =====================================================
# 9. 서비스를 재시작하고 검증 정보를 출력한다.
# =====================================================
echo "[STEP 9/9] Restarting NFS, keepalived, and cron."

# 부팅 후에도 NFS/keepalived/cron이 자동 시작되게 등록한다.
sudo systemctl enable nfs-kernel-server keepalived cron

# 설정 파일 변경을 반영하기 위해 관련 서비스를 재시작한다.
sudo systemctl restart nfs-kernel-server
sudo systemctl restart keepalived
sudo systemctl restart cron || true

# 실습 편의상 UFW 규칙을 추가한다.
# 2049/tcp: NFSv4 기본 포트
# 22/tcp: ssh-copy-id와 rsync over SSH
# 224.0.0.18: keepalived VRRP multicast
# UFW가 inactive라면 규칙을 추가해도 즉시 필터링되지는 않는다.
# 그래도 나중에 UFW를 enable했을 때 필요한 흐름이 막히지 않도록 미리 등록한다.
sudo ufw allow 2049/tcp || true
sudo ufw allow 22/tcp || true
sudo ufw allow in on "$IFACE" from "$EXPORT_NET" to 224.0.0.18 comment 'keepalived multicast' || true
print_ufw_status

echo "[INFO] Waiting for keepalived to settle."

# keepalived가 VIP를 붙일 시간을 잠깐 기다린다.
# MASTER 후보면 보통 몇 초 안에 VIP가 보인다.
WAIT_TIME=0
MAX_WAIT=15
VIP_READY="no"

while [ "$WAIT_TIME" -lt "$MAX_WAIT" ]; do
    if ip addr show dev "$IFACE" | grep -q "$VIP"; then
        VIP_READY="yes"
        break
    fi

    sleep 1
    WAIT_TIME=$((WAIT_TIME + 1))
    echo "[INFO] Waiting for VIP ${VIP}... (${WAIT_TIME}/${MAX_WAIT}s)"
done

if [ "$VIP_READY" = "yes" ]; then
    # 이 서버가 현재 VIP 소유자라면 원본 NFS 역할이다.
    # SSH key 준비가 끝났다면 즉시 한 번 rsync를 실행해 초기 동기화를 시도한다.
    echo "[INFO] This node currently owns NFS VIP ${VIP}."
    if sync_ready; then
        echo "[INFO] Automatic sync SSH key login is ready."
        echo "[INFO] Running one immediate sync attempt."
        sudo -u "$LOCAL_SYNC_USER" "$SYNC_SCRIPT" || true
    else
        # mount 자체는 가능할 수 있지만, SSH key가 없으면 자동 rsync는 아직 안 된다.
        echo "[WARN] Automatic sync is NOT ready."
        echo "[WARN] If ssh-copy-id asks for a password and fails, set the peer user's password on the peer node first:"
        echo "       sudo passwd ${PEER_SYNC_USER}"
        echo "[WARN] Then run this on the current node, then retry manual sync:"
        echo "       sudo -u ${LOCAL_SYNC_USER} ssh-copy-id ${PEER_SYNC_USER}@${PEER_IP}"
    fi
else
    # 이 서버가 현재 VIP를 갖고 있지 않으면 BACKUP처럼 대기한다.
    # cron은 돌지만 sync 스크립트가 VIP 체크 후 바로 종료한다.
    echo "[INFO] This node does not currently own NFS VIP ${VIP}. Sync cron will stay idle here."
    if sync_ready; then
        echo "[INFO] Automatic sync SSH key login is ready for future VIP ownership."
    else
        echo "[WARN] Automatic sync is NOT ready for future VIP ownership."
        echo "[WARN] If ssh-copy-id asks for a password and fails, set the peer user's password on the peer node first:"
        echo "       sudo passwd ${PEER_SYNC_USER}"
        echo "[WARN] Then run this on this node:"
        echo "       sudo -u ${LOCAL_SYNC_USER} ssh-copy-id ${PEER_SYNC_USER}@${PEER_IP}"
    fi
fi

print_disk_status
print_sync_log_status

echo "[SUCCESS] NFS HA server setup completed."
echo "[INFO] keepalived uses nopreempt. If this node recovers after failover, it will not automatically steal VIP back."
echo "[INFO] SSH key setup required for unattended sync:"
echo "       If ssh-copy-id asks for a password and fails, set it on the peer first: sudo passwd ${PEER_SYNC_USER}"
echo "       sudo -u ${LOCAL_SYNC_USER} ssh-copy-id ${PEER_SYNC_USER}@${PEER_IP}"
echo "[INFO] Manual immediate sync:"
echo "       sudo -u ${LOCAL_SYNC_USER} ${SYNC_SCRIPT}"
echo "[INFO] Verification commands:"
echo "       ip a | grep ${VIP}"
echo "       sudo exportfs -v"
echo "       systemctl status nfs-kernel-server --no-pager"
echo "       systemctl status keepalived --no-pager"
echo "       systemctl status cron --no-pager"
echo "       tail -n 50 ${SYNC_LOG}"
echo "       df -h ${SHARE_DIR}"
echo "       sudo ufw status verbose"
echo "[INFO] Split-brain suspicion checks:"
echo "       ip a | grep ${VIP}"
echo "       journalctl -u keepalived -n 80 --no-pager"
echo "       ping -c 3 ${PEER_IP}"

# 운영자가 기억해야 할 마지막 요약:
# - WEB은 NFS VIP만 mount한다.
# - VIP를 가진 NFS만 peer로 rsync한다.
# - 자동 delete sync는 기본 OFF다.
# - SSH key 등록 전에는 NFS mount는 가능해도 NFS1/NFS2 자동 복제는 준비되지 않은 상태다.
# - 이 구조는 실습용 편의 HA이며, 무손실 스토리지 클러스터가 아니다.
