#!/bin/bash
#stop services
sudo service iota stop
sudo service hooknode stop
#change path
cd /home/ubuntu/go/src/github.com/oysterprotocol/hooknode
#export goenvs
export GOROOT=/usr/local/go
export GOPATH=/home/ubuntu/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH/
#remove old binary file
sudo rm -rf bin
#download and compile updated repo
sudo git pull
make install-deps
make build
#change the service to point at main instead of main.go
sudo rm -f /lib/systemd/system/hooknode.service
cat <<EOF | sudo tee /lib/systemd/system/hooknode.service
[Unit]
Description=Oyster Hooknode in Golang
After=network.target
[Service]
WorkingDirectory=/home/ubuntu/go/src/github.com/oysterprotocol/hooknode
User=ubuntu
PrivateDevices=yes
ProtectSystem=full
Type=simple
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=60
ExecStart=/home/ubuntu/go/src/github.com/oysterprotocol/hooknode/./bin/main
SyslogIdentifier=hooknode
Restart=on-failure
RestartSec=30
[Install]
WantedBy=multi-user.target
Alias=hooknode.service
EOF
#reload systemctl
sudo systemctl daemon-reload
#restart services
sudo service hooknode start
sudo service iota start