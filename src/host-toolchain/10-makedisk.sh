#!/bin/bash
. config

sudo parted ${tgtdisk} mklabel msdos
sudo parted ${tgtdisk} mkpart primary 0.1 500
sudo parted ${tgtdisk} mkpart primary 501 35000
sudo parted ${tgtdisk} mkpart primary 35001 39500
sudo mkfs -v -t ext4 ${tgtdisk}1
sudo mkfs -v -t ext4 ${tgtdisk}2
sudo mkswap ${tgtdisk}3
sudo parted ${tgtdisk} set 1 boot on

. 10-mountdisks.sh

sudo mkdir -v $LFS/sources
sudo chmod -v a+wt $LFS/sources
sudo mkdir -v $LFS/tools
sudo ln -sv $LFS/tools /