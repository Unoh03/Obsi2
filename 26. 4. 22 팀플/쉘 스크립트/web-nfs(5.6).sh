#!/bin/bash
set -euo pipefail

# =====================================================
# WEB NFS HA 클라이언트 설정 스크립트 (5.6)
#
# 이 스크립트의 목적:
# - WEB 서버의 upload 디렉터리를 NFS VIP에 mount한다.
# - WEB은 NFS1/NFS2 실제 IP를 직접 보지 않고 VIP(192.168.2.50)만 바라본다.
# - 기존 로컬 upload 파일이 있으면 NFS mount 전에 백업한다.
# - 잘못된 NFS 서버나 중복 mount가 있으면 멈춰서 데이터 사고를 막는다.
#
# 처음 읽는 사람을 위한 큰 흐름:
# 1. WEB 서버에 NFS client 도구를 설치한다.
# 2. Tomcat upload 디렉터리를 mount point로 준비한다.
# 3. 이미 mount되어 있으면 VIP에서 온 정상 mount인지 확인한다.
# 4. 잘못된 source나 중복 mount가 있으면 자동 수정하지 않고 중단한다.
# 5. mount 전 로컬 upload 파일이 있으면 백업한다.
# 6. /etc/fstab에는 NFS1/NFS2 실제 IP가 아니라 NFS VIP만 등록한다.
# 7. 즉시 mount를 수행하고 결과가 VIP source인지 다시 확인한다.
#
# 핵심 개념:
# - 이 스크립트는 WEB 서버용이다. NFS 서버에서 실행하면 안 된다.
# - WEB 서버는 파일 서버 장애조치 여부를 몰라도 된다.
# - WEB 서버 입장에서는 항상 192.168.2.50:/share_directory가 upload 저장소다.
# - NFS1/NFS2 사이 복제는 이 스크립트가 아니라 nfs-ha(5.6).sh가 담당한다.
#
# 고정 구성:
# - NFS VIP: 192.168.2.50
# - 원격 NFS 공유: /share_directory
# - WEB mount 위치: /opt/tomcat/tomcat-10/webapps/upload
#
# 4.28.2에서 유지한 것:
# - WEB은 NFS1/NFS2 실제 IP가 아니라 NFS VIP만 mount한다.
# - 기존 로컬 upload 파일은 mount 전에 백업한다.
# - 백업 파일은 기존 NFS 파일을 덮어쓰지 않고 복사한다.
# - 중복 mount 또는 잘못된 source mount를 감지한다.
#
# 편의 우선 모드:
# - NFS 클라이언트 도구와 lsof를 함께 설치한다.
# - NFSv4/TCP를 기본으로 사용해서 서버 방화벽은 2049/tcp 중심으로 단순화한다.
#
# 이 스크립트가 하지 않는 일:
# - NFS1/NFS2 사이 데이터 동기화는 서버 스크립트 nfs-ha(5.6).sh가 담당한다.
# - 자동 rsync 설정도 이 WEB 스크립트가 아니라 NFS 서버 쪽 스크립트가 담당한다.
# =====================================================

# 첫 번째 인자로 VIP를 바꿀 수 있지만, 기본값은 팀플 NFS VIP다.
NFS_VIP="${1:-192.168.2.50}"

# NFS_VERSION 환경변수로 버전을 바꿀 수 있다.
# 기본은 NFSv4이며, 실제 mount 결과에서는 서버/클라이언트 협상으로 4.2처럼 보일 수 있다.
NFS_VERSION="${NFS_VERSION:-4}"

# NFS 서버가 export하는 디렉터리와 WEB 서버에서 mount할 위치다.
REMOTE_SHARE="/share_directory"
MOUNT_DIR="/opt/tomcat/tomcat-10/webapps/upload"

# mount 전에 기존 로컬 upload 파일을 백업할 기준 경로다.
BACKUP_BASE="/opt/tomcat"

# 이 WEB 서버가 최종적으로 mount해야 하는 유일한 정상 source다.
EXPECTED_SOURCE="${NFS_VIP}:${REMOTE_SHARE}"

# /etc/fstab에 들어갈 mount 옵션이다.
# nofail: 부팅 시 NFS가 잠깐 죽어 있어도 WEB 서버 부팅 자체를 막지 않는다.
# _netdev: 네트워크 파일시스템임을 systemd에 알려준다.
# vers/proto: NFSv4/TCP를 사용해서 포트와 방화벽 구성을 단순하게 만든다.
# hard: NFS 서버가 잠깐 응답하지 않아도 쓰기 요청을 쉽게 포기하지 않는다.
# x-systemd.*: 부팅/종료 중 NFS 때문에 오래 멈추는 상황을 줄인다.
# 운영상 의미:
# - hard mount는 데이터 일관성에는 유리하지만, NFS가 오래 죽으면 애플리케이션이 기다릴 수 있다.
# - nofail과 x-systemd timeout은 서버 부팅/종료가 NFS 때문에 완전히 멈추는 위험을 줄인다.
# - timeo/retrans는 장애를 너무 늦게 감지하지 않도록 조정한 실습용 값이다.
FSTAB_OPTIONS="defaults,_netdev,nofail,vers=${NFS_VERSION},proto=tcp,hard,timeo=50,retrans=2,x-systemd.automount,x-systemd.idle-timeout=30s,x-systemd.device-timeout=5s,x-systemd.mount-timeout=10s"

# 지금 즉시 mount/remount할 때 사용할 런타임 옵션이다.
# fstab 전용 옵션인 nofail, x-systemd.*는 여기에 넣지 않는다.
RUNTIME_OPTIONS="rw,vers=${NFS_VERSION},proto=tcp,hard,timeo=50,retrans=2"

# /etc/fstab에 최종으로 들어갈 한 줄이다.
FSTAB_LINE="${EXPECTED_SOURCE} ${MOUNT_DIR} nfs ${FSTAB_OPTIONS} 0 0"

echo "[INFO] WEB NFS HA client setup started."
echo "[INFO] Source=${EXPECTED_SOURCE}, Mount=${MOUNT_DIR}"

mount_sources() {
    # 현재 mount point에 연결된 source 목록만 추출한다.
    # 정상이라면 192.168.2.50:/share_directory 한 줄만 나와야 한다.
    findmnt -n -o SOURCE --target "$MOUNT_DIR" 2>/dev/null | sed '/^[[:space:]]*$/d' || true
}

mount_source_count() {
    # 같은 mount point가 여러 번 mount되어 있는지 확인하기 위해 source 개수를 센다.
    mount_sources | wc -l
}

current_mount_source() {
    # 현재 mount source 중 첫 번째 값을 가져온다.
    mount_sources | head -n 1
}

is_mounted() {
    # mount source가 하나 이상 있으면 이미 mount된 상태로 본다.
    [ "$(mount_source_count)" -gt 0 ]
}

is_expected_source() {
    # NFS client 출력은 끝에 /가 붙을 수도 있어서 두 형태를 모두 정상으로 인정한다.
    [ "$1" = "$EXPECTED_SOURCE" ] || [ "$1" = "$EXPECTED_SOURCE/" ]
}

print_mount_status() {
    # 사람이 바로 확인할 수 있게 findmnt/df/mount 결과를 함께 출력한다.
    echo "[INFO] Mount status:"
    findmnt --target "$MOUNT_DIR" || true
    df -h | grep "$MOUNT_DIR" || true
    mount | grep "$MOUNT_DIR" || true
}

print_mount_debug() {
    # mount 실패나 중복 mount가 있을 때 원인 확인에 필요한 정보를 한 번에 출력한다.
    echo "[DEBUG] fstab entries for this mount point:"
    grep -n "$MOUNT_DIR" /etc/fstab || true
    echo "[DEBUG] findmnt:"
    findmnt --target "$MOUNT_DIR" || true
    echo "[DEBUG] mount output:"
    mount | grep -E "$NFS_VIP|$REMOTE_SHARE|$MOUNT_DIR" || true
    echo "[DEBUG] /proc/mounts:"
    grep -E "$NFS_VIP|$REMOTE_SHARE|$MOUNT_DIR" /proc/mounts || true
}

register_fstab() {
    # /etc/fstab에 NFS VIP mount 규칙을 등록한다.
    # 같은 mount point에 대한 기존 줄은 먼저 제거해서 중복 mount를 막는다.
    # 여기서 제거 기준은 mount point다.
    # 예전 설정이 192.168.2.5 또는 192.168.2.6 실제 IP를 보고 있었다면 그 줄도 제거된다.
    echo "[INFO] Registering NFS VIP mount in /etc/fstab."
    sudo sed -i "\|[[:space:]]${MOUNT_DIR}[[:space:]]|d" /etc/fstab
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null

    # systemd가 fstab 변경을 다시 읽도록 한다.
    sudo systemctl daemon-reload
}

remount_current_mount() {
    # 이미 정상 VIP로 mount되어 있는 경우, fstab만 고치고 끝내지 않고 현재 mount 옵션도 갱신해 본다.
    # 실패해도 fstab은 갱신되어 있으므로 다음 reboot/remount 때 적용될 수 있다.
    echo "[INFO] Remounting current NFS mount with updated runtime options."
    if timeout 20s sudo mount -o "remount,${RUNTIME_OPTIONS}" "$MOUNT_DIR"; then
        echo "[INFO] Remount completed."
    else
        echo "[WARN] Remount failed or timed out. fstab is updated, but runtime options may apply after reboot/remount."
    fi
}

# =====================================================
# 1. NFS 클라이언트 패키지를 설치한다.
# =====================================================
echo "[STEP 1/7] Installing nfs-common and lsof."

# nfs-common: Linux에서 NFS mount를 수행하는 클라이언트 도구
# lsof: stale mount나 umount 실패 시 어떤 프로세스가 파일을 잡고 있는지 확인하는 도구
sudo apt update
sudo apt install -y nfs-common lsof

# =====================================================
# 2. upload mount point를 준비한다.
# =====================================================
echo "[STEP 2/7] Preparing upload mount point."

# Tomcat upload 디렉터리가 없으면 만든다.
# 아직 mount하기 전이므로 이 디렉터리는 로컬 디렉터리다.
sudo mkdir -p "$MOUNT_DIR"

# =====================================================
# 3. 이미 mount되어 있으면 정상/비정상을 먼저 판별한다.
# =====================================================
echo "[STEP 3/7] Checking current mount state."
if is_mounted; then
    MOUNT_COUNT="$(mount_source_count)"
    if [ "$MOUNT_COUNT" -gt 1 ]; then
        # 같은 upload 경로에 mount가 여러 개 걸려 있으면 어떤 NFS를 쓰는지 불명확하다.
        # 데이터 사고를 막기 위해 자동으로 고치지 않고 중단한다.
        echo "[ERROR] ${MOUNT_DIR} is mounted multiple times."
        echo "[ERROR] Unmount it until no mount remains, then run this script again:"
        echo "        sudo umount ${MOUNT_DIR}"
        echo "        sudo umount ${MOUNT_DIR}"
        print_mount_debug
        exit 1
    fi

    CURRENT_SOURCE="$(current_mount_source)"

    if is_expected_source "$CURRENT_SOURCE"; then
        # 이미 VIP로 정상 mount되어 있으면 새로 mount하지 않는다.
        # 대신 fstab을 현재 정책으로 갱신하고 remount를 시도한다.
        # 이 분기 덕분에 스크립트를 재실행해도 정상 mount를 억지로 끊지 않는다.
        # 운영 중 upload가 사용 중일 수 있으므로 불필요한 umount는 피한다.
        echo "[INFO] ${MOUNT_DIR} is already mounted from ${CURRENT_SOURCE}."
        register_fstab
        remount_current_mount
        print_mount_status
        echo "[SUCCESS] WEB NFS HA client setup is already applied and fstab is updated."
        exit 0
    fi

    # 이미 다른 source로 mount되어 있으면 위험하다.
    # 예: 192.168.2.5:/share_directory처럼 물리 NFS IP를 직접 보고 있으면 HA 구조가 깨진다.
    echo "[ERROR] ${MOUNT_DIR} is already mounted from an unexpected source."
    echo "[ERROR] Current source: ${CURRENT_SOURCE:-unknown}"
    echo "[ERROR] Expected source: ${EXPECTED_SOURCE}"
    echo "[ERROR] Unmount it manually after checking data, then run this script again."
    exit 1
fi

# =====================================================
# 4. NFS mount 전에 기존 로컬 upload 파일을 백업한다.
# =====================================================
echo "[STEP 4/7] Checking existing local upload files."
BACKUP_DIR=""

if sudo find "$MOUNT_DIR" -mindepth 1 -print -quit | grep -q .; then
    # NFS를 mount하면 기존 로컬 디렉터리 내용은 화면에서 가려진다.
    # 그래서 mount 전에 /opt/tomcat/upload-local-backup-날짜 형태로 백업한다.
    # 이 백업은 "삭제"가 아니라 "보존"이다.
    # mount 후 같은 이름의 파일이 NFS에 이미 있으면 덮어쓰지 않도록 나중에 cp -n으로 복사한다.
    BACKUP_DIR="${BACKUP_BASE}/upload-local-backup-$(date +%Y%m%d-%H%M%S)"
    echo "[INFO] Existing local files found. Backing up to ${BACKUP_DIR}."
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp -a "${MOUNT_DIR}/." "$BACKUP_DIR/"
else
    echo "[INFO] No existing local upload files found."
fi

# =====================================================
# 5. /etc/fstab에 NFS VIP mount를 등록한다.
# - 같은 mount point의 이전 규칙은 제거한다.
# - HA 구조에서는 NFS1/NFS2 실제 IP가 아니라 VIP만 mount해야 한다.
# =====================================================
echo "[STEP 5/7] Registering NFS VIP mount in /etc/fstab."
register_fstab

# =====================================================
# 6. NFS mount를 즉시 적용한다.
# - 최초 mount는 mount -a에만 맡기지 않는다.
# - 직접 mount해야 실패 원인을 바로 볼 수 있다.
# =====================================================
echo "[STEP 6/7] Checking NFS export and applying mount."
if [[ "$NFS_VERSION" = 4* ]]; then
    # showmount는 NFSv3/rpcbind 쪽 확인 도구라 NFSv4/TCP 모드에서는 혼란을 줄 수 있다.
    # 그래서 NFSv4일 때는 showmount를 건너뛰고 직접 mount를 시도한다.
    echo "[INFO] NFSv${NFS_VERSION}/TCP mode: skipping showmount because it is NFSv3/rpcbind oriented."
else
    # NFSv3 계열을 사용할 때만 export 목록 확인을 시도한다.
    showmount -e "$NFS_VIP" || echo "[WARN] showmount failed. Trying direct NFS mount anyway."
fi

# timeout을 둬서 NFS 서버 문제로 mount 명령이 오래 멈추는 것을 줄인다.
# mount -a만 쓰지 않는 이유:
# - fstab이 틀렸을 때 어느 줄에서 실패했는지 초보자가 보기 어렵다.
# - 직접 source와 mount point를 지정하면 실패 원인을 바로 좁힐 수 있다.
if timeout 20s sudo mount -v -t nfs -o "$RUNTIME_OPTIONS" "$EXPECTED_SOURCE" "$MOUNT_DIR"; then
    echo "[INFO] Direct NFS mount command completed."
else
    echo "[ERROR] Direct NFS mount command failed."
    print_mount_debug
    exit 1
fi

if ! is_mounted; then
    # mount 명령이 성공처럼 보였는데 실제 mount가 없으면 실패로 본다.
    echo "[ERROR] ${MOUNT_DIR} is not mounted after direct mount."
    print_mount_debug
    exit 1
fi

MOUNT_COUNT="$(mount_source_count)"
if [ "$MOUNT_COUNT" -gt 1 ]; then
    # 직접 mount 후에도 중복 mount가 감지되면 더 진행하지 않는다.
    echo "[ERROR] ${MOUNT_DIR} is mounted multiple times after direct mount."
    echo "[ERROR] Unmount it until no mount remains, then run this script again:"
    echo "        sudo umount ${MOUNT_DIR}"
    echo "        sudo umount ${MOUNT_DIR}"
    print_mount_debug
    exit 1
fi

CURRENT_SOURCE="$(current_mount_source)"
if ! is_expected_source "$CURRENT_SOURCE"; then
    # mount가 되었더라도 VIP가 아니면 HA 목적에 맞지 않으므로 실패 처리한다.
    echo "[ERROR] ${MOUNT_DIR} mounted from unexpected source after mount."
    echo "[ERROR] Current source: ${CURRENT_SOURCE:-unknown}"
    echo "[ERROR] Expected source: ${EXPECTED_SOURCE}"
    print_mount_debug
    exit 1
fi

if [ -n "$BACKUP_DIR" ]; then
    # 백업했던 로컬 upload 파일을 NFS로 복사한다.
    # -n 옵션으로 같은 이름의 파일은 덮어쓰지 않는다.
    # 소유권 보존은 하지 않는다. NFS nobody/nogroup 환경과 충돌을 줄이기 위해서다.
    echo "[INFO] Copying backup files to NFS without overwriting existing files or preserving ownership."
    sudo cp -rn "${BACKUP_DIR}/." "$MOUNT_DIR/"
    echo "[INFO] Local backup remains at ${BACKUP_DIR}."
fi

# =====================================================
# 7. mount 결과와 사후 확인 명령을 출력한다.
# =====================================================
echo "[STEP 7/7] Verifying mount result."
print_mount_status

# 여기서부터는 사람이 복사해서 확인할 수 있는 명령이다.
# touch 명령으로 실제 NFS upload 경로에 파일을 만들고 NFS1/NFS2에서 보이는지 확인한다.
echo "[SUCCESS] WEB NFS HA client setup completed."
echo "[INFO] Check commands:"
echo "       df -h | grep ${MOUNT_DIR}"
echo "       mount | grep ${MOUNT_DIR}"
echo "       ls -la ${BACKUP_BASE}/upload-local-backup-*"
echo "       touch ${MOUNT_DIR}/nfs-ha-review-\$(hostname)-\$(date +%Y%m%d-%H%M%S)"
echo "[INFO] If stale file handle or shutdown delay occurs:"
echo "       findmnt --target ${MOUNT_DIR}"
echo "       sudo lsof +f -- ${MOUNT_DIR}"
echo "       sudo systemctl stop tomcat"
echo "       sudo umount ${MOUNT_DIR}"
echo "       sudo mount ${MOUNT_DIR}"
echo "       sudo systemctl start tomcat"

# 운영자가 기억해야 할 마지막 요약:
# - WEB은 NFS1/NFS2 실제 IP가 아니라 NFS VIP만 바라봐야 한다.
# - 이미 다른 source로 mount되어 있으면 자동으로 고치지 말고 중단한다.
# - 로컬 upload 파일은 mount 전에 백업하고, NFS에는 같은 이름을 덮어쓰지 않는다.
# - stale file handle은 NFS failover 후 발생할 수 있으므로 findmnt/lsof/umount/mount 순서로 확인한다.
