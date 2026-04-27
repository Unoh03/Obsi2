#!/bin/bash
sudo apt update
sudo apt install -y bind9 bind9utils bind9-doc

sudo tee /etc/bind/named.conf.options > /dev/null <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

sudo tee /etc/bind/named.conf.local > /dev/null <<EOF
zone "zzaphub.com" {
    type slave;
    masters { 192.168.1.2; };
    file "/var/cache/bind/db.zzaphub.com";
};
EOF

 
sudo tee /etc/bind/db.zzaphub.com > /dev/null <<EOF
\$TTL 300
@       IN      SOA     ns1.zzaphub.com. admin.zzaphub.com. (
                        2026042701 ; Serial
                        300        ; Refresh
                        60         ; Retry
                        604800     ; Expire
                        300 )      ; Negative Cache TTL
;
@       IN      NS      ns1.zzaphub.com.
@       IN      NS      ns2.zzaphub.com.

ns1     IN      A       1.2.1.2
ns2     IN      A       1.2.1.3

@       IN      A       1.2.2.1
www     IN      A       1.2.2.1


EOF

sudo ufw allow 53
sudo named-checkconf
sudo named-checkzone zzaphub.com /etc/bind/db.zzaphub.com
sudo systemctl restart named
sudo systemctl enable named