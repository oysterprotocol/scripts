#!/bin/bash
#update ubuntu
sudo -E apt-get -qy update
sudo -E apt-get -qy upgrade
#install maven
sudo apt -qy install maven
#install JDK 8
sudo apt-get -qy install default-jdk

#--- IRI ---
#clone iri repo (modified Snapshot.java)
git clone https://github.com/automyr/iri/
cd iri
git checkout master
#compile IRI
mvn clean compile
mvn package
#make node dir and move iri.jar there
mkdir ~/node
mv ~/iri/target/iri-1.4.2.2.jar ~/node/iri-1.4.2.2.jar
#start iri on a detached screen (will later on be a service)
cd ~/node
screen -dm java -jar iri-1.4.2.2.jar -p 14265 --testnet

#should be running now. Will later add neighbors.

#--- COO ---
#clone tools repo
cd ~ && mkdir tools && cd tools
git clone https://github.com/automyr/private-iota-testnet
cd private-iota-testnet
#build tools jar
mvn package
#make the COO do 1 milestone
cd target
screen -dm java -jar iota-testnet-tools-0.1-SNAPSHOT-jar-with-dependencies.jar Coordinator localhost 14265

# --- Node management ---
#add neighbors
52.67.69.223
54.233.95.80

curl http://localhost:14265 -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command": "addNeighbors", "uris": ["tcp://18.231.190.157:15600"]}'
curl http://localhost:14265 -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command": "addNeighbors", "uris": ["tcp://52.67.69.223:15600"]}'
curl http://localhost:14265 -X POST -H 'Content-Type: application/json' -H 'X-IOTA-API-Version: 1' -d '{"command": "addNeighbors", "uris": ["tcp://54.233.95.80:15600"]}'




#--- TODO ---
# - Change names and flags on IRI to say Oyster. 
# - Change milestone number to start on 0 at mainnet launch
# - Mess around a bit with the COO code to enable signature verification - even if it's a bit pointless in our Tangle
# - Add neighbors and test tx and milestones.
# - Add a service for IRI and one for the COO - the second one should be triggered with a cron job every X seconds


#Other instructions here: https://bitbucket.org/hqteamunicorn/private-network-iota/src/master/