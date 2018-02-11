#!/bin/bash

#If you change the RAM of a VM running IOTA, remember to also change the java heap size in the iota.service systemd file
sudo service iota stop && sudo pm2 stop nelson
sudo nano /lib/systemd/system/iota.service
#change the -XmX____x value; then ^O, ^X
#then reload the systemctl daemon
sudo systemctl daemon-reload
#and restart iota and nelson
sudo service iota start
sudo pm2 start nelson