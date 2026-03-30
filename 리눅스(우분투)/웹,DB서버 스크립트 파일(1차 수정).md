# DB 서버 스크립트 파일
```bash
#!/bin/bash

sudo apt update
sudo apt install -y mariadb-server mariadb-client 
sudo systemctl restart mariadb
sudo systemctl status mariadb
sudo systemctl enable mariadb

sudo mariadb -uroot -p
#Enter password: 비번 안쳐도 됨 


CREATE DATABASE care; <<EOF
USE care;

CREATE TABLE member(
id varchar(20),
pw varchar(200),
username varchar(99),
postcode varchar(5),
address varchar(1000),
detailaddress varchar(100),
mobile varchar(15),
PRIMARY KEY(id)
)DEFAULT CHARSET=UTF8;

CREATE TABLE board(
no int,
title varchar(200),
content varchar(9999),
id varchar(20),
writedate varchar(100),
hit int,
filename varchar(1000),
PRIMARY KEY(no)
)DEFAULT CHARSET=UTF8;


ALTER USER 'root'@'localhost' IDENTIFIED BY '123';
CREATE USER 'web'@'192.168.42.%' IDENTIFIED BY '123';
GRANT ALL PRIVILEGES ON care.* TO 'web'@'192.168.42.%';
FLUSH PRIVILEGES;
exit
EOF


ss -tnl
#State        Recv-Q       Send-Q             Local Address:Port              Peer # Address:Port      Process      
# LISTEN       0            80                     127.0.0.1:3306                  # 0.0.0.0:*                      
#아직 뤂백 IP만 허용 중.                
sudo lsof -i :3306
#COMMAND   PID  USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
#mariadbd 2884 mysql   22u  IPv4  25902      0t0  TCP localhost:mysql (LISTEN)
#마찬가지로 로컬 호스트임.


sudo find / -name "50-server*" 2>/dev/null
# /etc/mysql/mariadb.conf.d/50-server.cnf

# 자동화 코드 (sed 사용):
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

sudo systemctl restart mariadb

sudo lsof -i :3306
#COMMAND   PID  USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
#mariadbd 4802 mysql   25u  IPv4  93986      0t0  TCP *:mysql (LISTEN)
#이제 로컬호스트가 아님.
ss -tnl
#State        Recv-Q       Send-Q             Local Address:Port              Peer Address:Port      Process         
#LISTEN       0            80                       0.0.0.0:3306                   0.0.0.0:*   
#마찬가지로 모든 IP 허용 중.              
```
# WEB 서버 스크립트 파일
```bash
sudo apt install -y openjdk-17-jdk

wget http://mirror.apache-kr.org/apache/tomcat/tomcat-10/v10.1.53/bin/apache-tomcat-10.1.53.tar.gz

sudo useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat

sudo tar -xf apache-tomcat-10.1.53.tar.gz -C /opt/tomcat

sudo mv /opt/tomcat/apache-tomcat-10.1.53 /opt/tomcat/tomcat-10

sudo chown -RH tomcat: /opt/tomcat/tomcat-10

sudo mv tomcat.service /etc/systemd/system/tomcat.service

sudo systemctl daemon-reload
sudo systemctl restart tomcat
sudo systemctl enable tomcat

sudo mv boot.war /opt/tomcat/tomcat-10/webapps/

# 브라우저에서 접속하여 확인: http://192.168.10.129:8080/boot/

# [DB 서버 설정 후 이어서 설정]
#!/bin/bash

 sudo find / -name "applica*.pro*" 2> /dev/null/opt/tomcat/tomcat-10/webapps/boot/WEB-INF/classes/application.properties

sudo sed -i 'spring.datasource.username.*/spring.datasource.username = web/' /opt/tomcat/tomcat-10/webapps/boot/WEB-INF/classes/application.properties
sudo sed -i 'spring.datasource.password.*/spring.datasource.password = 123/' /opt/tomcat/tomcat-10/webapps/boot/WEB-INF/classes/application.properties
sudo sed -i 'spring.datasource.url.*/spring.datasource.url = jdbc:mariadb://192.168.42.131:3306/care/' /opt/tomcat/tomcat-10/webapps/boot/WEB-INF/classes/application.properties
# spring.datasource.username=web # 디비에서 만든 계정 아이디로 수정
# spring.datasource.password=123 # 디비에서 만든 계정의 비번로 수정
# spring.datasource.url=jdbc:mariadb://192.168.42.131:3306/care # 디비서버 아이피주소로 수정

sudo systemctl restart tomcat
```