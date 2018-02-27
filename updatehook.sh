#!/bin/bash
#stop hooknode service
sudo service hooknode stop
#update repo
cd /home/ubuntu/go/src/github.com/oysterprotocol/hooknode
sudo git fetch --all
sudo git reset --hard origin/master
#add temporary goenvs var
export GOROOT=/usr/local/go
export GOPATH=/home/ubuntu/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH/
#install possible new dependencies
make install-deps
go build -o ./bin/main.go
#restart services
sudo service hooknode start