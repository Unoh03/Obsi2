#!/bin/bash
set -e

# =====================================================
# WEB NFS Client Setup
# - Default NFS server: NFS1 192.168.2.5
# - Manual failover target: NFS2 192.168.2.6
# - Mount point: /opt/tomcat/tomcat-10/webapps/upload
#
# Normal:
#   bash 'web-nfs(4.28.1).sh'
#
# Manual failover to NFS2:
#   bash 'web-nfs(4.28.1).sh' 192.168.2.6
# =====================================================

NFS_SERVER="${1:-192.168.2.5}"
REMOTE_SHARE="/share_directory"
MOUNT_DIR="/opt/tomcat/tomcat-10/webapps/upload"
FSTAB_LINE="${NFS_SERVER}:${REMOTE_SHARE} ${MOUNT_DIR} nfs defaults,_netdev,nofail,soft,timeo=100 0 0"

echo "[INFO] WEB NFS 클라이언트 설정을 시작합니다."
echo "[INFO] NFS_SERVER=${NFS_SERVER}, MOUNT_DIR=${MOUNT_DIR}"

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
# - NFS1에서 NFS2로 수동 전환할 때 같은 mount point 중복을 막음
# =====================================================
echo "[STEP 3/5] /etc/fstab에 NFS mount 설정을 등록합니다."
sudo sed -i "\| ${MOUNT_DIR} nfs |d" /etc/fstab
echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null

# =====================================================
# 4. NFS export 확인 및 mount 적용
# =====================================================
echo "[STEP 4/5] NFS export를 확인하고 mount를 적용합니다."
showmount -e "$NFS_SERVER" || true
sudo mount -a
sudo systemctl daemon-reload

# =====================================================
# 5. mount 결과 확인
# =====================================================
echo "[STEP 5/5] mount 결과를 확인합니다."
df -h | grep "$MOUNT_DIR"

echo "[SUCCESS] WEB NFS 클라이언트 설정이 완료되었습니다."
echo "[INFO] 확인 명령:"
echo "       df -h | grep ${MOUNT_DIR}"
echo "       mount | grep ${MOUNT_DIR}"
echo "       touch ${MOUNT_DIR}/nfs-test-\$(hostname)"
