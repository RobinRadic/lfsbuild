#!/tools/bin/bash

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
    countdown "Waiting again.."
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


65-createdir(){
    mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib,mnt,opt}
    mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
    install -dv -m 0750 /root
    install -dv -m 1777 /tmp /var/tmp
    mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
    mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
    mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
    mkdir -v  /usr/libexec
    mkdir -pv /usr/{,local/}share/man/man{1..8}

    case $(uname -m) in
    x86_64) ln -sv lib /lib64
         ln -sv lib /usr/lib64
         ln -sv lib /usr/local/lib64 ;;
    esac

    mkdir -v /var/{log,mail,spool}
    ln -sv /run /var/run
    ln -sv /run/lock /var/lock
    mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}
}

66-essentials-and-symlinks() {
    ln -sv /tools/bin/{bash,cat,echo,pwd,stty} /bin
    ln -sv /tools/bin/perl /usr/bin
    ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
    ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib
    sed 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la
    ln -sv bash /bin/sh
    ln -sv /proc/self/mounts /etc/mtab

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
nogroup:x:99:
users:x:999:
EOF

    exec /tools/bin/bash --login +h

    touch /var/log/{btmp,lastlog,wtmp}
    chgrp -v utmp /var/log/lastlog
    chmod -v 664  /var/log/lastlog
    chmod -v 600  /var/log/btmp

}


67-linux-api() {
    pre-build linux-3.16.2
    make mrproper
    make INSTALL_HDR_PATH=dest headers_install
    find dest/include \( -name .install -o -name ..install.cmd \) -delete
    cp -rv dest/include/* /usr/include
    post-build linux-3.16.2
}

68-man-pages() {
    pre-build man-pages-3.72
    make install
    post-build man-pages-3.72
}


69-glibc() {
    pre-build glibc-2.20

    patch -Np1 -i ../glibc-2.20-fhs-1.patch
    mkdir -v ../glibc-build
    cd ../glibc-build

    ../glibc-2.20/configure    \
        --prefix=/usr          \
        --disable-profile      \
        --enable-kernel=2.6.32 \
        --enable-obsolete-rpc

    make

    touch /etc/ld.so.conf

    make check

    countdown "This test is important! make sure its done ok. check http://www.linuxfromscratch.org/lfs/view/stable/chapter06/glibc.html"

    make install

    cp -v ../glibc-2.20/nscd/nscd.conf /etc/nscd.conf
    mkdir -pv /var/cache/nscd

    mkdir -pv /usr/lib/locale
    localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
    localedef -i de_DE -f ISO-8859-1 de_DE
    localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
    localedef -i de_DE -f UTF-8 de_DE.UTF-8
    localedef -i en_GB -f UTF-8 en_GB.UTF-8
    localedef -i en_HK -f ISO-8859-1 en_HK
    localedef -i en_PH -f ISO-8859-1 en_PH
    localedef -i en_US -f ISO-8859-1 en_US
    localedef -i en_US -f UTF-8 en_US.UTF-8
    localedef -i es_MX -f ISO-8859-1 es_MX
    localedef -i fa_IR -f UTF-8 fa_IR
    localedef -i fr_FR -f ISO-8859-1 fr_FR
    localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
    localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
    localedef -i it_IT -f ISO-8859-1 it_IT
    localedef -i it_IT -f UTF-8 it_IT.UTF-8
    localedef -i ja_JP -f EUC-JP ja_JP
    localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
    localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
    localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
    localedef -i zh_CN -f GB18030 zh_CN.GB18030

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF


tar -xf ../tzdata2014g.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix -y "sh yearistype.sh" ${tz}
    zic -L leapseconds -d $ZONEINFO/right -y "sh yearistype.sh" ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO


cp -v /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF


cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d
rm -rf /sources/glibc-build
    post-build glibc-2.20
}

610-adjust() {
    mv -v /tools/bin/{ld,ld-old}
    mv -v /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}
    mv -v /tools/bin/{ld-new,ld}
    ln -sv /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld
    gcc -dumpspecs | sed -e 's@/tools@@g'                   \
        -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
        -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
        `dirname $(gcc --print-libgcc-file-name)`/specs
    echo 'main(){}' > dummy.c
    cc dummy.c -v -Wl,--verbose &> dummy.log
    readelf -l a.out | grep ': /lib'
    countdown "There should be no errors for above. Should link to: Requesting program interpreter: /lib/ld-linux.so.2"

    grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
    countdown "The output for above command should be: /usr/lib/crt1.o succeeded /usr/lib/crti.o succeeded /usr/lib/crtn.o succeeded"

    grep -B1 '^ /usr/include' dummy.log
    countdown "The output for above command should be: #include <...> search starts here: /usr/include"

    grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
    countdown "The output for above command should be: SEARCH_DIR(/usr/lib) SEARCH_DIR(/lib);"

    grep "/lib.*/libc.so.6 " dummy.log
    countdown "The output for above command should be: attempt to open /lib/libc.so.6 succeeded"


    grep found dummy.log
    countdown "The output for above command should be: found ld-linux.so.2 at /lib/ld-linux.so.2"

    rm -v dummy.c a.out dummy.log
}

611-zlib(){
    pre-build zlib-1.2.8
    ./configure --prefix=/usr
    make
    make-check
    make install
    mv -v /usr/lib/libz.so.* /lib
    ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
    post-build zlib-1.2.8
}

612-file() {
    pre-build file-5.19
    generic-install
    post-build file-5.19
}




613-binutils() {
    pre-build binutils-2.24
    expect -c "spawn ls"
    countdown "The output for above command should be:  spawn ls"

    rm -fv etc/standards.info
    sed -i.bak '/^INFO/s/standards.info //' etc/Makefile.in
    patch -Np1 -i ../binutils-2.24-load_gcc_lto_plugin_by_default-1.patch
    patch -Np1 -i ../binutils-2.24-lto_testsuite-1.patch
    mkdir -v ../binutils-build
    cd ../binutils-build
    ../binutils-2.24/configure --prefix=/usr   \
                               --enable-shared \
                               --disable-werror
    make tooldir=/usr
    make -k check
    countdown "Check if tests pass. Important!"
    countdown "Check if tests pass. Important!"
    make tooldir=/usr install

    rm -rf /sources/binutils-build
    post-build binutils-2.24
}

614-gmp(){
    pre-build gmp-6.0.0a gmp-6.0.0
    ./configure --prefix=/usr \
                --enable-cxx  \
                --docdir=/usr/share/doc/gmp-6.0.0a
    make
    make html
    make check 2>&1 | tee gmp-check-log
    awk '/tests passed/{total+=$2} ; END{print total}' gmp-check-log
    countdown "Check if 188 tests pass. Important!"
    countdown "Check if 188 tests pass. Important!"
    make install
    make install-html
    post-build gmp-6.0.0a gmp-6.0.0
}

615-mpfr(){
    pre-build mpfr-3.1.2
    patch -Np1 -i ../mpfr-3.1.2-upstream_fixes-2.patch
    ./configure --prefix=/usr        \
                --enable-thread-safe \
                --docdir=/usr/share/doc/mpfr-3.1.2
    make
    make html

    make check
    countdown "Check if all tests pass. Important!"
    countdown "Check if all tests pass. Important!"
    make install
    make install-html

    post-build mpfr-3.1.2

}

616-mpc() {
    pre-build mpc-1.0.2
    ./configure --prefix=/usr --docdir=/usr/share/doc/mpc-1.0.2
    make
    make html
    make-check
    make install
    make install-html
    post-build mpc-1.0.2
}

617-gcc(){
    pre-build gcc-4.9.1
    sed -i 's/if \((code.*))\)/if (\1 \&\& \!DEBUG_INSN_P (insn))/' gcc/sched-deps.c
    patch -Np1 -i ../gcc-4.9.1-upstream_fixes-1.patch

    mkdir -v ../gcc-build
    cd ../gcc-build

    SED=sed                       \
    ../gcc-4.9.1/configure        \
         --prefix=/usr            \
         --enable-languages=c,c++ \
         --disable-multilib       \
         --disable-bootstrap      \
         --with-system-zlib

     make
     ulimit -s 32768
     make -k check
     ../gcc-4.9.1/contrib/test_summary
     ../gcc-4.9.1/contrib/test_summary | grep -A7 Summ
     echo -e "${f_cyan} Results can be compared with those located at http://www.linuxfromscratch.org/lfs/build-logs/7.6/ and http://gcc.gnu.org/ml/gcc-testresults/.${f_off}"
     echo "Press any key to continue"
     read

     make install
     ln -sv ../usr/bin/cpp /lib
     ln -sv gcc /usr/bin/cc

    install -v -dm755 /usr/lib/bfd-plugins
    ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/4.9.1/liblto_plugin.so /usr/lib/bfd-plugins/

    echo 'main(){}' > dummy.c
    cc dummy.c -v -Wl,--verbose &> dummy.log
    readelf -l a.out | grep ': /lib'
    countdown "Above command hsould return: [Requesting program interpreter: /lib/ld-linux.so.2]"

    grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
    countdown "Above command should return: \n /usr/lib/gcc/i686-pc-linux-gnu/4.9.1/../../../crt1.o succeeded \n /usr/lib/gcc/i686-pc-linux-gnu/4.9.1/../../../crti.o succeeded \n /usr/lib/gcc/i686-pc-linux-gnu/4.9.1/../../../crtn.o succeeded"

    grep -B4 '^ /usr/include' dummy.log
    countdown "Above command should return: #include <...> search starts here:\n /usr/lib/gcc/i686-pc-linux-gnu/4.9.1/include\n /usr/local/include\n /usr/lib/gcc/i686-pc-linux-gnu/4.9.1/include-fixed\n /usr/include"

    grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
    countdown "Above command should return: \n SEARCH_DIR(/usr/x86_64-unknown-linux-gnu/lib64)\nSEARCH_DIR(/usr/local/lib64)\nSEARCH_DIR(/lib64)\nSEARCH_DIR(/usr/lib64)\nSEARCH_DIR(/usr/x86_64-unknown-linux-gnu/lib)\nSEARCH_DIR(/usr/local/lib)\nSEARCH_DIR(/lib)\nSEARCH_DIR(/usr/lib);"

    grep "/lib.*/libc.so.6 " dummy.log
    countdown "Above command should return: attempt to open /lib/libc.so.6 succeeded"

    grep found dummy.log
    countdown "Above command should return: found ld-linux.so.2 at /lib/ld-linux.so.2"

    rm -v dummy.c a.out dummy.log
    mkdir -pv /usr/share/gdb/auto-load/usr/lib
    mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

    rm -rf /sources/gcc-build
    post-build gcc-4.9.1
}








$*