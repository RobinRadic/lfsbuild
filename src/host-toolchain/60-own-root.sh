#!/bin/bash

sudo chown -R root:root $LFS/tools
sudo cp /home/lfs/.bashrc /root/.bashrc

echo "Done! Exit lfs user and login with root"