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
sudo git fetch --all
sudo git reset --hard origin/master
make install-deps
make build
#restart services
sudo service hooknode start
sudo service iota start