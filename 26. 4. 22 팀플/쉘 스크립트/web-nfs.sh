#!/bin/bash
echo "[INFO] NFS 클라이언트 세팅을 시작합니다..."
sudo apt update
sudo apt install -y nfs-common
mkdir -p ~/share_client
sudo mkdir -p /opt/tomcat/tomcat-10/webapps/upload
FSTAB_LINE='192.168.2.5:/share_directory /opt/tomcat/tomcat-10/webapps/upload nfs defaults,_netdev,nofail,soft,timeo=100 0 0'
grep -qxF "$FSTAB_LINE" /etc/fstab || echo "$FSTAB_LINE" | sudo tee -a /etc/fstab
# NFS 서버(192.168.2.5)가 어떤 폴더를 공유(Export)하고 있는지 참고 확인
showmount -e 192.168.2.5 || true
sudo mount -a
sudo systemctl daemon-reload
df -h | grep /opt/tomcat/tomcat-10/webapps/upload
echo "[SUCCESS] NFS 클라이언트 세팅이 완벽하게 끝났습니다!"
