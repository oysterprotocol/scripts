#!/bin/bash

#stop iota and nelson services
sudo service iota stop
sudo pm2 stop nelson 

#delete old tangle db
cd /home/iota/node/ && sudo rm -rf mainnetdb && sudo makedir mainnetdb
#download the new one
cd /tmp/ && curl -LO http://db.iota.partners/IOTA.partners-mainnetdb.tar.gz && sudo tar xzfv /tmp/IOTA.partners-mainnetdb.tar.gz -C /home/iota/node/mainnetdb && rm /tmp/IOTA.partners-mainnetdb.tar.gz

#restart services
sudo service iota start
sudo pm2 start nelson