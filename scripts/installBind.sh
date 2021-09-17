#! /bin/bash
apt update
apt install -y bind9

cat <<EOF > /etc/bind/named.conf.options
options {
        directory "/var/cache/bind";

        // Default forwarder is Azure DNS
        forwarders {
                168.63.129.16;
        };

        listen-on port 53 { any; };
        allow-query { any; };
        recursion yes;

        auth-nxdomain no;    # conform to RFC1035
};
EOF

systemctl restart bind9