#!/bin/bash
. config

SBU=30

f_off="\e[0m"
f_bold="\e[1m"
f_orange="\e[38;5;202m"
f_cyan="\e[38;5;75m"
f_green="\e[38;5;82m"

runtests=0

make-check(){
    if [ $runtests -eq 1 ]; then
        make check
    fi
}

generic-install(){
    ./configure --prefix=/usr
    make
    make-check
    make install
}

countdown(){
    local title=$1

    echo -e "${f_cyan}${f_bold}${title}${f_off}\n============"
    echo -e "${f_orange}${f_bold}3${f_off}"
    sleep 1
    echo -e "${f_cyan}${f_bold}2${f_off}"
    sleep 1
    echo -e "${f_green}${f_bold}1${f_off}"
    sleep 1    
}



pre-build(){
    local pkg=$1
    local diroveride=$2

    clear
    echo -e "${f_cyan}${f_bold} $pkg ${f_off}"

    countdown "Starting in.."
    
    cd /sources


    tar -xvf $pkg.tar.*

    if [ -z ${diroveride} ]; then 
        echo -e "${f_cyan}\e[1m CD PKG: $pkg ${f_off}"
        cd $pkg
    else 
        echo -e "${f_cyan}\e[1m CD DIROVERIDE: $diroveride ${f_off}"
        cd $diroveride
    fi
    
}

post-build(){
    local pkg=$1
    local diroveride=$2
    cd /sources
 
    if [ -z ${diroveride} ]; then
        rm -rf $pkg
    else 
        rm -rf $diroveride
    fi


    echo -e "${f_green}completed: $pkg ${f_off}"
    echo -e "${f_cyan}${f_bold} ${f_off}"

    countdown "Waiting a bit"
}

c-check(){
    local currdir=$(pwd)
    echo -e "${f_green}${f_bold}SANITY CHECK!${f_off}\n==========\nShould output something like: [Requesting program interpreter: /tools/lib/ld-linux.so.2]\n==============="

    cd /root
    echo 'main(){}' > dummy.c
    cc dummy.c -v -Wl,--verbose &> dummy.log
    readelf -l a.out | grep ': /lib'
    echo "================================"
    rm -v dummy.c a.out
    cd ${currdir}
    echo -e "${f_bold}End of sanity check${f_off}"
    countdown "Waiting a bit"
}


772-lfs-bootscripts(){
    pre-build lfs-bootscripts-20140815
    make install
    post-build lfs-bootscripts-20140815
}




$*