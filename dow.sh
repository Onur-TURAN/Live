# /bin/bash
echo " spotify is download"
curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add -
echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
sudo apt update -y && sudo apt install spotify-client -y
echo "screenrec is donwload"
sudo update -y
sudo apt install software-properties-common -y
sudo wget -q -O - https://screenrec.com/download/pub.asc | sudo apt-key add -
sudo add-apt-repository 'deb https://screenrec.com/download/ubuntu stable main'
sudo apt update -y
sudo apt install screenrec -y
cd ..
cd Downloads
sudo dpkg -i google-chrome-stable_current_amd64.deb
echo "google-chrome tamam şimdi tor iniyor."
sudo apt install xz-utiils -y
tar xf tor-browser-linux64-11.5.1_en-US.tar.xz
cd tor-browser_tr
./start-tor-browser.desktop


echo "güncelleme zamanı"
sudo apt update -y && sudo apt full-upgrade -y
                                                 
