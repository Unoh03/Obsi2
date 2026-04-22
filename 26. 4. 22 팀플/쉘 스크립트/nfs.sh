#!/bin/bash
sudo apt update
sudo apt install -y nfs-kernel-server


sudo mkdir -p /share_directory
# 실무에서는 777 대신 755나 770을 주고, 특정 그룹만 접근하게 통제한다. (실습용이므로 일단 777 허용)
sudo chmod 777 /share_directory
sudo chown nobody:nogroup /share_directory

echo "/share_directory 192.168.3.0/24(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports

sudo systemctl restart nfs-kernel-server
sudo exportfs -arv
sudo ufw allow 2049/tcp  # NFSv4의 기본 포트