#!/bin/bash
set -euo pipefail

# =====================================================
# WEB NFS HA Client Setup (4.29.1)
# - NFS VIP: 192.168.2.50
# - Remote share: /share_directory
# - Mount point: /opt/tomcat/tomcat-10/webapps/upload
#
# Keep from 4.28.2:
# - WEB mounts only the NFS VIP, not NFS1/NFS2 directly.
# - Existing local upload files are backed up before mount.
# - Backup files are copied to NFS without overwriting existing files.
# - Duplicate or wrong-source mounts are detected.
#
# Not changed here:
# - NFS1/NFS2 data sync is server-side work.
# - Automatic sync is configured by nfs-ha(4.29.1).sh.
# =====================================================

NFS_VIP="${1:-192.168.2.50}"
REMOTE_SHARE="/share_directory"
MOUNT_DIR="/opt/tomcat/tomcat-10/webapps/upload"
BACKUP_BASE="/opt/tomcat"
EXPECTED_SOURCE="${NFS_VIP}:${REMOTE_SHARE}"

# Keep nofail only in fstab so boot is not blocked if NFS is down.
# Do not force vers=4 here; let the client and server negotiate like the known-good script did.
# x-systemd options shorten boot/shutdown waits while keeping NFS writes hard-mounted.
FSTAB_OPTIONS="defaults,_netdev,nofail,hard,timeo=50,retrans=2,x-systemd.automount,x-systemd.idle-timeout=30s,x-systemd.device-timeout=5s,x-systemd.mount-timeout=10s"
RUNTIME_OPTIONS="rw,hard,timeo=50,retrans=2"
FSTAB_LINE="${EXPECTED_SOURCE} ${MOUNT_DIR} nfs ${FSTAB_OPTIONS} 0 0"

echo "[INFO] WEB NFS HA client setup started."
echo "[INFO] Source=${EXPECTED_SOURCE}, Mount=${MOUNT_DIR}"

mount_sources() {
    findmnt -n -o SOURCE --target "$MOUNT_DIR" 2>/dev/null | sed '/^[[:space:]]*$/d' || true
}

mount_source_count() {
    mount_sources | wc -l
}

current_mount_source() {
    mount_sources | head -n 1
}

is_mounted() {
    [ "$(mount_source_count)" -gt 0 ]
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

register_fstab() {
    echo "[INFO] Registering NFS VIP mount in /etc/fstab."
    sudo sed -i "\|[[:space:]]${MOUNT_DIR}[[:space:]]|d" /etc/fstab
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
    sudo systemctl daemon-reload
}

remount_current_mount() {
    echo "[INFO] Remounting current NFS mount with updated runtime options."
    if timeout 20s sudo mount -o "remount,${RUNTIME_OPTIONS}" "$MOUNT_DIR"; then
        echo "[INFO] Remount completed."
    else
        echo "[WARN] Remount failed or timed out. fstab is updated, but runtime options may apply after reboot/remount."
    fi
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
if is_mounted; then
    MOUNT_COUNT="$(mount_source_count)"
    if [ "$MOUNT_COUNT" -gt 1 ]; then
        echo "[ERROR] ${MOUNT_DIR} is mounted multiple times."
        echo "[ERROR] Unmount it until no mount remains, then run this script again:"
        echo "        sudo umount ${MOUNT_DIR}"
        echo "        sudo umount ${MOUNT_DIR}"
        print_mount_debug
        exit 1
    fi

    CURRENT_SOURCE="$(current_mount_source)"

    if is_expected_source "$CURRENT_SOURCE"; then
        echo "[INFO] ${MOUNT_DIR} is already mounted from ${CURRENT_SOURCE}."
        register_fstab
        remount_current_mount
        print_mount_status
        echo "[SUCCESS] WEB NFS HA client setup is already applied and fstab is updated."
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
register_fstab

# =====================================================
# 6. Apply NFS mount directly
# - Do not rely on mount -a for the first mount.
# - Direct mount shows the real NFS error if the mount fails.
# =====================================================
echo "[STEP 6/7] Checking NFS export and applying mount."
showmount -e "$NFS_VIP" || echo "[WARN] showmount failed. Trying direct NFS mount anyway."
if timeout 20s sudo mount -v -t nfs -o "$RUNTIME_OPTIONS" "$EXPECTED_SOURCE" "$MOUNT_DIR"; then
    echo "[INFO] Direct NFS mount command completed."
else
    echo "[ERROR] Direct NFS mount command failed."
    print_mount_debug
    exit 1
fi

if ! is_mounted; then
    echo "[ERROR] ${MOUNT_DIR} is not mounted after direct mount."
    print_mount_debug
    exit 1
fi

MOUNT_COUNT="$(mount_source_count)"
if [ "$MOUNT_COUNT" -gt 1 ]; then
    echo "[ERROR] ${MOUNT_DIR} is mounted multiple times after direct mount."
    echo "[ERROR] Unmount it until no mount remains, then run this script again:"
    echo "        sudo umount ${MOUNT_DIR}"
    echo "        sudo umount ${MOUNT_DIR}"
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
echo "[INFO] If stale file handle or shutdown delay occurs:"
echo "       findmnt --target ${MOUNT_DIR}"
echo "       sudo lsof +f -- ${MOUNT_DIR}"
echo "       sudo systemctl stop tomcat"
echo "       sudo umount ${MOUNT_DIR}"
echo "       sudo mount ${MOUNT_DIR}"
echo "       sudo systemctl start tomcat"
