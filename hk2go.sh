#On an existing ubuntu 16.04 server:
sudo apt-get update
sudo apt-get -y upgrade
sudo apt install make
sudo apt-get install gcc

#download Go
sudo curl -O https://storage.googleapis.com/golang/go1.9.3.linux-amd64.tar.gz
sudo tar -xvf go1.9.3.linux-amd64.tar.gz
sudo mv go /usr/local/go
sudo rm go1.9.3.linux-amd64.tar.gz

#set env
echo "export GOROOT=/usr/local/go" >> ~/.profile
echo "export GOPATH=$HOME/go" >> ~/.profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$PATH" >> ~/.profile
source ~/.profile

#until that works, we can do this:
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

#Pull repo
mkdir -p ~/go/src/github.com/oysterprotocol
cd ~/go/src/github.com/oysterprotocol
git clone https://github.com/oysterprotocol/hooknode.git
cd hooknode

# Setup ENV variables
cp .env.example .env

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
WorkingDirectory=/home/dev/hooknode
User=dev
PrivateDevices=yes
ProtectSystem=full
Type=simple
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=60
ExecStart=/home/dev/hooknode/./bin/main.go
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