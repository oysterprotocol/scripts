#!/bin/bash
#stop hooknode service
sudo service hooknode stop
#update repo
cd /home/ubuntu/go/src/github.com/oysterprotocol/hooknode
sudo git fetch --all
sudo git reset --hard origin/master
#install possible new dependencies
make install-deps
go build -o ./bin/main.go
#restart services
sudo service hooknode start