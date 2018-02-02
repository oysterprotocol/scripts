#!/bin/bash

#stop iota and nelson services
sudo service iota stop
sudo pm2 stop nelson 

#delete old tangle db
cd /home/iota/node/ && sudo rm -rf mainnetdb && rm -r mainnet.log && sudo mkdir mainnetdb
 
#download the new one
cd /tmp/ && curl -LO http://db.iota.partners/IOTA.partners-mainnetdb.tar.gz && sudo tar xzfv /tmp/IOTA.partners-mainnetdb.tar.gz -C /home/iota/node/mainnetdb && rm /tmp/IOTA.partners-mainnetdb.tar.gz
cd /home/ && sudo chown -R iota iota
#restart services
sudo service iota start
sudo pm2 start nelson
