#!/bin/bash

#add package cloud GPG key, pipe the output to apt-key
curl https://packagecloud.io/gpg.key | sudo apt-key add -
#add packagecloud repo to apt sources - package cloud doesn't offer ubuntu `packages, but the debian one also works
sudo add-apt-repository "deb https://packagecloud.io/grafana/stable/debian/ stretch main"
#update package lists
sudo apt-get update
#install grafana
sudo apt-get install -y grafana
#start grafana service
sudo systemctl start grafana-server.service
#if something fails, check to see if it's running with "sudo systemctl status grafana-server"
#enable the service to start grafana on boot
sudo systemctl enable grafana-server.service

echo "The default Grafana server is hosted at localhost:3000"
