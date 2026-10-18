#!/bin/bash
set -e

CLIENT_NAME="client1"
PORT=1194
PROTO="udp"

apt update
apt install -y openvpn easy-rsa iptables-persistent curl

# EASY-RSA
make-cadir ~/easy-rsa
cd ~/easy-rsa

./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa gen-dh
./easyrsa build-server-full server nopass
./easyrsa build-client-full $CLIENT_NAME nopass

openvpn --genkey secret ta.key

# OPENVPN DIR
mkdir -p /etc/openvpn/server

cp pki/ca.crt pki/dh.pem \
pki/issued/server.crt pki/private/server.key \
ta.key /etc/openvpn/server/

# CONFIG
cat > /etc/openvpn/server/server.conf <<EOF
port $PORT
proto $PROTO
dev tun

ca ca.crt
cert server.crt
key server.key
dh dh.pem

auth SHA256
cipher AES-256-GCM

tls-auth ta.key 0

server 10.8.0.0 255.255.255.0

push "redirect-gateway def1"
push "dhcp-option DNS 1.1.1.1"

keepalive 10 120

user nobody
group nogroup

persist-key
persist-tun

verb 3
EOF

# IP FORWARD
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# NAT
IFACE=$(ip route | grep default | awk '{print $5}')
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $IFACE -j MASQUERADE
netfilter-persistent save

# START
systemctl enable openvpn-server@server
systemctl restart openvpn-server@server

echo "[+] Server hazır"