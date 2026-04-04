# WEB 서버 스크립트 파일
```bash
#!/bin/bash
echo "[INFO] Tomcat 웹 서버 세팅을 시작합니다..."

sudo apt update
sudo apt install -y openjdk-17-jdk
wget http://mirror.apache-kr.org/apache/tomcat/tomcat-10/v10.1.53/bin/apache-tomcat-10.1.53.tar.gz

sudo useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat
sudo tar -xf apache-tomcat-10.1.53.tar.gz -C /opt/tomcat
sudo mv /opt/tomcat/apache-tomcat-10.1.53 /opt/tomcat/tomcat-10
sudo chown -RH tomcat: /opt/tomcat/tomcat-10

# 1. tomcat.service 파일을 스크립트 내부에서 직접 생성 (tee 명령어 활용)
sudo tee /etc/systemd/system/tomcat.service > /dev/null <<EOF
[Unit]
Description=Tomcat 10 servlet container
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/"
ExecStart=/opt/tomcat/tomcat-10/bin/startup.sh
ExecStop=/opt/tomcat/tomcat-10/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now tomcat

# 2. war 파일 이동 (boot.war 파일이 스크립트와 같은 폴더에 있다고 가정)
if [ -f "boot.war" ]; then
    sudo mv boot.war /opt/tomcat/tomcat-10/webapps/
    echo "[INFO] boot.war 배포 완료. Tomcat이 압축을 해제할 때까지 대기합니다..."
else
    echo "[ERROR] boot.war 파일이 없습니다! 스크립트를 중단합니다."
    exit 1
fi

# 3. Smart Polling: 파일이 생성될 때까지 대기 (최대 30초)
PROP_FILE="/opt/tomcat/tomcat-10/webapps/boot/WEB-INF/classes/application.properties"
WAIT_TIME=0

# sudo test -f 로 권한 문제 우회! 파일이 없을(! ) 동안 계속 루프를 돈다.
while ! sudo test -f "$PROP_FILE"; do
    sleep 1
    WAIT_TIME=$((WAIT_TIME + 1))
    echo "압축 해제 대기 중... (${WAIT_TIME}초 경과)"
    
    if [ $WAIT_TIME -ge 30 ]; then
        echo "[ERROR] 30초가 지났지만 파일이 생성되지 않았습니다. 수동 확인 요망!"
        exit 1
    fi
done

# 4. application.properties 자동 수정 및 재시작
echo "[SUCCESS] application.properties 파일 발견! 설정을 변경합니다."
sudo sed -i 's|spring.datasource.username.*|spring.datasource.username=web|' $PROP_FILE
sudo sed -i 's|spring.datasource.password.*|spring.datasource.password=123|' $PROP_FILE
sudo sed -i 's|spring.datasource.url.*|spring.datasource.url=jdbc:mariadb://192.168.42.135:3306/care|' $PROP_FILE

sudo systemctl restart tomcat
echo "[SUCCESS] WEB 서버 세팅 및 DB 연동이 완벽하게 끝났습니다!"
```
[[web.sh]]
[[boot.war]]
# DB 서버 스크립트 파일
```bash
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
CREATE USER 'web'@'192.168.42.%' IDENTIFIED BY '123';
GRANT ALL PRIVILEGES ON care.* TO 'web'@'192.168.42.%';
FLUSH PRIVILEGES;
EOF

# 2. 외부 접속 허용 (bind-address 수정)
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# 3. 재시작 및 완료
sudo systemctl restart mariadb
echo "[SUCCESS] DB 서버 세팅이 완료되었습니다."
```
[[db.sh]]