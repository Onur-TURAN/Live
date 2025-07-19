#!/bin/bash
# Bu script rasp4 ve rasp5 üzerinde çalıştırılmalıdır

RASPGATEWAY="192.168.1.32"  # raspw2 IP'si

echo "📡 Mevcut route kaldırılıyor..."
sudo ip route del default || echo "🔹 Zaten yok"

echo "📍 Yeni default gateway olarak raspw2 atanıyor ($RASPGATEWAY)..."
sudo ip route add default via $RASPGATEWAY dev wlan0

echo "🛠️ DNS ayarlanıyor..."
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null

echo "✅ Default route başarıyla değiştirildi. Yeni çıkış noktası: $RASPGATEWAY"

echo -e "\n🌍 Dış IP (VPN'e geçiş test):"
curl -s ifconfig.io || echo "⚠️ Bağlantı yok, NAT aktif mi kontrol et (raspw2)"

