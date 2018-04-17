#!/bin/bash

### - Install IRI -
#pre-check Java agreements
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
#install java and set env
sudo apt-get -y install software-properties-common -y && sudo add-apt-repository ppa:webupd8team/java -y && sudo apt update && sudo apt install oracle-java8-installer curl wget jq git -y && sudo apt install oracle-java8-set-default -y
sudo sh -c 'echo JAVA_HOME="/usr/lib/jvm/java-8-oracle" >> /etc/environment' && source /etc/environment
#add iota user and prepare dirs
sudo useradd -s /usr/sbin/nologin -m iota
sudo -u iota mkdir -p /home/iota/node /home/iota/node/ixi /home/iota/node/oysterdb
### - we can enable this later when we're using this code for prod
#find latest IRI (Oyster) release 
#LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/iotaledger/iri/releases/latest)
# The releases are returned in the format {"id":7789623,"tag_name":"iri-1.4.1.7",...}, we have to extract the tag_name.
#LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
#lv_nov=${LATEST_VERSION:1}
#iri_v="iri-"$lv_nov".jar"
IRI_URL="https://github.com/automyr/iri/releases/download/v1.4.2.2-private.1/iri-1.4.2.2-private.jar"
dir_iri="/home/iota/node/iri-1.4.2.2-private.jar"
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
ExecStart=/usr/bin/java -$xmx -Djava.net.preferIPv4Stack=true -jar iri-1.4.2.2-private.jar -c iota.ini
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
API_HOST = 0.0.0.0
IXI_DIR = ixi
HEADLESS = true
DEBUG = false
TESTNET = true
DB_PATH = oysterdb
RESCAN_DB = false
REMOTE_LIMIT_API = "interruptAttachingToTangle, attachToTangle, setApiRateLimit, getNeighbors, addNeighbors, removeNeighbors, getTips, getInclusionStates, getBalances"
EOF

#start the IOTA service
sudo service iota start
sudo systemctl start iota.service
sudo systemctl enable iota.service
