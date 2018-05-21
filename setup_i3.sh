#how to set up i3 instances

#partition the instance stores:
#show all partition tables
fdisk -l
#search for the /nvme0n1 or /nvme1n1, which won't have any partitions
#open fdisk in that volume, for example
fdisk /dev/nvme0n1
#then just write n, go along with all default options and then write "w" at the end to write all changes
#now we need to configure the filesystem
#use lsblk to see partitions
lsblk
#grab the partition names in the instance stores (eg: nvme0n1p1)
#format new partitions as ext4
mkfs -t ext4 /dev/nvme0n1p1
#make new dir to mount the partition on
mkdir /storage
mount /dev/nvme0n1p1 /storage