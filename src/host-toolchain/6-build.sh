#!/bin/bash

. config

SBU=30

f_off="\e[0m" 
f_bold="\e[1m"
f_orange="\e[38;5;202m"   
f_cyan="\e[38;5;75m"
f_green="\e[38;5;82m"


make-check(){
    if [ $runtests -eq 1 ]; then
        make check
    fi
}

generic-install(){
    ./configure --prefix=/tools
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

sbu(){    
    local f_off="\e[0m"
    local f_orange="\e[38;5;202m"    
    local duration=$(php -r "echo $SBU * $1;")
    local minutes=$(php -r "echo round($duration / 60, 1);")
    echo -e "${f_orange}This part will take up around $1 SBU = $duration seconds ($minutes minutes) ${f_off}"
}

pre-build(){
    local pkg=$1
    local tartype=$2
    local sbu=$3
    local diroveride=$4

    clear
    echo -e "${f_cyan}${f_bold} $pkg ${f_off}"
    sbu $sbu
    countdown "Starting in.."
    
    cd $LFS/sources
    
    case $tartype in
        gz) tar -zxvf $pkg.tar.$tartype;;
        bz2) tar -jxvf $pkg.tar.$tartype;;
        xz) tar -Jxvf $pkg.tar.$tartype;;
    esac
    
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
    cd $LFS/sources
 
    if [ -z ${diroveride} ]; then
        rm -rf $pkg
    else 
        rm -rf $diroveride
    fi


    echo -e "${f_green}completed: $pkg ${f_off}"
    echo -e "${f_cyan}${f_bold} ${f_off}"

    countdown "Waiting a bit"
    countdown "Waiting again.."
}

clean-tools(){
    rm -rf $LFS/tools/*
}

c-check(){
    local currdir=$(pwd)
    echo -e "${f_green}${f_bold}SANITY CHECK!${f_off}\n==========\nShould output something like: [Requesting program interpreter: /tools/lib/ld-linux.so.2]\n==============="

    cd ~/
    echo 'main(){}' > dummy.c
    $LFS_TGT-gcc dummy.c
    readelf -l a.out | grep ': /tools'
    echo "================================"
    rm -v dummy.c a.out
    cd ${currdir}
    echo -e "${f_bold}End of sanity check${f_off}"
    countdown "Waiting a bit"
}


54-binutils(){
    pre-build binutils-2.24 bz2 1

    post-build binutils-2.24
}


$*