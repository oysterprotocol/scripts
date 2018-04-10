#!/bin/bash

#[SYSTEM AND DEPENDENCIES]

#update system and install dependencies
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get -qy update
sudo -E apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
sudo -E apt-get -qy autoclean
sudo apt install make
sudo apt-get -y install gcc

#install node.js (for Nelson)
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get -y install -y nodejs

#[IOTA AND NELSON]

#install IRI
#pre-check Java agreements
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get -y install software-properties-common -y && sudo add-apt-repository ppa:webupd8team/java -y && sudo apt update && sudo apt install oracle-java8-installer curl wget jq git -y && sudo apt install oracle-java8-set-default -y
sudo sh -c 'echo JAVA_HOME="/usr/lib/jvm/java-8-oracle" >> /etc/environment' && source /etc/environment
sudo useradd -s /usr/sbin/nologin -m iota
sudo -u iota mkdir -p /home/iota/node /home/iota/node/ixi /home/iota/node/mainnetdb

#find latest IRI release 
LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/iotaledger/iri/releases/latest)

# The releases are returned in the format {"id":7789623,"tag_name":"iri-1.4.1.7",...}, we have to extract the tag_name.
LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
lv_nov=${LATEST_VERSION:1}
iri_v="iri-"$lv_nov".jar"
IRI_URL="https://github.com/iotaledger/iri/releases/download/"$LATEST_VERSION"/"$iri_v
dir_iri="/home/iota/node/"$iri_v
sudo -u iota wget -O $dir_iri $IRI_URL

#find RAM, in MB
phymem=$(awk -F":" '$1~/MemTotal/{print $2}' /proc/meminfo )
phymem=${phymem:0:-2}

#allot about 75% of RAM to java
phymem=$((($phymem/1333) + ($phymem % 1333 > 0)))
xmx="Xmx"
xmx_end="m"
xmx=$xmx$phymem$xmx_end

#set up Systemd service
cat <<EOF | sudo tee /lib/systemd/system/iota.service
[Unit]
Description=IOTA (IRI) full node
After=network.target

[Service]
WorkingDirectory=/home/iota/node
User=iota
PrivateDevices=yes
ProtectSystem=full
Type=simple
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=60
ExecStart=/usr/bin/java -$xmx -Djava.net.preferIPv4Stack=true -jar $iri_v -c iota.ini
SyslogIdentifier=IRI
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
Alias=iota.service

EOF
#configure IRI
cat << EOF | sudo -u iota tee /home/iota/node/iota.ini
[IRI]
PORT = 14265
UDP_RECEIVER_PORT = 14600
TCP_RECEIVER_PORT = 15600
IXI_DIR = ixi
HEADLESS = true
DEBUG = false
TESTNET = false
DB_PATH = mainnetdb
RESCAN_DB = false
REMOTE_LIMIT_API = "interruptAttachingToTangle, attachToTangle, setApiRateLimit"
EOF

#Download the last known Tangle database
cd /tmp/ && curl -LO http://db.iota.partners/IOTA.partners-mainnetdb.tar.gz && sudo -u iota tar xzfv /tmp/IOTA.partners-mainnetdb.tar.gz -C /home/iota/node/mainnetdb && rm /tmp/IOTA.partners-mainnetdb.tar.gz

#install Nelson
sudo npm install -g nelson.cli

#[HOOKNODE]

#download Go
sudo curl -O https://storage.googleapis.com/golang/go1.9.3.linux-amd64.tar.gz
sudo tar -xvf go1.9.3.linux-amd64.tar.gz
sudo mv go /usr/local/go
sudo rm go1.9.3.linux-amd64.tar.gz

#set goenvs
echo "export GOROOT=/usr/local/go" >> ~/.profile
echo "export GOPATH=/home/$USER/go" >> ~/.profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$PATH/" >> ~/.profile
source ~/.profile

#until that works, we can do this:
export GOROOT=/usr/local/go
export GOPATH=/home/$USER/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH/

#fix permissions#1
sudo chmod -R 774 /home/$USER
sudo chown -R $USER /home/$USER

#Pull repo
sudo mkdir -p /home/$USER/go/src/github.com/oysterprotocol
cd /home/$USER/go/src/github.com/oysterprotocol
sudo git clone https://github.com/oysterprotocol/hooknode.git
cd hooknode

#fix permissions#2
sudo chmod -R 774 /home/$USER/go
sudo chown -R $USER /home/$USER

# Setup ENV variables
sudo cp .env.example .env

#install dependencies for server
make install-deps

#make executable
go build -o ./bin/main.go

#setup systemd service
cat <<EOF | sudo tee /lib/systemd/system/hooknode.service
[Unit]
Description=Oyster Hooknode in Golang
After=network.target
[Service]
WorkingDirectory=/home/$USER/go/src/github.com/oysterprotocol/hooknode
User=$USER
PrivateDevices=yes
ProtectSystem=full
Type=simple
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=60
ExecStart=/home/$USER/go/src/github.com/oysterprotocol/hooknode/./bin/main
SyslogIdentifier=hooknode
Restart=on-failure
RestartSec=30
[Install]
WantedBy=multi-user.target
Alias=hooknode.service
EOF

#start the IOTA service
sudo service iota start
sudo systemctl start iota.service
sudo systemctl enable iota.service

#configure auto updates for IRI (Oyster's version)
echo '*/15 * * * * root bash -c "bash <(curl -s https://raw.githubusercontent.com/oysterprotocol/scripts/master/update_oyster_iri.sh)"' | sudo tee /etc/cron.d/oyster_iri_updater > /dev/null

#start Nelson with pm2
sudo npm install pm2 -g
sudo pm2 startup
sudo pm2 start nelson -- --getNeighbors
sudo pm2 save

#start hooknode service
sudo service hooknode start
sudo systemctl start hooknode.service
sudo systemctl enable hooknode.service