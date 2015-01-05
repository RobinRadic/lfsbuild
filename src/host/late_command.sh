#!/bin/bash

# passwordless sudo
echo "%sudo   ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# public ssh key for vagrant user
#mkdir /home/vagrant/.ssh
#wget -O /home/vagrant/.ssh/authorized_keys "https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub"
#chmod 755 /home/vagrant/.ssh
#chmod 644 /home/vagrant/.ssh/authorized_keys
#chown -R vagrant:vagrant /home/vagrant/.ssh

# speed up ssh
echo "UseDNS no" >> /etc/ssh/sshd_config

# Install chef from omnibus
curl -L https://www.getchef.com/chef/install.sh | bash

# display login promt after boot
sed "s/quiet splash//" /etc/default/grub > /tmp/grub
sed "s/GRUB_TIMEOUT=[0-9]/GRUB_TIMEOUT=0/" /tmp/grub > /etc/default/grub
update-grub




# Install node
cd ~/
git clone https://github.com/joyent/node.git
cd node
git checkout v0.11.14
./configure
make -j 6
sudo make -j 6 install

# install npm
curl https://npmjs.org/install.sh | sudo sh


# install global node/npm packages
sudo npm install -g generator-radic bower grunt-cli lodash-cli

cd ..
rm -rf node

# own lfs
#echo "export LFS=/mnt/lfs" > ~/.bashrc
echo "export LFS=/mnt/lfs" > ~/lfs.sh
chmod +x lfs.sh
sudo cp ~/lfs.sh /etc/profile.d/lfs.sh
sudo mkdir /mnt/lfs
sudo chown -R radic:radic /mnt/lfs

# clean up
apt-get clean

# Zero free space to aid VM compression
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY