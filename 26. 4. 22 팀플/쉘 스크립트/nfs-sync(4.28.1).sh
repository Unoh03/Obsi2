#!/bin/bash
set -e

# =====================================================
# NFS Backup Sync
# - Run this on NFS2.
# - Pulls /share_directory from NFS1 by rsync over SSH.
# - This is a backup/manual failover helper, not active-active storage.
#
# Usage:
#   bash 'nfs-sync(4.28.1).sh'
#   bash 'nfs-sync(4.28.1).sh' 192.168.2.5 nfs1-user
# =====================================================

NFS1="${1:-192.168.2.5}"
REMOTE_USER="${2:-$USER}"
SHARE_DIR="/share_directory"

echo "[INFO] NFS backup sync를 시작합니다."
echo "[INFO] Source=${REMOTE_USER}@${NFS1}:${SHARE_DIR}/"
echo "[INFO] Target=${SHARE_DIR}/"

# =====================================================
# 1. rsync 설치
# =====================================================
echo "[STEP 1/3] rsync와 openssh-client를 설치합니다."
sudo apt update
sudo apt install -y rsync openssh-client

# =====================================================
# 2. NFS2 로컬 공유 디렉터리 준비
# =====================================================
echo "[STEP 2/3] NFS2 로컬 공유 디렉터리를 준비합니다."
sudo mkdir -p "$SHARE_DIR"
sudo chown nobody:nogroup "$SHARE_DIR"
sudo chmod 777 "$SHARE_DIR"

# =====================================================
# 3. NFS1에서 NFS2로 데이터 동기화
# - SSH 비밀번호 또는 SSH key가 필요할 수 있음
# - --delete 옵션 때문에 NFS1에 없는 파일은 NFS2에서도 삭제됨
# =====================================================
echo "[STEP 3/3] rsync 동기화를 실행합니다."
sudo rsync -av --delete "${REMOTE_USER}@${NFS1}:${SHARE_DIR}/" "${SHARE_DIR}/"
sudo chown -R nobody:nogroup "$SHARE_DIR"
sudo chmod -R 777 "$SHARE_DIR"

echo "[SUCCESS] NFS backup sync가 완료되었습니다."
echo "[INFO] 확인 명령:"
echo "       ls -al ${SHARE_DIR}"
