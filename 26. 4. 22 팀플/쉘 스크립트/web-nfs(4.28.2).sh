#!/bin/bash
set -e

# =====================================================
# WEB NFS HA Client Setup
# - NFS VIP: 192.168.2.50
# - Remote share: /share_directory
# - Mount point: /opt/tomcat/tomcat-10/webapps/upload
#
# Existing local upload files are preserved before mount:
# - Backup path: /opt/tomcat/upload-local-backup-YYYYmmdd-HHMMSS
# - After NFS mount succeeds, backup files are copied to NFS.
# - Existing NFS files are not overwritten.
# =====================================================

NFS_VIP="${1:-192.168.2.50}"
REMOTE_SHARE="/share_directory"
MOUNT_DIR="/opt/tomcat/tomcat-10/webapps/upload"
BACKUP_BASE="/opt/tomcat"
FSTAB_LINE="${NFS_VIP}:${REMOTE_SHARE} ${MOUNT_DIR} nfs defaults,_netdev,nofail,hard,vers=4,timeo=600,retrans=2 0 0"

echo "[INFO] WEB NFS HA client setup started."
echo "[INFO] NFS_VIP=${NFS_VIP}, MOUNT_DIR=${MOUNT_DIR}"

# =====================================================
# 1. Install NFS client package
# =====================================================
echo "[STEP 1/6] Installing nfs-common."
sudo apt update
sudo apt install -y nfs-common

# =====================================================
# 2. Prepare mount point and detect already-mounted state
# =====================================================
echo "[STEP 2/6] Preparing upload mount point."
sudo mkdir -p "$MOUNT_DIR"

if mountpoint -q "$MOUNT_DIR"; then
    echo "[INFO] ${MOUNT_DIR} is already mounted. Skipping backup and remount."
    echo "[INFO] Current mount status:"
    df -h | grep "$MOUNT_DIR"
    mount | grep "$MOUNT_DIR"
    echo "[SUCCESS] WEB NFS HA client setup is already applied."
    exit 0
fi

# =====================================================
# 3. Backup existing local upload files before NFS mount
# =====================================================
echo "[STEP 3/6] Checking existing local upload files."
BACKUP_DIR=""

if [ -n "$(sudo find "$MOUNT_DIR" -mindepth 1 -print -quit)" ]; then
    BACKUP_DIR="${BACKUP_BASE}/upload-local-backup-$(date +%Y%m%d-%H%M%S)"
    echo "[INFO] Existing local files found. Backing up to ${BACKUP_DIR}."
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp -a "${MOUNT_DIR}/." "$BACKUP_DIR/"
else
    echo "[INFO] No existing local upload files found."
fi

# =====================================================
# 4. Register NFS VIP mount in /etc/fstab
# - HA mode must mount the VIP only, not NFS1/NFS2 directly.
# =====================================================
echo "[STEP 4/6] Registering NFS VIP mount in /etc/fstab."
sudo sed -i "\| ${MOUNT_DIR} nfs |d" /etc/fstab
echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null

# =====================================================
# 5. Apply mount and copy preserved files to NFS
# =====================================================
echo "[STEP 5/6] Checking NFS export and applying mount."
showmount -e "$NFS_VIP" || true
sudo mount -a
sudo systemctl daemon-reload

if ! mountpoint -q "$MOUNT_DIR"; then
    echo "[ERROR] ${MOUNT_DIR} is not mounted after mount -a."
    exit 1
fi

if [ -n "$BACKUP_DIR" ]; then
    echo "[INFO] Copying backup files to NFS without overwriting existing files."
    sudo cp -an "${BACKUP_DIR}/." "$MOUNT_DIR/"
    echo "[INFO] Local backup remains at ${BACKUP_DIR}."
fi

# =====================================================
# 6. Verify mount result
# =====================================================
echo "[STEP 6/6] Verifying mount result."
df -h | grep "$MOUNT_DIR"
mount | grep "$MOUNT_DIR"

echo "[SUCCESS] WEB NFS HA client setup completed."
echo "[INFO] Check commands:"
echo "       df -h | grep ${MOUNT_DIR}"
echo "       mount | grep ${MOUNT_DIR}"
echo "       ls -la ${BACKUP_BASE}/upload-local-backup-*"
echo "       touch ${MOUNT_DIR}/nfs-ha-test-\$(hostname)"
