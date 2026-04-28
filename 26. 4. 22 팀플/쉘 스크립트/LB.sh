#!/bin/bash
set -e

# =====================================================
# Charlie C Zone Load Balancer Setup
# - nginx: WEB1/WEB2로 HTTP 요청을 round-robin 분산
# - keepalived: LB1/LB2 사이에서 VIP Active-Standby 구성
# - VIP: 192.168.2.10
# - Public NAT: 1.2.2.10 -> 192.168.2.10
# =====================================================

echo "[INFO] Load Balancer 설정을 시작합니다."

# =====================================================
# 1. 기본 변수 설정
# =====================================================
VIP="192.168.2.10"
WEB1="192.168.2.3"
WEB2="192.168.2.4"
VRID="22"
AUTH_PASS="zzaphub"

echo "[STEP 1/6] 기본 IP 정보를 설정했습니다."
echo "[INFO] VIP=${VIP}, WEB1=${WEB1}:8080, WEB2=${WEB2}:8080"

# =====================================================
# 2. 실행 노드 역할과 프로젝트망 인터페이스 확인
# - 인자를 주지 않으면 192.168.2.1은 MASTER, 192.168.2.2는 BACKUP으로 자동 판단
# - 자동 판단이 실패하면 IFACE=ens37 bash LB.sh MASTER 처럼 직접 지정
# =====================================================
ROLE="${1:-}"
PRIORITY="${2:-}"
IFACE="${IFACE:-}"

echo "[STEP 2/6] 인터페이스와 LB 역할을 확인합니다."

if [ -z "$IFACE" ]; then
    IFACE="$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.2\./ {print $2; exit}')"
fi

if [ -z "$IFACE" ]; then
    echo "[ERROR] 192.168.2.0/24 주소를 가진 인터페이스를 찾지 못했습니다."
    echo "        예시: IFACE=ens37 bash LB.sh MASTER"
    exit 1
fi

LOCAL_IP="$(ip -o -4 addr show dev "$IFACE" | awk '{print $4}' | cut -d/ -f1 | grep -E '^192\.168\.2\.(1|2)$' | head -n 1 || true)"

if [ -z "$ROLE" ]; then
    case "$LOCAL_IP" in
        192.168.2.1)
            ROLE="MASTER"
            PRIORITY="${PRIORITY:-150}"
            ;;
        192.168.2.2)
            ROLE="BACKUP"
            PRIORITY="${PRIORITY:-100}"
            ;;
        *)
            echo "[ERROR] 현재 IP로 LB 역할을 자동 판단하지 못했습니다."
            echo "        LB1에서 실행: IFACE=${IFACE} bash LB.sh MASTER"
            echo "        LB2에서 실행: IFACE=${IFACE} bash LB.sh BACKUP"
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
# 3. 패키지 설치
# - nginx: HTTP reverse proxy / load balancer
# - keepalived: VIP failover 담당
# =====================================================
echo "[STEP 3/6] nginx와 keepalived를 설치합니다."
sudo apt update
sudo apt install nginx keepalived -y

# =====================================================
# 4. nginx 로드밸런서 설정
# - 별도 알고리즘을 지정하지 않으므로 기본 round-robin으로 동작
# - 요청을 WEB1, WEB2의 Tomcat 8080 포트로 전달
# =====================================================
echo "[STEP 4/6] nginx upstream 설정을 작성합니다."
sudo tee /etc/nginx/conf.d/load-balancer.conf > /dev/null << EOF
upstream backend_nodes {
    server ${WEB1}:8080;
    server ${WEB2}:8080;
}

server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://backend_nodes;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo rm -f /etc/nginx/sites-enabled/default

# =====================================================
# 5. keepalived VIP 설정
# - check_nginx.sh가 nginx 상태를 확인
# - nginx가 죽으면 이 노드는 FAULT가 되고 VIP가 다른 LB로 이동
# - LB1/LB2의 virtual_router_id, auth_pass는 서로 같아야 함
# =====================================================
echo "[STEP 5/6] keepalived VIP 설정을 작성합니다."
sudo tee /usr/local/bin/check_nginx.sh > /dev/null << 'EOF'
#!/bin/sh
systemctl is-active --quiet nginx
EOF
sudo chmod 755 /usr/local/bin/check_nginx.sh

sudo tee /etc/keepalived/keepalived.conf > /dev/null << EOF
global_defs {
    router_id LB_${ROLE}
    enable_script_security
    script_user root
}

vrrp_script chk_nginx {
    script "/usr/local/bin/check_nginx.sh"
    interval 2
    fall 2
    rise 2
}

vrrp_instance VI_LB {
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
        chk_nginx
    }
}
EOF

# =====================================================
# 6. 설정 검사 및 서비스 시작
# =====================================================
echo "[STEP 6/6] 설정을 검사하고 서비스를 재시작합니다."
sudo nginx -t
sudo systemctl enable nginx keepalived
sudo systemctl restart nginx
sudo systemctl restart keepalived

echo "[SUCCESS] LB 설정이 완료되었습니다."
echo "[INFO] Role=${ROLE}, Priority=${PRIORITY}, Interface=${IFACE}, VIP=${VIP}"

if ip addr show dev "$IFACE" | grep -q "$VIP"; then
    echo "[INFO] 이 노드가 현재 VIP ${VIP}를 가지고 있습니다."
else
    echo "[INFO] 이 노드에는 현재 VIP ${VIP}가 없습니다. BACKUP 노드라면 정상일 수 있습니다."
fi

echo "[INFO] 확인 명령:"
echo "       ip a | grep ${VIP}"
echo "       systemctl status nginx --no-pager"
echo "       systemctl status keepalived --no-pager"
echo "       curl http://${VIP}"
