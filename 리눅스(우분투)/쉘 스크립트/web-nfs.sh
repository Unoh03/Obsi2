#!/bin/bash
echo "[INFO] NFS 클라이언트 세팅을 시작합니다..."
sudo apt update
sudo apt install -y nfs-common
mkdir ~/share_client
echo '192.168.3.4:/share_directory /home/nfs/share_client nfs defaults 0 0' | sudo tee -a /etc/fstab
# NFS 서버(192.168.3.4)가 어떤 폴더를 공유(Export)하고 있는지 확인
showmount -e 192.168.3.4
sudo mount -a
df -h | grep nfs
echo "[SUCCESS] NFS 클라이언트 세팅이 완벽하게 끝났습니다!"