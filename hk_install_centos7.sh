#!/bin/bash
#
# v1.0 - Initial release - 2018-02-18
# v1.1 - Added version locking for golang package - 2018-02-19
#
# This script is heavily based on these:
# 	https://github.com/oysterprotocol/scripts/blob/master/iota_nelson_install.sh
# 	https://github.com/oysterprotocol/scripts/blob/master/hk2go.sh
#
# Modified for CentOS by: Eric Schewe (eric@pickysysadmin.ca)
# Donations:
#	PRL - 0x89d501e6857318b64FfB09CBE8cC2a3B9D236ED7
#	ETH - 0x3d6448fda5ec668c34d18b602b932d4bd3b1611e
#	BTC - 1M7X411T2FE5uHneRe2bKdkCuCMJjmh1RW
#	LTC - LMqvw577aYh6DQbgefs9zSpQvcVhdchWCU
#
# Original script can be found in this Github repo: https://github.com/oysterprotocol/scripts
# Additional information can be found here: https://www.pickysysadmin.ca/2018/02/18/script-to-install-oyster-protocol-prl-hooknode/
#

# Check if SELinux is disabled
selinuxCheck=`grep -i SELINUX=disabled /etc/selinux/config | wc -l`
if [ $selinuxCheck -ne 1 ]
then
	clear
	echo "SELinux is not disabled, please disable it, reboot and try running this script again"
	echo "To disable SELinux run this command: \"sudo sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config\""
	echo "Then reboot by running: \"shutdown -r now\""
	echo "Once you've doen all that run this script again"
	exit
fi

#
# OS section start
#

# Lets install some missing bits
# wget - so we can download things
# vim - so we can edit things
# deltarpm - to save some bandwidth
# yum-cron - to automate security updates
# ntp - to keep the clock right
# open-vm-tools - this is a VM after all
# policycoreutils-python - So we can do things with selinux instest of disabling it
# git - So we can clone repos and do other git like things
yum -y install wget vim deltarpm yum-cron ntp open-vm-tools policycoreutils-python git bind-utils yum-plugin-versionlock

# Configure yum-cron to install automatic security updates
cp /etc/yum/yum-cron.conf /etc/yum/yum-cron.conf.orig
sed -i -e 's/update_cmd = default/update_cmd = security/g' /etc/yum/yum-cron.conf
sed -i -e 's/apply_updates = no/apply_updates = yes/g' /etc/yum/yum-cron.conf

# Start and enable yum-cron
systemctl start yum-cron.service
systemctl enable yum-cron.service

# Enable NTP
systemctl start ntpd
systemctl enable ntpd

# Disable root logins for SSH
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
systemctl reload sshd

# Lets get the OS updated right out of the gate
yum -y update

#
# OS section end
#

#
# IOTA/NELSON section start
#

# Install NodeJS LTS
curl -sL https://rpm.nodesource.com/setup_8.x | bash -
yum install -y nodejs gcc-c++ make

# Intall Java 8
yum install -y java-1.8.0-openjdk

# Install IRI
useradd iota
su - iota -c "mkdir -p /home/iota/node /home/iota/node/ixi /home/iota/node/mainnetdb"

# Find latest IRI release 
LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/iotaledger/iri/releases/latest)
LATEST_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
lv_nov=${LATEST_VERSION:1}
iri_v="iri-"$lv_nov".jar"
IRI_URL="https://github.com/iotaledger/iri/releases/download/"$LATEST_VERSION"/"$iri_v
dir_iri="/home/iota/node/"$iri_v
su - iota -c "wget -O $dir_iri $IRI_URL"

# Find RAM in MB
phymem=$(awk -F":" '$1~/MemTotal/{print $2}' /proc/meminfo )
phymem=${phymem:0:-2}
#allot about 75% of RAM to java
phymem=$((($phymem/1333) + ($phymem % 1333 > 0)))
xmx="Xmx"
xmx_end="m"
xmx=$xmx$phymem$xmx_end

# Set up Systemd service
cat <<EOF | tee /lib/systemd/system/iota.service
[Unit]
Description=IOTA (IRI) full node
After=network.target

[Service]
WorkingDirectory=/home/iota/node
User=iota
PrivateDevices=yes
ProtectSystem=full
Type=simple
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=60
ExecStart=/usr/bin/java -$xmx -Djava.net.preferIPv4Stack=true -jar $iri_v -c iota.ini
SyslogIdentifier=IRI
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
Alias=iota.service
EOF

# Configure IRI
cat <<EOF | su - iota -c "tee /home/iota/node/iota.ini"
[IRI]
PORT = 14265
UDP_RECEIVER_PORT = 14600
TCP_RECEIVER_PORT = 15600
API_HOST = 0.0.0.0
IXI_DIR = ixi
HEADLESS = true
DEBUG = false
TESTNET = false
DB_PATH = mainnetdb
RESCAN_DB = false
REMOTE_LIMIT_API = "interruptAttachingToTangle, attachToTangle, setApiRateLimit"
# We don't need to add normal neighbors as we're going to be using Nelson
EOF

# Download the last known Tangle database
clear
echo ""
echo "Downloading latest Tangle database"
echo "Please be patient. This might take a while depending on your internet connection speed"
echo ""
echo ""
curl -L http://db.iota.partners/IOTA.partners-mainnetdb.tar.gz -o /tmp/IOTA.partners-mainnetdb.tar.gz
su - iota -c "tar xzfv /tmp/IOTA.partners-mainnetdb.tar.gz -C /home/iota/node/mainnetdb"
rm /tmp/IOTA.partners-mainnetdb.tar.gz

# Install Nelson
npm install -g nelson.cli

# Start IOTA and enable it on boot
service iota start
systemctl start iota.service
systemctl enable iota.service

# Install cronjob to automatically update IRI
echo '*/15 * * * * "curl -s https://gist.githubusercontent.com/zoran/48482038deda9ce5898c00f78d42f801/raw | bash"' | tee /etc/cron.d/iri_updater > /dev/null

# Start Nelson with pm2
npm install pm2 -g
pm2 startup
pm2 start nelson -- --getNeighbors
pm2 save


#
# IOTA/NELSON section end
#

#
# Oyster/Hooknode section start
#

service iota stop

# Install the latest 1.9.3 go
# Hooknode won't compile if you're using v1.9.4 or newer
rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO
curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo

# Comment this out if newer than 1.9.3 becomes supported, see next few lines for your options
yum install -y golang-1.9.3-0.el7.centos
yum versionlock golang-*

# Uncomment these two lines if newer than 1.9.3 becomes supported but not 1.10.x
#goVersionNumber=`yum --showduplicates list golang |grep -oP '1.9\.[0-9].*centos?' | sort |tail -n 1`
#yum install -y golang-$goVersionNumber

# Uncomment this line if 1.10.x ever becomes supported
#yum install -y golang

# Create a user for hooknode and setup go
adduser hooknode

su - hooknode -c "echo \"export GOROOT=/usr/lib/golang\" >> /home/hooknode/.bash_profile"
su - hooknode -c "echo \"export GOPATH=/home/hooknode/go\" >> /home/hooknode/.bash_profile"
su - hooknode -c "echo \"export PATH=/home/hooknode/go/bin:\$PATH\" >> /home/hooknode/.bash_profile"

su - hooknode -c "mkdir -p /home/hooknode/go/src"
su - hooknode -c "mkdir -p /home/hooknode/go/bin"

# Install the go dependancy manager
su - hooknode -c "go get -u github.com/golang/dep/cmd/dep"

# Pull the hooknode repo
su - hooknode -c "mkdir -p /home/hooknode/go/src/github.com/oysterprotocol"
su - hooknode -c "cd /home/hooknode/go/src/github.com/oysterprotocol; git clone https://github.com/oysterprotocol/hooknode.git"
su - hooknode -c "cp /home/hooknode/go/src/github.com/oysterprotocol/hooknode/.env.example /home/hooknode/go/src/github.com/oysterprotocol/hooknode/.env"
su - hooknode -c "cd /home/hooknode/go/src/github.com/oysterprotocol/hooknode/; make install-deps"
su - hooknode -c "cd /home/hooknode/go/src/github.com/oysterprotocol/hooknode/; go build -o ./bin/main.go"

# Setup systemd service
cat <<EOF | tee /lib/systemd/system/hooknode.service
[Unit]
Description=Oyster Hooknode in Golang
After=network.target
[Service]
WorkingDirectory=/home/hooknode/go/src/github.com/oysterprotocol/hooknode
User=hooknode
PrivateDevices=yes
ProtectSystem=full
Type=simple
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=60
ExecStart=/home/hooknode/go/src/github.com/oysterprotocol/hooknode/bin/main.go
SyslogIdentifier=HOOKN
Restart=on-failure
RestartSec=30
[Install]
WantedBy=multi-user.target
Alias=hooknode.service
EOF

# Start service
service hooknode start
systemctl start hooknode.service
systemctl enable hooknode.service

# Start iota again
service iota start


# Open the firewall for incoming connections
firewall-cmd --zone=public --add-port=14265/tcp --permanent
firewall-cmd --zone=public --add-port=14265/udp --permanent
firewall-cmd --zone=public --add-port=14600/udp --permanent
firewall-cmd --zone=public --add-port=15600/tcp --permanent
firewall-cmd --reload


# Get IPs
externalIps="$(dig +short myip.opendns.com @resolver1.opendns.com)"
internalIps="$(hostname -I)"
internalIps="$(echo -e "${internalIps}" | tr -d '[:space:]')"

# Prepare and show confirmation message
echo "Installation complete!"
echo ""
echo "You will now need to open the appropriate ports on your firewall/router:"
echo "Port 14265 - TCP and UDP"
echo "Port 14600 - UDP"
echo "Port 15600 - TCP"
echo ""
echo "This servers internal IP is: $internalIps"
echo "This servers external IP is: $externalIps"
echo ""
echo "Copy/paste the above information and store it some place for reference."
echo "It is recommended you reboot this server to finish installation by running \"shutdown -r now\""
echo ""
echo "Donations are always welcome."
echo "  PRL - 0x89d501e6857318b64FfB09CBE8cC2a3B9D236ED7"
echo "  ETH - 0x3d6448fda5ec668c34d18b602b932d4bd3b1611e"
echo "  BTC - 1M7X411T2FE5uHneRe2bKdkCuCMJjmh1RW"
echo "  LTC - LMqvw577aYh6DQbgefs9zSpQvcVhdchWCU"
echo ""
