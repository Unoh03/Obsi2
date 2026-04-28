#!/bin/bash
set -e

# =====================================================
# WEB NFS HA Client Setup
# - NFS VIP: 192.168.2.50
# - Mount point: /opt/tomcat/tomcat-10/webapps/upload
#
# WEB1/WEB2 should mount the VIP only.
# Do not mount 192.168.2.5 or 192.168.2.6 directly in HA mode.
#
# Normal:
#   bash 'web-nfs(4.28.2).sh'
#
# Override VIP:
#   bash 'web-nfs(4.28.2).sh' 192.168.2.50
# =====================================================

NFS_VIP="${1:-192.168.2.50}"
REMOTE_SHARE="/share_directory"
MOUNT_DIR="/opt/tomcat/tomcat-10/webapps/upload"
FSTAB_LINE="${NFS_VIP}:${REMOTE_SHARE} ${MOUNT_DIR} nfs defaults,_netdev,nofail,hard,vers=4,timeo=600,retrans=2 0 0"

echo "[INFO] WEB NFS HA 클라이언트 설정을 시작합니다."
echo "[INFO] NFS_VIP=${NFS_VIP}, MOUNT_DIR=${MOUNT_DIR}"

# =====================================================
# 1. 패키지 설치
# =====================================================
echo "[STEP 1/5] nfs-common을 설치합니다."
sudo apt update
sudo apt install -y nfs-common

# =====================================================
# 2. Tomcat upload mount point 생성
# =====================================================
echo "[STEP 2/5] upload mount point를 준비합니다."
sudo mkdir -p "$MOUNT_DIR"

# =====================================================
# 3. 기존 upload NFS mount 설정 정리 후 /etc/fstab 등록
# - HA 모드에서는 NFS1/NFS2 개별 IP가 아니라 VIP만 등록
# =====================================================
echo "[STEP 3/5] /etc/fstab에 NFS VIP mount 설정을 등록합니다."
sudo sed -i "\| ${MOUNT_DIR} nfs |d" /etc/fstab
echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null

# =====================================================
# 4. NFS export 확인 및 mount 적용
# =====================================================
echo "[STEP 4/5] NFS VIP export를 확인하고 mount를 적용합니다."
showmount -e "$NFS_VIP" || true
sudo mount -a
sudo systemctl daemon-reload

# =====================================================
# 5. mount 결과 확인
# =====================================================
echo "[STEP 5/5] mount 결과를 확인합니다."
df -h | grep "$MOUNT_DIR"

echo "[SUCCESS] WEB NFS HA 클라이언트 설정이 완료되었습니다."
echo "[INFO] 확인 명령:"
echo "       df -h | grep ${MOUNT_DIR}"
echo "       mount | grep ${MOUNT_DIR}"
echo "       touch ${MOUNT_DIR}/nfs-ha-test-\$(hostname)"
