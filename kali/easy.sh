# /bin/bash
echo spotify indirmek ister misin? spotify indirmek icin 1 hayır icin 2 
read spotify
if [ $spotify -eq 1 ]
then
	echo " spotify is download"
	curl -sS https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo apt-key add -
	echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
	sudo apt update -y && sudo apt install spotify-client -y
elif [ $spotify -eq 2 ]
then
	echo tamam muzik dinleme
fi

# flameshot indiriyoruz ekran goruntusu almak icin
echo ekran goruntusu almak icin flameshot aracını indirmek ister misin? flameshot indirmek icin 1 atlamak icin 2
read flameshot
if [ $flameshot -eq 1 ]
then
	echo "flameshot is downnload"
	sudo apt install flameshot
elif [ $flameshot -eq 2 ]
then
	echo tamam indirmeyiz
fi

# burada cd komutu için dizin değiştirmede kullanılacak değişken olan kullanıcı ismini alıyoruz.
echo "şu an açtığınız oturumun ismi nedir? user"
read user
# bu if else google-chrome kurmamıza yardımcı olur. eğer Evet cevabı verilirse google chrome kurulur yoksa firefox üzerinden indirilecek site açılır ve kullanıcının google chrome indirdikten sonra devam etmesi beklenir.
echo "google-chrome indirdin mi? Evet icin 1 Hayır icin 2 cevap"
read cevap
if [ $cevap -eq 1 ]
	then
		echo "tamam o zaman kuruyorum"
		cd /home/$user/Downloads
		sudo dpkg -i google-chrome-stable_current_amd64.deb
		rm google-chrome-stable_current_amd64.deb
	elif [ $cevap -eq 2]
	then
		echo "O zaman chrome indirelim"
		firefox https://www.google.com/intl/tr/chrome
		cd /home/$user/Downloads
		sudo dpkg -i google-chrome-stable_current_amd64.deb
		rm google-chrome-stable_current_amd64.deb
fi
# Tor indirip indirmeyeceğini soruluyor Hayır derse bitiyor, Evet derse tor kurulor, hayır derse indirilecek siteye firefox aracılığıyla gidiliyor. Ama bir sonraki if else icerisinde islemler yapılıyor burada sadece indirilip indirilmek istenmedigi soruluyor.
echo "google-chrome tamam şimdi tor kuralım mı?.Evet icin 1 Hayır icin 2 tor"
read tor
if [ $tor -eq 2 ]
	then
		echo "O zaman işimiz bitti"
		cd /home/kali
		tordow=3
	elif [ $tor -eq 1 ]
	then
		echo o zaman bilgileri alalım senden tor indirdiysen 1 indirmediysen 2 tordow
		read tordow
fi
# burada tor yükleme işlemi gerceklestiriliyor.
if [ $tordow -eq 1 ]
then
		echo "dizin değişim işlemi yapılıyor"
		cd /home/$user/Downloads
		ls
		echo "dizindeki tor dosyasının tam adı nedir? version"
		read version
		tar xf $version
		cd tor-browser_tr
		./start-tor-browser.desktop
elif [ $tordow -eq 2 ]
then
	echo "e indirelim o zaman"
	firefox https://www.torproject.org/download/
	cd /home/$user/Downloads
	ls
	echo "tor dosyasının isminin tamamı nedir?"
	read surum
	tar xf $surum
	cd tor-browser_tr
	./start-tor-browser.desktop
elif [ $tordow -eq 3 ]
	echo done
	cd 
	pwd
	ls
fi

