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
echo "flameshot is downloading"
sudo apt install flameshot

# burada cd komutu için dizin değiştirmede kullanılacak değişken olan kullanıcı ismini alıyoruz.
echo "what is your session username? user:"
read user


# Kalilinux official repo add.
echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" | sudo tee /etc/apt/sources.list

# repo add after, update the system
sudo apt update
sudo apt upgrade -y

# Metasploit Framework
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall
./msfinstall

# Exploit Database
sudo apt install -y exploitdb

# Veil Framework
git clone https://github.com/Veil-Framework/Veil.git
cd Veil
./config/setup.sh --force --silent
cd ..

# SecLists
sudo apt install -y seclists

# OWASP ZAP
sudo apt install -y zaproxy

# Nikto
sudo apt install -y nikto

# John the Ripper
sudo apt install -y john

# Hydra
sudo apt install -y hydra

# Nmap
sudo apt install -y nmap

# Wireshark
sudo apt install -y wireshark

# Aircrack-ng
sudo apt install -y aircrack-ng

# Burp Suite
sudo apt install -y burpsuite

# SQLMap
sudo apt install -y sqlmap

# Hashcat
sudo apt install -y hashcat

# Maltego
sudo apt install -y maltego

# Social Engineering Toolkit (SET)
sudo apt install -y set

# Ettercap
sudo apt install -y ettercap-graphical

# OpenVAS
sudo apt install -y openvas

# Recon-ng
sudo apt install -y recon-ng

# Sistemi temizle
sudo apt autoremove -y

echo "well done, bye bye"
echo "Do you want to reboot Kali Linux? (Y/N)"
read reboot
if [ $reboot = "Y" ]; then
    sudo reboot
fi