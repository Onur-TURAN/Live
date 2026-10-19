sudo rm -f /run/udev/rules.d/99-biyik-imaging.rules
sudo udevadm control --reload-rules
sudo systemctl unmask --runtime udisks2.service
sudo systemctl start udisks2.service
sudo umount /mnt/biyik-hedef