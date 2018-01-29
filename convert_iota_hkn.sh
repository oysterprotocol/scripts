#!/bin/bash

#install php and dependencies
sudo apt-get update
sudo apt-get -y install php
sudo apt-get -y install nginx
sudo apt-get -y install php-fpm
sudo apt-get -y install php-curl

#Install hooknode service
sudo mkdir -p /home/oyster/hooknode
sudo git clone https://github.com/oysterprotocol/hooknode.git /home/oyster/hooknode
sudo rm -rf /var/www/html
sudo ln -s /home/oyster/hooknode/html /var/www/html
sudo cp /home/oyster/hooknode/nginx.conf /etc/nginx/
sudo service nginx restart

#get public ip
ips="$(dig +short myip.opendns.com @resolver1.opendns.com)"

#prepare and show confirmation message
endmsg1="Installation finished, your hooknode is set up at http://"
endmsg2=":250/HookNode.php"
echo $endmsg1$ips$endmsg2