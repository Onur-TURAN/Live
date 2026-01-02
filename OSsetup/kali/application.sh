#!/bin/bash
echo "önce bir update"
sudo apt update -y
sudo apt full-upgrade -y
echo gerekli paketleri indirelim
sudo apt install picom -y
echo picom indirildi
sudo apt install caja -y
echo caja indirildi
sudo apt install feh -y
echo feh indirildi

echo i3 desktop kullanmak ister misin? 1 evet, 2 hayır
read desktop
if [ $desktop -eq 1 ]; then
	echo i3 indirelim
	sudo apt install i3
	echo config dosyası github üzerinden çekiliyor.
	cd /home/kali/Documents
	git clone https://github.com/Onur-TURAN/Live.git
	cd /home/kali
	echo config dosyasını güncel olanla değiştirelim
	cp /home/kali/Documents/Live/kali/i3config/config /home/kali/.config/i3/config
	echo işlem tamamdır.
elif [ $desktop -eq 2 ]; then
	echo bu işlem atlandı
fi

echo spotify indirmek ister misin? spotify indirmek için 1 hayır için 2 
read spotify
if [ $spotify -eq 1 ]; then
	echo "spotify is downloading"
	curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add -
	echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
	sudo apt update -y && sudo apt install spotify-client -y
elif [ $spotify -eq 2 ]; then
	echo tamam müzik dinleme
fi

# flameshot download
echo ekran görüntüsü almak için flameshot aracını indirmek ister misin? flameshot indirmek için 1 atlamak için 2
read flameshot
if [ $flameshot -eq 1 ]; then
	echo "flameshot is downloading"
	sudo apt install flameshot
elif [ $flameshot -eq 2 ]; then
	echo tamam indirmeyiz
fi

# burada cd komutu için dizin değiştirmede kullanılacak değişken olan kullanıcı ismini alıyoruz.
echo "what is your session username? user:"
read user
# bu if else google-chrome kurmamıza yardımcı olur. eğer Evet cevabı verilirse google chrome kurulur yoksa firefox üzerinden indirilecek site açılır ve kullanıcının google chrome indirdikten sonra devam etmesi beklenir.
echo "google-chrome indirdin mi? Evet için 1 Hayır için 2 cevap"
read answer
if [ $answer -eq 1 ]; then
	echo "tamam o zaman kuruyorum"
	cd /home/$user/Downloads
	sudo dpkg -i google-chrome-stable_current_amd64.deb
	rm google-chrome-stable_current_amd64.deb
elif [ $answer -eq 2 ]; then
	echo "O zaman chrome indirelim"
	firefox https://www.google.com/intl/tr/chrome
	cd /home/$user/Downloads
	sudo dpkg -i google-chrome-stable_current_amd64.deb
	rm google-chrome-stable_current_amd64.deb
fi

# Tor indirip indirmeyeceğini soruluyor Hayır derse bitiyor, Evet derse tor kuruluyor, hayır derse indirilecek siteye firefox aracılığıyla gidiliyor. Ama bir sonraki if else içerisinde işlemler yapılıyor burada sadece indirilip indirilmek istenmediği soruluyor.
echo "google-chrome tamam şimdi tor kuralım mı? Evet için 1 Hayır için 2"
read tor
if [ $tor -eq 2 ]; then
	echo "Ok, skipping Tor installation."
	cd /home/kali
	tordow=3
elif [ $tor -eq 1 ]; then
	echo "Ok, let's get your information. If you have downloaded Tor, press 1. If not, press 2."
	read tordow
fi

# burada tor yükleme işlemi gerçekleştiriliyor.
if [ $tordow -eq 1 ]; then
	echo "dizin değişim işlemi yapılıyor"
	cd /home/$user/Downloads
	ls
	echo "dizindeki tor dosyasının tam adı nedir?"
	read version
	tar xf $version
	cd tor-browser_tr
	./start-tor-browser.desktop
elif [ $tordow -eq 2 ]; then
	echo "e indirelim o zaman"
	firefox https://www.torproject.org/download/
	cd /home/$user/Downloads
	ls
	echo "tor dosyasının isminin tamamı nedir?"
	read surum
	tar xf $surum
	cd tor-browser_tr
	./start-tor-browser.desktop
elif [ $tordow -eq 3 ]; then
	echo done
	cd 
	pwd
	ls
fi


# Kalilinux official repo add.
echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" | sudo tee /etc/apt/sources.list

# repo add after, update the system
sudo apt-get update
sudo apt-get upgrade -y

# Metasploit Framework
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall
./msfinstall

# Exploit Database
sudo apt-get install -y exploitdb

# Veil Framework
git clone https://github.com/Veil-Framework/Veil.git
cd Veil
./config/setup.sh --force --silent
cd ..

# SecLists
sudo apt-get install -y seclists

# OWASP ZAP
sudo apt-get install -y zaproxy

# Nikto
sudo apt-get install -y nikto

# John the Ripper
sudo apt-get install -y john

# Hydra
sudo apt-get install -y hydra

# Nmap
sudo apt-get install -y nmap

# Wireshark
sudo apt-get install -y wireshark

# Aircrack-ng
sudo apt-get install -y aircrack-ng

# Burp Suite
sudo apt-get install -y burpsuite

# SQLMap
sudo apt-get install -y sqlmap

# Hashcat
sudo apt-get install -y hashcat

# Maltego
sudo apt-get install -y maltego

# Social Engineering Toolkit (SET)
sudo apt-get install -y set

# Ettercap
sudo apt-get install -y ettercap-graphical

# OpenVAS
sudo apt-get install -y openvas

# Recon-ng
sudo apt-get install -y recon-ng

# Sistemi temizle
sudo apt-get autoremove -y

# p0f install
sudo apt install -y p0f

#pdf-parser
sudo apt install -y pdf-parser

#dumpzilla
sudo apt install -y dumpzilla

# dff
sudo apt install -y dff

# bulk-extractor
sudo apt install -y bulk-extractor

# autocutsel
sudo apt install -y autocutsel

echo "well done, bye bye"
echo "Do you want to reboot Kali Linux? (Y/N)"
read reboot
if [ $reboot = "Y" ]; then
    sudo reboot
fi