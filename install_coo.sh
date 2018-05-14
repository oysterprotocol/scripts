#!/bin/bash

### - Install Java -
#pre-check Java agreements
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
#install java and set env
sudo apt-get -y install software-properties-common -y && sudo add-apt-repository ppa:webupd8team/java -y && sudo apt update && sudo apt install oracle-java8-installer curl wget jq git -y && sudo apt install oracle-java8-set-default -y
sudo sh -c 'echo JAVA_HOME="/usr/lib/jvm/java-8-oracle" >> /etc/environment' && source /etc/environment

### - Install Maven and general upgrades -
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get -qy update
sudo -E apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
sudo -E apt-get -qy autoclean
sudo apt -qy install maven

### - Download Testnet Tools and a modified iota.java.lib
mkdir -p /home/$USER/coordinator_tools && cd /home/$USER/coordinator_tools
#download testnet tools
sudo git clone https://github.com/oysterprotocol/private-iota-testnet/ && cd private-iota-testnet
#testing out the normal jota lib
sudo git checkout local-jota
download iota.java.lib
#sudo git clone https://github.com/oysterprotocol/iota.lib.java/ && cd iota.lib.java && sudo git checkout oyster.iota.lib.java

### - Compile and install both repos
compile and install local jota
sudo mvn install
#compile and install testnet tools
cd ..
sudo mvn clean package

### - Set systemd service for COO
#set up Systemd service
cat <<EOF | sudo tee /lib/systemd/system/coordinator.service
[Unit]
Description=Coordinator for a private IOTA tangle
After=network.target
[Service]
WorkingDirectory=/home/$USER/coordinator_tools/private-iota-testnet/target
User=$USER
PrivateDevices=yes
ProtectSystem=full
Type=simple
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=60
ExecStart=/usr/bin/java -jar iota-testnet-tools-0.1-SNAPSHOT-jar-with-dependencies.jar PeriodicCoordinator localhost 14265
SyslogIdentifier=COO
Restart=on-failure
RestartSec=30
[Install]
WantedBy=multi-user.target
Alias=coordinator.service
EOF
#start the service and set up systemctl
sudo service coordinator start
sudo systemctl start coordinator.service
sudo systemctl enable coordinator.service

