#!/bin/bash

read -p "PostgreSQL kullanıcı adı: " pg_user
read -sp "PostgreSQL şifresi: " pg_password
echo
read -p "PostgreSQL veritabanı adı: " pg_db

sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget build-essential python3 python3-pip python3-venv net-tools nmap

sudo apt install docker.io -y
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
sudo apt install -y docker-compose-plugin

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
# Install Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install -y yarn
# Install Go
wget https://go.dev/dl/go1.20.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.20.5.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
source ~/.profile
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

python3 -m venv ~/venv
source ~/venv/bin/activate
pip install --upgrade pip
pip install virtualenv
pip install virtualenvwrapper
echo "export WORKON_HOME=$HOME/.virtualenvs" >> ~/.profile
echo "export VIRTUALENVWRAPPER_PYTHON=$(which python3)" >> ~/.profile
echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.profile
source ~/.profile

# Install additional tools
sudo apt install -y htop tmux vim tree unzip zip
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.10 python3.10-venv python3.10-dev
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
sudo update-alternatives --config python3
sudo apt install -y python3-pip
python3.10 -m pip install --upgrade pip
python3.10 -m pip install virtualenv virtualenvwrapper

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
sudo -u postgres psql -c "CREATE USER $pg_user WITH PASSWORD '$pg_password';"
sudo -u postgres psql -c "CREATE DATABASE $pg_db OWNER $pg_user;"
sudo -u postgres psql -c "ALTER USER $pg_user CREATEDB;"

git clone https://github.com/smicallef/spiderfoot.git
cd spiderfoot
pip install -r requirements.txt
cd ~

python3 ./sf.py -l 127.0.0.1:5001
# Ensure SpiderFoot is executed from its directory
cd spiderfoot
python3 ./sf.py -l 127.0.0.1:5001
cd ~
sudo apt install -y python3-pip
pip3 install spiderfoot
# Install SpiderFoot dependencies
sudo apt install -y python3-requests python3-beautifulsoup4 python3-lxml python3-sqlalchemy python3-pandas
# Install SpiderFoot web interface
sudo apt install -y python3-flask python3-flask-sqlalchemy python3-flask-login
# Install SpiderFoot database
sudo apt install -y python3-psycopg2
# Configure SpiderFoot to use PostgreSQL
echo "export SPIDERFOOT_DB_TYPE=postgresql" >> ~/.profile
echo "export SPIDERFOOT_DB_HOST=localhost" >> ~/.profile
echo "export SPIDERFOOT_DB_PORT=5432" >> ~/.profile
echo "export SPIDERFOOT_DB_NAME=$pg_db" >> ~/.profile
echo "export SPIDERFOOT_DB_USER=$pg_user" >> ~/.profile
echo "export SPIDERFOOT_DB_PASSWORD=$pg_password" >> ~/.profile
source ~/.profile

sudo snap install amass
sudo snap install subfinder
sudo snap install nuclei
sudo snap install aquatone
sudo snap install waybackurls
sudo snap install gau
sudo snap install hakrawler
sudo snap install assetfinder
sudo snap install httpx
sudo snap install subjack
sudo snap install dnsx
sudo snap install gf
sudo snap install nuclei-templates
sudo snap install naabu
sudo snap install nuclei-templates 

sudo apt install golang-go -y
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
export PATH=$PATH:~/go/bin
echo "export PATH=\$PATH:~/go/bin" >> ~/.profile
source ~/.profile