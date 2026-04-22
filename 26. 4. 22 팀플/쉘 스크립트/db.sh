#!/bin/bash
echo "[INFO] MariaDB 설치 및 세팅을 시작합니다..."

sudo apt update
sudo apt install -y mariadb-server mariadb-client 
sudo systemctl enable --now mariadb

# 1. Here-Doc을 이용한 쿼리 자동 주입 (비밀번호 프롬프트 무시)
sudo mariadb -uroot <<EOF
CREATE DATABASE care;
USE care;

# DB 만들기

ALTER USER 'root'@'localhost' IDENTIFIED BY '123';
CREATE USER 'web'@'34.34.34.3' IDENTIFIED BY '123';
GRANT ALL PRIVILEGES ON care.* TO 'web'@'34.34.34.3';
FLUSH PRIVILEGES;
EOF

# 2. 외부 접속 허용 (bind-address 수정)
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# 3. 재시작 및 완료
sudo ufw allow 3306/tcp
sudo systemctl restart mariadb
echo "[SUCCESS] DB 서버 세팅이 완료되었습니다."