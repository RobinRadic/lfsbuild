#!/bin/bash
. config

mkdir -p $LFS >/dev/null 2>&1
sudo mount -v -t ext4 ${tgtdisk}2 $LFS
sudo mkdir -p $LFS/boot >/dev/null 2>&1
sudo mount -v -t ext4 ${tgtdisk}1 $LFS/boot
