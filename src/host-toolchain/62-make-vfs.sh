#!/bin/bash


## ADDED VAGRANT ASWELL
mkdir -pv $LFS/{dev,proc,sys,run,vagrant}
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3

. 62-mount-vfs.sh

if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

echo "done"