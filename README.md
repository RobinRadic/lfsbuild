# lfsbuild

## Requirements
- VirtualBox
- Vagrant
- 7z
- curl

## Getting started
```bash
git clone http://github.com/robinradic/lfsbuild
cd lfsbuild
./lfsbuilder make-installer
./lfsbuilder make-host
./lfsbuilder start-host

# Should be in the vm now
cd /vagrant
./10-makedisk.sh
./20-download-packages.sh
./30-add-lfs-user.sh
./40-login.sh

# should be logged in as lfs
cd /vagrant
./41-first-login.sh
./5-build.sh <what to build>
# ./5-build.sh build-54-to-57
# ./5-build.sh build-58-to-510
# ./5-build.sh build-511-to-518
# ./5-build.sh build-519-to-534
# OR ./5-build.sh build-all

```


## todo
```bash
# after build all
sudo chown -R root:root $LFS/tools
sudo cp /home/lfs/.bashrc /root/.bashrc

# exit user lfs & login as root
exit
sudo su

# 6.2
mkdir -pv $LFS/{dev,proc,sys,run}
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3
mount -v --bind /dev $LFS/dev
mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
```