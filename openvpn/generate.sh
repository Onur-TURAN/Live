#!/bin/bash

CLIENT_NAME=$1
SERVER_IP=$2

if [ -z "$CLIENT_NAME" ] || [ -z "$SERVER_IP" ]; then
  echo "Kullanım: ./gen-client.sh clientadi server_ip"
  exit 1
fi

cd ~/easy-rsa

./easyrsa build-client-full $CLIENT_NAME nopass

cat > ~/${CLIENT_NAME}.ovpn <<EOF
client
dev tun
proto udp
remote $SERVER_IP 1194

resolv-retry infinite
nobind

persist-key
persist-tun

remote-cert-tls server
cipher AES-256-GCM
auth SHA256

key-direction 1

<ca>
$(cat ~/easy-rsa/pki/ca.crt)
</ca>

<cert>
$(cat ~/easy-rsa/pki/issued/${CLIENT_NAME}.crt)
</cert>

<key>
$(cat ~/easy-rsa/pki/private/${CLIENT_NAME}.key)
</key>

<tls-auth>
$(cat /etc/openvpn/server/ta.key)
</tls-auth>
EOF

echo "[+] Oluşturuldu: ~/${CLIENT_NAME}.ovpn"