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

#Start server
make install-deps
make start