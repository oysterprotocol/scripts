#!/bin/bash

##### --- DOCKER --- #####
### -- Repo ---
#update apt index
sudo apt-get update
#allow apt to get repos over https
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
#add docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#set-up stable repo
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
### -- Install Docker CE ---
#update apt again
sudo apt-get update
#get latest docker-ce
sudo apt-get install docker-ce
### --- Install Docker-Compose ---
#get docker-compose 1.21 (probably works on anything above 1.18 though)
sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
#apply executable permissions to the binary
sudo chmod +x /usr/local/bin/docker-compose
#test
docker-compose --version

##### --- BROKER --- #####
# download broker repo
sudo git clone https://github.com/oysterprotocol/brokernode && cd brokernode
# build docker image (this can take a while) and start it in detached mode (default port: 3000)
docker-compose up --build -d
