#!/bin/bash
sudo groupadd lfs
sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs
# add lfs user to sudo group
sudo usermod -a -G sudo lfs
sudo passwd lfs

sudo chown -v lfs $LFS/tools
sudo chown -v lfs $LFS/sources
