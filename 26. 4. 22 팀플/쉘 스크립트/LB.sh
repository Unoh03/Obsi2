#!/bin/bash
set -e

VIP="192.168.2.10"
WEB1="192.168.2.3"
WEB2="192.168.2.4"
VRID="22"
AUTH_PASS="zzaphub"

echo "[INFO] Configure nginx load balancer and keepalived VIP ${VIP}"

ROLE="${1:-}"
PRIORITY="${2:-}"
IFACE="${IFACE:-}"

if [ -z "$IFACE" ]; then
    IFACE="$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.2\./ {print $2; exit}')"
fi

if [ -z "$IFACE" ]; then
    echo "[ERROR] Cannot find an interface with a 192.168.2.0/24 address."
    echo "        Example: IFACE=ens37 ./LB.sh MASTER"
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
            echo "[ERROR] Cannot auto-detect LB role from interface ${IFACE}."
            echo "        Run on LB1: ./LB.sh MASTER"
            echo "        Run on LB2: ./LB.sh BACKUP"
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
        echo "[ERROR] ROLE must be MASTER or BACKUP."
        exit 1
        ;;
esac

sudo apt update
sudo apt install nginx keepalived -y

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

sudo nginx -t
sudo systemctl enable nginx keepalived
sudo systemctl restart nginx
sudo systemctl restart keepalived

echo "[INFO] LB role=${ROLE}, priority=${PRIORITY}, interface=${IFACE}, VIP=${VIP}"
ip addr show dev "$IFACE" | grep "$VIP" || true
