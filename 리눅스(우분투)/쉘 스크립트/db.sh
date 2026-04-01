#!/bin/bash
echo "[INFO] MariaDB 설치 및 세팅을 시작합니다..."

sudo apt update
sudo apt install -y mariadb-server mariadb-client 
sudo systemctl enable --now mariadb

# 1. Here-Doc을 이용한 쿼리 자동 주입 (비밀번호 프롬프트 무시)
sudo mariadb -uroot <<EOF
CREATE DATABASE care;
USE care;

CREATE TABLE member(
id varchar(20), pw varchar(200), username varchar(99),
postcode varchar(5), address varchar(1000), detailaddress varchar(100),
mobile varchar(15), PRIMARY KEY(id)
) DEFAULT CHARSET=UTF8;

CREATE TABLE board(
no int, title varchar(200), content varchar(9999),
id varchar(20), writedate varchar(100), hit int,
filename varchar(1000), PRIMARY KEY(no)
) DEFAULT CHARSET=UTF8;

ALTER USER 'root'@'localhost' IDENTIFIED BY '123';
CREATE USER 'web'@'192.168.4.%' IDENTIFIED BY '123';
GRANT ALL PRIVILEGES ON care.* TO 'web'@'192.168.4.%';
FLUSH PRIVILEGES;
EOF

# 2. 외부 접속 허용 (bind-address 수정)
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# 3. 재시작 및 완료
sudo systemctl restart mariadb
echo "[SUCCESS] DB 서버 세팅이 완료되었습니다."