#!/bin/bash
set -euo pipefail

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
EXPECTED_SOURCE="${NFS_VIP}:${REMOTE_SHARE}"

# Keep nofail only in fstab so boot is not blocked if NFS is down.
# Do not force vers=4 here; let the client and server negotiate like the known-good script did.
FSTAB_OPTIONS="defaults,_netdev,nofail,soft,timeo=100"
RUNTIME_OPTIONS="rw,soft,timeo=100"
FSTAB_LINE="${EXPECTED_SOURCE} ${MOUNT_DIR} nfs ${FSTAB_OPTIONS} 0 0"

echo "[INFO] WEB NFS HA client setup started."
echo "[INFO] Source=${EXPECTED_SOURCE}, Mount=${MOUNT_DIR}"

current_mount_source() {
    findmnt -n -o SOURCE --target "$MOUNT_DIR" 2>/dev/null || true
}

is_expected_source() {
    [ "$1" = "$EXPECTED_SOURCE" ] || [ "$1" = "$EXPECTED_SOURCE/" ]
}

print_mount_status() {
    echo "[INFO] Mount status:"
    findmnt --target "$MOUNT_DIR" || true
    df -h | grep "$MOUNT_DIR" || true
    mount | grep "$MOUNT_DIR" || true
}

print_mount_debug() {
    echo "[DEBUG] fstab entries for this mount point:"
    grep -n "$MOUNT_DIR" /etc/fstab || true
    echo "[DEBUG] findmnt:"
    findmnt --target "$MOUNT_DIR" || true
    echo "[DEBUG] mount output:"
    mount | grep -E "$NFS_VIP|$REMOTE_SHARE|$MOUNT_DIR" || true
    echo "[DEBUG] /proc/mounts:"
    grep -E "$NFS_VIP|$REMOTE_SHARE|$MOUNT_DIR" /proc/mounts || true
}

# =====================================================
# 1. Install NFS client package
# =====================================================
echo "[STEP 1/7] Installing nfs-common."
sudo apt update
sudo apt install -y nfs-common

# =====================================================
# 2. Prepare mount point
# =====================================================
echo "[STEP 2/7] Preparing upload mount point."
sudo mkdir -p "$MOUNT_DIR"

# =====================================================
# 3. Stop if the mount point is already mounted incorrectly
# =====================================================
echo "[STEP 3/7] Checking current mount state."
if mountpoint -q "$MOUNT_DIR"; then
    CURRENT_SOURCE="$(current_mount_source)"

    if is_expected_source "$CURRENT_SOURCE"; then
        echo "[INFO] ${MOUNT_DIR} is already mounted from ${CURRENT_SOURCE}."
        print_mount_status
        echo "[SUCCESS] WEB NFS HA client setup is already applied."
        exit 0
    fi

    echo "[ERROR] ${MOUNT_DIR} is already mounted from an unexpected source."
    echo "[ERROR] Current source: ${CURRENT_SOURCE:-unknown}"
    echo "[ERROR] Expected source: ${EXPECTED_SOURCE}"
    echo "[ERROR] Unmount it manually after checking data, then run this script again."
    exit 1
fi

# =====================================================
# 4. Backup existing local upload files before NFS mount
# =====================================================
echo "[STEP 4/7] Checking existing local upload files."
BACKUP_DIR=""

if sudo find "$MOUNT_DIR" -mindepth 1 -print -quit | grep -q .; then
    BACKUP_DIR="${BACKUP_BASE}/upload-local-backup-$(date +%Y%m%d-%H%M%S)"
    echo "[INFO] Existing local files found. Backing up to ${BACKUP_DIR}."
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp -a "${MOUNT_DIR}/." "$BACKUP_DIR/"
else
    echo "[INFO] No existing local upload files found."
fi

# =====================================================
# 5. Register NFS VIP mount in /etc/fstab
# - Remove any previous mount rule for this mount point.
# - HA mode must mount the VIP only, not NFS1/NFS2 directly.
# =====================================================
echo "[STEP 5/7] Registering NFS VIP mount in /etc/fstab."
sudo sed -i "\|[[:space:]]${MOUNT_DIR}[[:space:]]|d" /etc/fstab
echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
sudo systemctl daemon-reload

# =====================================================
# 6. Apply NFS mount directly
# - Do not rely on mount -a for the first mount.
# - Direct mount shows the real NFS error if the mount fails.
# =====================================================
echo "[STEP 6/7] Checking NFS export and applying mount."
showmount -e "$NFS_VIP" || echo "[WARN] showmount failed. Trying direct NFS mount anyway."
if sudo mount -v -t nfs -o "$RUNTIME_OPTIONS" "$EXPECTED_SOURCE" "$MOUNT_DIR"; then
    echo "[INFO] Direct NFS mount command completed."
else
    echo "[ERROR] Direct NFS mount command failed."
    print_mount_debug
    exit 1
fi

if ! mountpoint -q "$MOUNT_DIR"; then
    echo "[ERROR] ${MOUNT_DIR} is not mounted after direct mount."
    print_mount_debug
    exit 1
fi

CURRENT_SOURCE="$(current_mount_source)"
if ! is_expected_source "$CURRENT_SOURCE"; then
    echo "[ERROR] ${MOUNT_DIR} mounted from unexpected source after mount."
    echo "[ERROR] Current source: ${CURRENT_SOURCE:-unknown}"
    echo "[ERROR] Expected source: ${EXPECTED_SOURCE}"
    print_mount_debug
    exit 1
fi

if [ -n "$BACKUP_DIR" ]; then
    echo "[INFO] Copying backup files to NFS without overwriting existing files or preserving ownership."
    sudo cp -rn "${BACKUP_DIR}/." "$MOUNT_DIR/"
    echo "[INFO] Local backup remains at ${BACKUP_DIR}."
fi

# =====================================================
# 7. Verify mount result
# =====================================================
echo "[STEP 7/7] Verifying mount result."
print_mount_status

echo "[SUCCESS] WEB NFS HA client setup completed."
echo "[INFO] Check commands:"
echo "       df -h | grep ${MOUNT_DIR}"
echo "       mount | grep ${MOUNT_DIR}"
echo "       ls -la ${BACKUP_BASE}/upload-local-backup-*"
echo "       touch ${MOUNT_DIR}/nfs-ha-test-\$(hostname)"
