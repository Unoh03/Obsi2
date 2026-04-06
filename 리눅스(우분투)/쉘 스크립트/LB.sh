#!/bin/bash
echo "[INFO] Load-Balancer 설치 및 세팅을 시작합니다..."
sudo apt update
sudo apt install nginx -y

sudo tee /etc/nginx/conf.d/load-balancer.conf > /dev/null << EOF

upstream backend_nodes {
    server 192.168.3.1:8080;
    server 192.168.3.2:8080;
}
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://backend_nodes;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Nginx 문법 검사 (오타 방지)
sudo nginx -t
# Nginx 설정 적용 및 재시작
sudo systemctl restart nginx