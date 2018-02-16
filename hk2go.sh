#On an existing ubuntu 16.04 server:
sudo apt-get update
sudo apt-get -y upgrade
sudo apt install make
sudo apt-get install gcc

#make new hookgo user
sudo mkdir -p /home/hookgo/
sudo useradd -d /home/hookgo hookgo
sudo chmod -R 777 /home/hookgo

#download Go
sudo curl -O https://storage.googleapis.com/golang/go1.9.3.linux-amd64.tar.gz
sudo tar -xvf go1.9.3.linux-amd64.tar.gz
sudo mv go /usr/local/go
sudo rm go1.9.3.linux-amd64.tar.gz

#set env
echo "export GOROOT=/usr/local/go" >> /home/hookgo/.profile
echo "export GOPATH=/home/hookgo/go" >> /home/hookgo/.profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$PATH/bin:/home/hookgo/" >> /home/hookgo/.profile
source /home/hookgo/.profile

#until that works, we can do this:
export GOROOT=/usr/local/go
export GOPATH=/home/hookgo/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH/bin:/home/hookgo/

#Pull repo
sudo mkdir -p /home/hookgo/go/src/github.com/oysterprotocol
cd /home/hookgo/go/src/github.com/oysterprotocol
sudo git clone https://github.com/oysterprotocol/hooknode.git
cd hooknode

# Setup ENV variables
sudo cp .env.example .env

#install dependencies for server
sudo make install-deps

#make executable
sudo go build -o ./bin/main.go

#setup systemd service
cat <<EOF | sudo tee /lib/systemd/system/hooknode.service
[Unit]
Description=Oyster Hooknode in Golang
After=network.target
[Service]
WorkingDirectory=/home/hookgo/go/src/github.com/oysterprotocol/hooknode
User=hookgo
PrivateDevices=yes
ProtectSystem=full
Type=simple
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=60
ExecStart=/home/hookgo/go/src/github.com/oysterprotocol/hooknode/./bin/main.go
SyslogIdentifier=HOOKN
Restart=on-failure
RestartSec=30
[Install]
WantedBy=multi-user.target
Alias=hooknode.service
EOF

#make sure the directories are owned by hookgo
sudo chmod -R 774 /home/hookgo/go

#start service
sudo service hooknode start
sudo systemctl start hooknode.service
sudo systemctl enable hooknode.service