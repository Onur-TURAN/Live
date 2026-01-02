#!/bin/bash
echo "önce bir update"
sudo apt update -y
sudo apt full-upgrade -y
echo gerekli paketleri indirelim



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

# Hashcat
sudo apt-get install -y hashcat


# Recon-ng
sudo apt-get install -y recon-ng

# Sistemi temizle
sudo apt-get autoremove -y
