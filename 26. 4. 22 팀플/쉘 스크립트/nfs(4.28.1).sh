#!/bin/bash
set -e

# =====================================================
# Charlie C Zone NFS Server Setup
# - NFS1 primary: 192.168.2.5
# - NFS2 backup: 192.168.2.6
# - Share path: /share_directory
# - Allowed clients: 192.168.2.0/24
#
# Run this script on NFS1 first.
# It can also be run on NFS2 to prepare a manual failover target.
# =====================================================

SHARE_DIR="/share_directory"
EXPORT_NET="192.168.2.0/24"
EXPORT_LINE="${SHARE_DIR} ${EXPORT_NET}(rw,sync,no_subtree_check)"

echo "[INFO] NFS 서버 설정을 시작합니다."
echo "[INFO] Share=${SHARE_DIR}, Allowed=${EXPORT_NET}"

# =====================================================
# 1. 패키지 설치
# =====================================================
echo "[STEP 1/5] nfs-kernel-server를 설치합니다."
sudo apt update
sudo apt install -y nfs-kernel-server

# =====================================================
# 2. 공유 디렉터리 생성
# - 실습 편의를 위해 777 사용
# - 운영 환경에서는 770 + 전용 그룹 권한이 더 안전함
# =====================================================
echo "[STEP 2/5] 공유 디렉터리를 준비합니다."
sudo mkdir -p "$SHARE_DIR"
sudo chown nobody:nogroup "$SHARE_DIR"
sudo chmod 777 "$SHARE_DIR"

# =====================================================
# 3. /etc/exports 등록
# - 같은 줄이 이미 있으면 중복 추가하지 않음
# =====================================================
echo "[STEP 3/5] /etc/exports에 공유 설정을 등록합니다."
grep -qxF "$EXPORT_LINE" /etc/exports || echo "$EXPORT_LINE" | sudo tee -a /etc/exports > /dev/null

# =====================================================
# 4. NFS 서비스 재시작 및 export 반영
# =====================================================
echo "[STEP 4/5] NFS 서비스를 재시작하고 export를 반영합니다."
sudo systemctl restart nfs-kernel-server
sudo exportfs -arv

# =====================================================
# 5. 방화벽 허용 및 확인
# =====================================================
echo "[STEP 5/5] NFS 기본 포트 2049/tcp를 허용합니다."
sudo ufw allow 2049/tcp || true

echo "[SUCCESS] NFS 서버 설정이 완료되었습니다."
echo "[INFO] 확인 명령:"
echo "       sudo exportfs -v"
echo "       systemctl status nfs-kernel-server --no-pager"
echo "       ls -ld ${SHARE_DIR}"
