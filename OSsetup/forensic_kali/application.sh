#!/bin/bash
echo "First, let's update the system"
sudo apt update -y
sudo apt full-upgrade -y
echo "Now let's install required packages"

# Add Kali Linux official repo
echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" | sudo tee /etc/apt/sources.list

# Update system after adding repo
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

# p0f install
sudo apt install -y p0f

# pdf-parser
sudo apt install -y pdf-parser

# dumpzilla
sudo apt install -y dumpzilla

# dff
sudo apt install -y dff

# bulk-extractor
sudo apt install -y bulk-extractor

# autocutsel
sudo apt install -y autocutsel

# Clean up the system
sudo apt-get autoremove -y
sudo apt-get autoremove -y

echo "All done, goodbye"
echo "Do you want to reboot Kali Linux? (Y/N)"
read reboot
if [ $reboot = "Y" ]; then
    sudo reboot
fi
