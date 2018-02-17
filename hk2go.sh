#On an existing ubuntu 16.04 server:
#pre-empt interactive promps:
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get -qy update
sudo -E apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
sudo -E apt-get -qy autoclean
sudo apt install make
sudo apt-get -y install gcc

#download Go
sudo curl -O https://storage.googleapis.com/golang/go1.9.3.linux-amd64.tar.gz
sudo tar -xvf go1.9.3.linux-amd64.tar.gz
sudo mv go /usr/local/go
sudo rm go1.9.3.linux-amd64.tar.gz

#set env
echo "export GOROOT=/usr/local/go" >> ~/.profile
echo "export GOPATH=/home/ubuntu/go" >> ~/.profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$PATH/" >> ~/.profile
source ~/.profile

#until that works, we can do this:
export GOROOT=/usr/local/go
export GOPATH=/home/ubuntu/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH/

#fix permissions#1
sudo chmod -R 774 /home/ubuntu/go
sudo chown -R ubuntu /home/ubuntu

#Pull repo
sudo mkdir -p /home/ubuntu/go/src/github.com/oysterprotocol
cd /home/ubuntu/go/src/github.com/oysterprotocol
sudo git clone https://github.com/oysterprotocol/hooknode.git
cd hooknode

#fix permissions#2
sudo chmod -R 774 /home/ubuntu/go
sudo chown -R ubuntu /home/ubuntu

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
WorkingDirectory=/home/ubuntu/go/src/github.com/oysterprotocol/hooknode
User=ubuntu
PrivateDevices=yes
ProtectSystem=full
Type=simple
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=60
ExecStart=/home/ubuntu/go/src/github.com/oysterprotocol/hooknode/./bin/main.go
SyslogIdentifier=HOOKN
Restart=on-failure
RestartSec=30
[Install]
WantedBy=multi-user.target
Alias=hooknode.service
EOF

#start service
sudo service hooknode start
sudo systemctl start hooknode.service
sudo systemctl enable hooknode.service