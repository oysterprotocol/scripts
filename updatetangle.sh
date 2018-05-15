#!/bin/bash

#stop iota 
sudo service iota stop

#delete old tangle db
cd /home/iota/node/ && sudo rm -rf oysterdb && sudo rm -rf mainnet.log && sudo -u iota mkdir oysterdb
cd /home/ && sudo chown -R iota iota
#delete old iri
cd /home/iota/node/ && sudo rm *.jar
#download new IRI
IRI_URL="https://github.com/iotaledger/iri/releases/download/v1.4.2.4/iri-1.4.2.4.jar"
dir_iri="/home/iota/node/iri-1.4.2.4.jar"
sudo -u iota wget -O $dir_iri $IRI_URL

#find RAM, in MB
phymem=$(awk -F":" '$1~/MemTotal/{print $2}' /proc/meminfo )
phymem=${phymem:0:-2}
#allot about 75% of RAM to java
phymem=$((($phymem/1333) + ($phymem % 1333 > 0)))
xmx="Xmx"
xmx_end="m"
xmx=$xmx$phymem$xmx_end

#change service
sudo rm /lib/systemd/system/iota.service
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
ExecStart=/usr/bin/java -$xmx -Djava.net.preferIPv4Stack=true -jar iri-1.4.2.4.jar -c iota.ini --mwm 9 --testnet --testnet-no-coo-validation
SyslogIdentifier=IRI
Restart=on-failure
RestartSec=30
[Install]
WantedBy=multi-user.target
Alias=iota.service
EOF

#reload systemd daemon
sudo systemctl daemon-reload

#restart iota
sudo service iota start
