#!/bin/bash
sudo apt update
sudo apt install -y bind9 bind9utils bind9-doc

sudo tee /etc/bind/named.conf.options > /dev/null <<EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-query { any; };
    listen-on-v6 { any; };
};
EOF

sudo tee /etc/bind/named.conf.local > /dev/null <<EOF
zone "zzaphub.com" {
    type master;
    file "/etc/bind/db.zzaphub.com";
};
EOF

 
sudo tee /etc/bind/db.zzaphub.com > /dev/null <<EOF
\$TTL    604800
@       IN      SOA     ns.zzaphub.com. root.zzaphub.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.zzaphub.com.
ns      IN      A       1.2.1.2
@       IN      A       1.2.2.1
www     IN      A       1.2.2.1
EOF

sudo ufw allow 53
sudo named-checkconf
sudo named-checkzone zzaphub.com /etc/bind/db.zzaphub.com
sudo systemctl restart named
sudo systemctl enable named