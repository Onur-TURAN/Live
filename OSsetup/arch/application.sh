#!/bin/bash

echo "hello there"
echo "let's try check your net"
ping google.com -c 6
echo "if any packet's havn't loss you write 1, you write 0"
read A
if [ $A -eq 1 ];
then
	echo "update"
	sudo pacman -Syyu
	echo "i3"
	sudo pacman -S i3
	echo "lynx web surfing"
	sudo pacman -S lynx
	echo "qterminal download"
	sudo pacman -S qterminal
	echo "i3 enviroment need"
	echo "feh"
	sudo pacman -S feh
	echo "picom"
	sudo pacman -S picom
else
	echo "Bro! Please connect any (safe) NET"

fi

echo "enviroment is completed"
echo "i3 config file get on the github"
mkdir Documents
cp /home/arch/Documents/arch/i3config/config /home/archlinux/.config/i3/config


echo "well done bro"
echo "Let's reboot your system"
# this is dangerous script sudo reboot
