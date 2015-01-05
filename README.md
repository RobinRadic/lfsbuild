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

./6-build.sh <what to build>
# figureitout
```

