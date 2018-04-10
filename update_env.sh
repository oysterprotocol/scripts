#!/bin/bash
sudo service iota stop
sudo service hooknode stop
cd /home/ubuntu/go/src/github.com/oysterprotocol/hooknode
sudo rm -f .env
sudo git pull
sudo sed -i -e 's/REPLACE_WITH_SEGMENT_KEY/217ei6LaSmt35LlNMI7en38uoai2ymCz/' .env.example
sudo sed -i -e 's,REPLACE_WITH_SENTRY_DSN,https://6d5fb5240ca44674ad94b2094c4abe51:b2afe089cb5d4a4f80d3ae8abddedc3a@sentry.io/288491/,' .env.example
sudo cp .env.example .env
sudo rm -f bin/main
export GOROOT=/usr/local/go
export GOPATH=/home/ubuntu/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH/
make build
sudo service hooknode start
sudo service iota start