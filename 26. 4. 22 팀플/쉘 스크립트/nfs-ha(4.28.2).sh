#!/bin/bash
set -e

# =====================================================
# Charlie C Zone NFS HA Server Setup
# - NFS1: 192.168.2.5
# - NFS2: 192.168.2.6
# - NFS VIP: 192.168.2.50
# - Share path: /share_directory
# - Allowed clients: 192.168.2.0/24
#
# This script configures service failover with keepalived.
# WEB servers should mount only the VIP, not NFS1/NFS2 directly.
#
# Important:
# - This does not provide block-level data replication.
# - For true no-data-loss HA, use shared storage or DRBD-style replication.
# - Without that, failover can serve stale or missing files on NFS2.
#
# Normal:
#   bash 'nfs-ha(4.28.2).sh'
#
# Manual role override: 
#   IFACE=ens37 bash 'nfs-ha(4.28.2).sh' MASTER
#   IFACE=ens37 bash 'nfs-ha(4.28.2).sh' BACKUP
# =====================================================

NFS1_IP="192.168.2.5"
NFS2_IP="192.168.2.6"
VIP="192.168.2.50"
VRID="50"
AUTH_PASS="nfs-ha"
SHARE_DIR="/share_directory"
EXPORT_NET="192.168.2.0/24"
EXPORT_LINE="${SHARE_DIR} ${EXPORT_NET}(rw,sync,no_subtree_check)"

echo "[INFO] NFS HA 서버 설정을 시작합니다."
echo "[INFO] VIP=${VIP}, NFS1=${NFS1_IP}, NFS2=${NFS2_IP}, Share=${SHARE_DIR}"

# =====================================================
# 1. 역할과 프로젝트망 인터페이스 확인
# - 192.168.2.5는 MASTER, 192.168.2.6은 BACKUP으로 자동 판단
# =====================================================
echo "[STEP 1/7] 인터페이스와 NFS HA 역할을 확인합니다."

ROLE="${1:-}"
PRIORITY="${2:-}"
IFACE="${IFACE:-}"

if [ -z "$IFACE" ]; then
    IFACE="$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.2\./ {print $2; exit}')"
fi

if [ -z "$IFACE" ]; then
    echo "[ERROR] 192.168.2.0/24 주소를 가진 인터페이스를 찾지 못했습니다."
    echo "        예시: IFACE=ens37 bash 'nfs-ha(4.28.2).sh' MASTER"
    exit 1
fi

LOCAL_IP="$(ip -o -4 addr show dev "$IFACE" | awk '{print $4}' | cut -d/ -f1 | grep -E '^192\.168\.2\.(5|6)$' | head -n 1 || true)"

if [ -z "$ROLE" ]; then
    case "$LOCAL_IP" in
        "$NFS1_IP")
            ROLE="MASTER"
            PRIORITY="${PRIORITY:-150}"
            ;;
        "$NFS2_IP")
            ROLE="BACKUP"
            PRIORITY="${PRIORITY:-100}"
            ;;
        *)
            echo "[ERROR] 현재 IP로 NFS 역할을 자동 판단하지 못했습니다."
            echo "        NFS1에서 실행: IFACE=${IFACE} bash 'nfs-ha(4.28.2).sh' MASTER"
            echo "        NFS2에서 실행: IFACE=${IFACE} bash 'nfs-ha(4.28.2).sh' BACKUP"
            exit 1
            ;;
    esac
fi

ROLE="$(echo "$ROLE" | tr '[:lower:]' '[:upper:]')"

case "$ROLE" in
    MASTER)
        PRIORITY="${PRIORITY:-150}"
        ;;
    BACKUP)
        PRIORITY="${PRIORITY:-100}"
        ;;
    *)
        echo "[ERROR] ROLE 값은 MASTER 또는 BACKUP만 사용할 수 있습니다."
        exit 1
        ;;
esac

echo "[INFO] Interface=${IFACE}, Local_IP=${LOCAL_IP:-unknown}, Role=${ROLE}, Priority=${PRIORITY}"

# =====================================================
# 2. 패키지 설치
# =====================================================
echo "[STEP 2/7] nfs-kernel-server와 keepalived를 설치합니다."
sudo apt update
sudo apt install -y nfs-kernel-server keepalived

# =====================================================
# 3. Prepare shared directory
# - Lab mode uses 777 for simple testing.
# - In production, prefer 770 with a dedicated group.
# =====================================================
echo "[STEP 3/7] NFS 공유 디렉터리를 준비합니다."
sudo mkdir -p "$SHARE_DIR"
sudo chown nobody:nogroup "$SHARE_DIR"
sudo chmod 777 "$SHARE_DIR"

# =====================================================
# 4. /etc/exports 등록
# - 같은 줄이 이미 있으면 중복 추가하지 않음
# =====================================================
echo "[STEP 4/7] /etc/exports에 공유 설정을 등록합니다."
grep -qxF "$EXPORT_LINE" /etc/exports || echo "$EXPORT_LINE" | sudo tee -a /etc/exports > /dev/null
sudo exportfs -arv

# =====================================================
# 5. keepalived health check script 작성
# - nfs-kernel-server 상태를 보고 VIP 유지 여부를 판단
# =====================================================
echo "[STEP 5/7] keepalived health check를 작성합니다."
sudo tee /usr/local/bin/check_nfs.sh > /dev/null << 'EOF'
#!/bin/sh
systemctl is-active --quiet nfs-kernel-server
EOF
sudo chmod 755 /usr/local/bin/check_nfs.sh

# =====================================================
# 6. Configure keepalived VIP
# - NFS1/NFS2 must use the same virtual_router_id and auth_pass.
# - If MASTER or NFS service fails, VIP moves to BACKUP.
# =====================================================
echo "[STEP 6/7] keepalived VIP 설정을 작성합니다."
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
    state ${ROLE}
    interface ${IFACE}
    virtual_router_id ${VRID}
    priority ${PRIORITY}
    advert_int 1
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
# 7. 서비스 재시작 및 확인
# =====================================================
echo "[STEP 7/7] NFS와 keepalived를 재시작합니다."
sudo systemctl enable nfs-kernel-server keepalived
sudo systemctl restart nfs-kernel-server
sudo systemctl restart keepalived
sudo ufw allow 2049/tcp || true

# =====================================================
# 8. Smart Polling: keepalived VIP 반영 대기
# - keepalived는 재시작 직후 BACKUP으로 들어갔다가 MASTER로 승격될 수 있음
# - 바로 확인하면 VIP가 아직 안 붙은 것처럼 보일 수 있으므로 잠시 대기
# =====================================================
echo "[INFO] keepalived가 VIP 상태를 결정할 때까지 확인합니다."
WAIT_TIME=0
MAX_WAIT=15
VIP_READY="no"

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    if ip addr show dev "$IFACE" | grep -q "$VIP"; then
        VIP_READY="yes"
        break
    fi

    sleep 1
    WAIT_TIME=$((WAIT_TIME + 1))
    echo "[INFO] VIP ${VIP} 대기 중... (${WAIT_TIME}/${MAX_WAIT}초)"
done

echo "[SUCCESS] NFS HA 서버 설정이 완료되었습니다."
echo "[INFO] Role=${ROLE}, Priority=${PRIORITY}, Interface=${IFACE}, VIP=${VIP}"

if [ "$VIP_READY" = "yes" ]; then
    echo "[INFO] 이 노드가 현재 NFS VIP ${VIP}를 가지고 있습니다."
else
    if [ "$ROLE" = "MASTER" ]; then
        echo "[WARN] MASTER 역할인데도 NFS VIP ${VIP}가 아직 보이지 않습니다."
        echo "[WARN] keepalived 상태와 같은 VRRP 그룹의 다른 NFS 노드를 확인하세요."
    else
        echo "[INFO] 이 노드에는 현재 NFS VIP ${VIP}가 없습니다. BACKUP 노드라면 정상일 수 있습니다."
    fi
fi

echo "[INFO] 확인 명령:"
echo "       ip a | grep ${VIP}"
echo "       sudo exportfs -v"
echo "       systemctl status nfs-kernel-server --no-pager"
echo "       systemctl status keepalived --no-pager"
