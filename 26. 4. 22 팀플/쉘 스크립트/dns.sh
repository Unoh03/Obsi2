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
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
};
EOF


sudo tee /etc/bind/db.example.com > /dev/null <<EOF
\$TTL    604800
@       IN      SOA     ns.example.com. root.example.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns.example.com.
ns      IN      A       2.2.2.2
@       IN      A       3.3.3.3
www     IN      A       3.3.3.3
EOF

sudo ufw allow 53
sudo named-checkconf
sudo named-checkzone example.com /etc/bind/db.example.com
sudo systemctl restart named
sudo systemctl enable named