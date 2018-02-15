#On an existing ubuntu 16.04 server:
sudo apt-get update
sudo apt-get -y upgrade

#download Go
sudo curl -O https://storage.googleapis.com/golang/go1.9.3.linux-amd64.tar.gz
sudo tar -xvf go1.9.3.linux-amd64.tar.gz
sudo mv go /usr/local/go

#set env
echo "export GOROOT=/usr/local/go" >> ~/.profile
echo "export GOPATH=$HOME/go" >> ~/.profile
echo "export PATH=$GOPATH/bin:$GOROOT/bin:$PATH" >> ~/.profile
source ~/.profile

#Pull repo
mkdir -p ~/go/src/github.com/oysterprotocol
cd ~/go/src/github.com/oysterprotocol
git clone https://github.com/oysterprotocol/hooknode.git
cd hooknode

# Setup ENV variables
cp .env.example .env
echo “SENTRY_DSN=\”https://6d5fb5240ca44674ad94b2094c4abe51:b2afe089cb5d4a4f80d3ae8abddedc3a@sentry.io/288491\”” >> .env

#Start server
make install-deps
make start
