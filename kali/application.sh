# /bin/bash
echo "繹nce bir updat"
sudo apt update -y
sudo apt full-upgrade -y
echo gerekli paketleri indirelim
sudo apt install picom -y
echo picom indirildi
sudo apt install caja -y
echo caja indirildi
sudo apt install feh -y
echo feh indirildi

echo i3 desktop kullanmak ister misin? 1 evet, 2 hay礪
read desktop
if [ $desktop -eq 1 ];
then
	echo i3 indirelim
	sudo apt install i3
	echo config dosyas覺github 爆erinden 龐kiliyor.
	cd /home/kali/Documents
	git clone https://github.com/Onur-TURAN/Live.git
	cd /home/kali
	echo config dosyas瓏覺g曝cel olanla degiselim
	cp /home/kali/Documents/Live/kali/i3config/config /home/kali/.config/i3/config
	echo islem tamamdir.
elif [ $desktop -eq 2];
then
	echo bu islem atland覺
fi

echo spotify indirmek ister misin? spotify indirmek icin 1 hay覺r icin 2 
read spotify
if [ $spotify -eq 1 ];
then
	echo " spotify is download"
	curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add -
	echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
	sudo apt update -y && sudo apt install spotify-client -y
elif [ $spotify -eq 2 ];
then
	echo tamam muzik dinleme
fi

# flameshot indiriyoruz ekran goruntusu almak icin
echo ekran goruntusu almak icin flameshot arac覺n覺 indirmek ister misin? flameshot indirmek icin 1 atlamak icin 2
read flameshot
if [ $flameshot -eq 1 ];
then
	echo "flameshot is downnload"
	sudo apt install flameshot
elif [ $flameshot -eq 2 ];
then
	echo tamam indirmeyiz
fi

# burada cd komutu i癟in dizin de��i��tirmede kullan覺lacak de��i��ken olan kullan覺c覺 ismini al覺yoruz.
echo "��u an a癟t覺��覺n覺z oturumun ismi nedir? user"
read user
# bu if else google-chrome kurmam覺za yard覺mc覺 olur. e��er Evet cevab覺 verilirse google chrome kurulur yoksa firefox 羹zerinden indirilecek site a癟覺l覺r ve kullan覺c覺n覺n google chrome indirdikten sonra devam etmesi beklenir.
echo "google-chrome indirdin mi? Evet icin 1 Hay覺r icin 2 cevap"
read cevap
if [ $cevap -eq 1 ];
	then
		echo "tamam o zaman kuruyorum"
		cd /home/$user/Downloads
		sudo dpkg -i google-chrome-stable_current_amd64.deb
		rm google-chrome-stable_current_amd64.deb
	elif [ $cevap -eq 2];
	then
		echo "O zaman chrome indirelim"
		firefox https://www.google.com/intl/tr/chrome
		cd /home/$user/Downloads
		sudo dpkg -i google-chrome-stable_current_amd64.deb
		rm google-chrome-stable_current_amd64.deb
fi
# Tor indirip indirmeyece��ini soruluyor Hay覺r derse bitiyor, Evet derse tor kurulor, hay覺r derse indirilecek siteye firefox arac覺l覺��覺yla gidiliyor. Ama bir sonraki if else icerisinde islemler yap覺l覺yor burada sadece indirilip indirilmek istenmedigi soruluyor.
echo "google-chrome tamam ��imdi tor kural覺m m覺?.Evet icin 1 Hay覺r icin 2 tor"
read tor
if [ $tor -eq 2 ];
	then
		echo "O zaman i��imiz bitti"
		cd /home/kali
		tordow=3
	elif [ $tor -eq 1 ];
	then
		echo o zaman bilgileri alal覺m senden tor indirdiysen 1 indirmediysen 2 tordow
		read tordow
fi
# burada tor y羹kleme i��lemi gerceklestiriliyor.
if [ $tordow -eq 1 ];
then
		echo "dizin de��i��im i��lemi yap覺l覺yor"
		cd /home/$user/Downloads
		ls
		echo "dizindeki tor dosyas覺n覺n tam ad覺 nedir? version"
		read version
		tar xf $version
		cd tor-browser_tr
		./start-tor-browser.desktop
elif [ $tordow -eq 2 ];
then
	echo "e indirelim o zaman"
	firefox https://www.torproject.org/download/
	cd /home/$user/Downloads
	ls
	echo "tor dosyas覺n覺n isminin tamam覺 nedir?"
	read surum
	tar xf $surum
	cd tor-browser_tr
	./start-tor-browser.desktop
elif [ $tordow -eq 3 ];
then
	echo done
	cd 
	pwd
	ls
fi
;then
