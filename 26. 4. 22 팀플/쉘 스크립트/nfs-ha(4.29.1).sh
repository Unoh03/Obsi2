#!/bin/bash
set -euo pipefail

# =====================================================
# Charlie C Zone NFS HA Server Setup (4.29.1)
# - NFS1: 192.168.2.5
# - NFS2: 192.168.2.6
# - NFS VIP: 192.168.2.50
# - Share path: /share_directory
# - Allowed clients: 192.168.2.0/24
#
# Keep from 4.28.2:
# - NFS export for 192.168.2.0/24
# - keepalived VIP failover
# - NFS service health check
# - UFW rules for NFS and VRRP
#
# Changed in 4.29.1:
# - Add rsync-based automatic sync.
# - Only the node that currently owns the VIP syncs to the peer.
# - Sync runs every minute through cron.
# - Delete mirroring is disabled by default to avoid deleting files from
#   the recovering node after failover.
# - If delete mirroring is intentionally required, set
#   SYNC_DELETE_OPT="--delete-delay" when running this script.
#
# Important:
# - Convenience-first mode creates the local sync user if it is missing.
# - Lab mode keeps the broad 192.168.2.0/24 export and chmod 777 share.
# - This is not block-level replication.
# - This does not solve split-brain.
# - SSH key login is required for unattended cron sync.
# - keepalived uses nopreempt, so automatic failback is intentionally disabled.
#
# Normal:
#   bash 'nfs-ha(4.29.1).sh'
#
# Manual role override:
#   IFACE=ens37 bash 'nfs-ha(4.29.1).sh' MASTER
#   IFACE=ens37 bash 'nfs-ha(4.29.1).sh' BACKUP
# =====================================================

NFS1_IP="192.168.2.5"
NFS2_IP="192.168.2.6"
NFS1_USER="${NFS1_USER:-nfs1}"
NFS2_USER="${NFS2_USER:-nfs2}"
VIP="192.168.2.50"
VRID="50"
AUTH_PASS="nfs-ha"
SHARE_DIR="/share_directory"
EXPORT_NET="192.168.2.0/24"
EXPORT_LINE="${SHARE_DIR} ${EXPORT_NET}(rw,sync,no_subtree_check)"

SYNC_SCRIPT="/usr/local/bin/nfs_ha_sync.sh"
SYNC_LOG="/var/log/nfs-ha-sync.log"
CRON_FILE="/etc/cron.d/nfs-ha-sync"
LOCK_FILE="/tmp/nfs-ha-sync.lock"
DELETE_OPT="${SYNC_DELETE_OPT:-}"
DISK_WARN_PERCENT="${DISK_WARN_PERCENT:-85}"

echo "[INFO] NFS HA server setup started."
echo "[INFO] VIP=${VIP}, NFS1=${NFS1_IP}, NFS2=${NFS2_IP}, Share=${SHARE_DIR}"

# =====================================================
# 1. Detect interface, local IP, role, and sync peer
# =====================================================
echo "[STEP 1/9] Checking interface, local role, and sync peer."

ROLE="${1:-}"
PRIORITY="${2:-}"
IFACE="${IFACE:-}"

if [ -z "$IFACE" ]; then
    IFACE="$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.2\./ {print $2; exit}')"
fi

if [ -z "$IFACE" ]; then
    echo "[ERROR] Could not find an interface with a 192.168.2.0/24 address."
    echo "        Example: IFACE=ens37 bash 'nfs-ha(4.29.1).sh' MASTER"
    exit 1
fi

LOCAL_IP="$(ip -o -4 addr show dev "$IFACE" | awk '{print $4}' | cut -d/ -f1 | grep -E '^192\.168\.2\.(5|6)$' | head -n 1 || true)"

case "$LOCAL_IP" in
    "$NFS1_IP")
        DEFAULT_ROLE="MASTER"
        DEFAULT_PRIORITY="150"
        LOCAL_SYNC_USER="$NFS1_USER"
        PEER_IP="$NFS2_IP"
        PEER_SYNC_USER="$NFS2_USER"
        ;;
    "$NFS2_IP")
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

ROLE="${ROLE:-$DEFAULT_ROLE}"
PRIORITY="${PRIORITY:-$DEFAULT_PRIORITY}"
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
    if id "$LOCAL_SYNC_USER" >/dev/null 2>&1; then
        return
    fi

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
# 2. Install required packages
# =====================================================
echo "[STEP 2/9] Installing NFS, keepalived, rsync, SSH, and cron packages."
sudo apt update
sudo apt install -y nfs-kernel-server keepalived rsync openssh-client openssh-server cron

sudo systemctl enable ssh cron || true
sudo systemctl restart ssh || true

# =====================================================
# 3. Prepare shared directory
# =====================================================
echo "[STEP 3/9] Preparing NFS shared directory."
sudo mkdir -p "$SHARE_DIR"
sudo chown nobody:nogroup "$SHARE_DIR"
sudo chmod 777 "$SHARE_DIR"

# =====================================================
# 4. Register NFS export
# =====================================================
echo "[STEP 4/9] Registering NFS export."
sudo sed -i "\|^${SHARE_DIR}[[:space:]]|d" /etc/exports
echo "$EXPORT_LINE" | sudo tee -a /etc/exports > /dev/null
sudo exportfs -arv

# =====================================================
# 5. Create keepalived health check script
# =====================================================
echo "[STEP 5/9] Creating keepalived health check script."
sudo tee /usr/local/bin/check_nfs.sh > /dev/null << 'EOF'
#!/bin/sh
SHARE_DIR="/share_directory"

systemctl is-active --quiet nfs-kernel-server
test -d "$SHARE_DIR" || exit 1
test -w "$SHARE_DIR" || exit 1
touch "$SHARE_DIR/.nfs-healthcheck" || exit 1
rm -f "$SHARE_DIR/.nfs-healthcheck" || exit 1
exportfs -v | awk -v dir="$SHARE_DIR" '$1 == dir {found=1} END {exit !found}' || exit 1
EOF
sudo chmod 755 /usr/local/bin/check_nfs.sh

# =====================================================
# 6. Create automatic sync script
# - Run by cron as the local NFS user.
# - Does nothing unless this node owns the VIP.
# - Requires SSH key login to the peer user.
# =====================================================
echo "[STEP 6/9] Creating NFS sync script."

LOCAL_HOME="$(getent passwd "$LOCAL_SYNC_USER" | cut -d: -f6)"
sudo -u "$LOCAL_SYNC_USER" mkdir -p "${LOCAL_HOME}/.ssh"
sudo chmod 700 "${LOCAL_HOME}/.ssh"

if [ ! -f "${LOCAL_HOME}/.ssh/id_ed25519" ]; then
    echo "[INFO] Creating SSH key for ${LOCAL_SYNC_USER}."
    sudo -u "$LOCAL_SYNC_USER" ssh-keygen -t ed25519 -N "" -f "${LOCAL_HOME}/.ssh/id_ed25519"
fi

sudo touch "$SYNC_LOG"
sudo chmod 666 "$SYNC_LOG"

sudo tee "$SYNC_SCRIPT" > /dev/null << EOF
#!/bin/bash
set -u

VIP="${VIP}"
IFACE="${IFACE}"
SHARE_DIR="${SHARE_DIR}"
PEER="${PEER_SYNC_USER}@${PEER_IP}"
SYNC_LOG="${SYNC_LOG}"
LOCK_FILE="${LOCK_FILE}"
DELETE_OPT="${DELETE_OPT}"

log() {
    echo "\$(date -Is) \$*" >> "\$SYNC_LOG"
}

if ! ip addr show dev "\$IFACE" | grep -q "\$VIP"; then
    exit 0
fi

if ! systemctl is-active --quiet nfs-kernel-server; then
    log "skip: nfs-kernel-server is not active"
    exit 0
fi

if ! ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "\$PEER" "test -d \"\$SHARE_DIR\""; then
    log "skip: SSH key login or remote share is not ready for \$PEER:\$SHARE_DIR"
    exit 0
fi

if ! flock -n "\$LOCK_FILE" rsync -rltv \$DELETE_OPT --no-owner --no-group --no-perms --omit-dir-times \\
    "\${SHARE_DIR}/" "\${PEER}:\${SHARE_DIR}/" >> "\$SYNC_LOG" 2>&1; then
    log "warn: sync failed or previous sync is still running"
fi
EOF

sudo chmod 755 "$SYNC_SCRIPT"

sync_ready() {
    sudo -u "$LOCAL_SYNC_USER" ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 \
        "${PEER_SYNC_USER}@${PEER_IP}" "test -d '${SHARE_DIR}' -a -w '${SHARE_DIR}'"
}

print_disk_status() {
    DISK_USAGE="$(df -P "$SHARE_DIR" 2>/dev/null | awk 'NR == 2 {gsub("%", "", $5); print $5}' || true)"
    echo "[INFO] Disk usage for ${SHARE_DIR}:"
    df -h "$SHARE_DIR" || true

    if [ -n "$DISK_USAGE" ] && [ "$DISK_USAGE" -ge "$DISK_WARN_PERCENT" ]; then
        echo "[WARN] ${SHARE_DIR} filesystem usage is ${DISK_USAGE}%."
        echo "[WARN] Upload and rsync can fail when this filesystem becomes full."
    fi
}

print_ufw_status() {
    echo "[INFO] UFW status relevant to NFS/VRRP/SSH:"
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw status verbose || true
    else
        echo "[INFO] ufw command not found."
    fi
}

print_sync_log_status() {
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
# 7. Configure cron automation
# =====================================================
echo "[STEP 7/9] Registering cron job for automatic sync."
sudo tee "$CRON_FILE" > /dev/null << EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
* * * * * ${LOCAL_SYNC_USER} ${SYNC_SCRIPT}
EOF
sudo chmod 644 "$CRON_FILE"
sudo systemctl restart cron || true

# =====================================================
# 8. Configure keepalived VIP
# =====================================================
echo "[STEP 8/9] Writing keepalived configuration."
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
# 9. Restart services and show verification commands
# =====================================================
echo "[STEP 9/9] Restarting NFS, keepalived, and cron."
sudo systemctl enable nfs-kernel-server keepalived cron
sudo systemctl restart nfs-kernel-server
sudo systemctl restart keepalived
sudo systemctl restart cron || true
sudo ufw allow 2049/tcp || true
sudo ufw allow 22/tcp || true
sudo ufw allow in on "$IFACE" from "$EXPORT_NET" to 224.0.0.18 comment 'keepalived multicast' || true
print_ufw_status

echo "[INFO] Waiting for keepalived to settle."
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
    echo "[INFO] This node currently owns NFS VIP ${VIP}."
    if sync_ready; then
        echo "[INFO] Automatic sync SSH key login is ready."
        echo "[INFO] Running one immediate sync attempt."
        sudo -u "$LOCAL_SYNC_USER" "$SYNC_SCRIPT" || true
    else
        echo "[WARN] Automatic sync is NOT ready."
        echo "[WARN] Run this on the current node, then retry manual sync:"
        echo "       sudo -u ${LOCAL_SYNC_USER} ssh-copy-id ${PEER_SYNC_USER}@${PEER_IP}"
    fi
else
    echo "[INFO] This node does not currently own NFS VIP ${VIP}. Sync cron will stay idle here."
    if sync_ready; then
        echo "[INFO] Automatic sync SSH key login is ready for future VIP ownership."
    else
        echo "[WARN] Automatic sync is NOT ready for future VIP ownership."
        echo "[WARN] Run this on this node:"
        echo "       sudo -u ${LOCAL_SYNC_USER} ssh-copy-id ${PEER_SYNC_USER}@${PEER_IP}"
    fi
fi

print_disk_status
print_sync_log_status

echo "[SUCCESS] NFS HA server setup completed."
echo "[INFO] keepalived uses nopreempt. If this node recovers after failover, it will not automatically steal VIP back."
echo "[INFO] SSH key setup required for unattended sync:"
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
