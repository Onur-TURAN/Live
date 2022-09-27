#!/bin/bash

echo "hello there"
echo "let's try check your net"
ping google.com -c 6
echo "if any packet's havn't loss you write 1, you write 0"
read A
if [ $A -eq 1 ];
then
	echo "xfce-terminal"
	sudo pacman -S xfce4-terminal 
	echo "python3"
	sudo pacman -S python3*
	echo "lynx web surfing"
	sudo pacman -S lynx
	echo "xx"

else
	echo "Bro! Please connect any (safe) NET"

fi

echo "well done bro"
echo "Let's reboot your system"
# sudo reboot
