#!/bin/bash
# 구버전 WEB 설치 스크립트.
# 현재 표준 통합본은 web(5.6).sh를 사용한다.
echo "[INFO] Tomcat 웹 서버 세팅을 시작합니다..."

sudo apt update
sudo apt install -y openjdk-17-jdk
# 🌟 버전 변수 선언 (나중에 업데이트할 땐 이 숫자만 바꾸면 됨!)
TOMCAT_VER="10.1.54"
TOMCAT_BASE_URL="https://downloads.apache.org/tomcat/tomcat-10"
TOMCAT_DOWNLOAD_URL="${TOMCAT_BASE_URL}/v${TOMCAT_VER}/bin/apache-tomcat-${TOMCAT_VER}.tar.gz"

# Apache 공식 다운로드 서버에서 Tomcat 다운로드
# 나중에 버전이 바뀌면 TOMCAT_VER만 바꾸면 된다.
wget "${TOMCAT_DOWNLOAD_URL}"

# 🛡️ [보안] 쉘 접속이 불가능한(/bin/false) 톰캣 전용 계정 생성 및 권한 격리
sudo useradd -r -m -U -d /opt/tomcat -s /bin/false tomcat

# 변수를 활용한 압축 해제 및 폴더명 변경
sudo tar -xf "apache-tomcat-${TOMCAT_VER}.tar.gz" -C /opt/tomcat
sudo mv "/opt/tomcat/apache-tomcat-${TOMCAT_VER}" /opt/tomcat/tomcat-10
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
    sudo chown tomcat:tomcat /opt/tomcat/tomcat-10/webapps/boot.war
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
sudo sed -i 's|spring.datasource.password.*|spring.datasource.password=7898|' $PROP_FILE
sudo sed -i 's|spring.datasource.url.*|spring.datasource.url=jdbc:mariadb://1.2.3.1:3306/care|' $PROP_FILE

sudo mkdir --mode=777 /opt/tomcat/tomcat-10/webapps/upload

sudo ufw allow 8080/tcp
sudo systemctl restart tomcat
echo "[SUCCESS] WEB 서버 세팅 및 DB 연동이 완벽하게 끝났습니다!"
