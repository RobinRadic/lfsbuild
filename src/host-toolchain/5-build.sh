#!/bin/bash

. config
# ./6-build.sh [TASK]

# For each package:
# Using the tar program, extract the package to be built. In Chapter 5, ensure you are the lfs user when extracting the package.
# Change to the directory created when the package was extracted.
# Follow the book's instructions for building the package.
# Change back to the sources directory.
# Delete the extracted source directory and any <package>-build directories that were created in the build process unless instructed otherwise.

#tar: tar -xvf
#tar.gz: tar -zxvf 
#tar.bz2: tar -jxvf
#tar.xz: tar -Jxvf

SBU=30           # 30 seconds = 1 sbu when using -j 6 on my system



    
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
    
    local f_off="\e[0m" 
    local f_bold="\e[1m"
    local f_orange="\e[38;5;202m"   
    local f_cyan="\e[38;5;75m"
    local f_green="\e[38;5;82m"
    
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
    local f_off="\e[0m"
    local f_bold="\e[1m"
    local f_cyan="\e[38;5;75m"
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
    local f_off="\e[0m"
    local f_green="\e[38;5;82m"
    local f_cyan="\e[38;5;75m"
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

lfs-own(){
    sudo chown -R lfs:lfs $LFS
}

root-own(){
    sudo chown -R root:root $LFS
}


54-binutils(){
    pre-build binutils-2.24 bz2 1
    
    mkdir -v ../binutils-build
    cd ../binutils-build
    #time { ../binutils-2.24/configure --prefix=/tools --with-sysroot=$LFS --with-lib-path=/tools/lib --target=$LFS_TGT --disable-nls --disable-werror && make && mkdir -v /tools/lib && ln -sv lib /tools/lib64 && make install; }
    
    ../binutils-2.24/configure     \
        --prefix=/tools            \
        --with-sysroot=$LFS        \
        --with-lib-path=/tools/lib \
        --target=$LFS_TGT          \
        --disable-nls              \
        --disable-werror
        
    make
    case $(uname -m) in
        x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
    esac
    make install

    rm -rf $LFS/sources/binutils-build
    # --prefix=/tools: #This tells the configure script to prepare to install the Binutils programs in the /tools directory.
    # --with-sysroot=$LFS: For cross compilation, this tells the build system to look in $LFS for the target system libraries as needed.
    # --with-lib-path=/tools/lib: This specifies which library path the linker should be configured to use.
    # --target=$LFS_TGT: Because the machine description in the LFS_TGT variable is slightly different than the value returned by the config.guess script, this switch will tell the configure script to adjust Binutil's build system for building a cross linker.
    # --disable-nls: This disables internationalization as i18n is not needed for the temporary tools.
    # --disable-werror: This prevents the build from stopping in the event that there are warnings from the host's compiler.
    post-build binutils-2.24
}

55-gcc(){
    pre-build gcc-4.9.1 bz2 7.4
    tar -xf ../mpfr-3.1.2.tar.xz
    mv -v mpfr-3.1.2 mpfr
    tar -xf ../gmp-6.0.0a.tar.xz
    mv -v gmp-6.0.0 gmp
    tar -xf ../mpc-1.0.2.tar.gz
    mv -v mpc-1.0.2 mpc
    
    #The following command will change the location of GCC's default dynamic linker to use the one installed in /tools. It also removes /usr/include from GCC's include search path. Issue:
for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

    #GCC doesn't detect stack protection correctly, which causes problems for the build of Glibc-2.20, so fix that by issuing the following command:
    sed -i '/k prot/agcc_cv_libc_provides_ssp=yes' gcc/configure

    #Also fix a problem identified upstream:
    sed -i 's/if \((code.*))\)/if (\1 \&\& \!DEBUG_INSN_P (insn))/' gcc/sched-deps.c

    mkdir -v ../gcc-build
    cd ../gcc-build
    ../gcc-4.9.1/configure                               \
        --target=$LFS_TGT                                \
        --prefix=/tools                                  \
        --with-sysroot=$LFS                              \
        --with-newlib                                    \
        --without-headers                                \
        --with-local-prefix=/tools                       \
        --with-native-system-header-dir=/tools/include   \
        --disable-nls                                    \
        --disable-shared                                 \
        --disable-multilib                               \
        --disable-decimal-float                          \
        --disable-threads                                \
        --disable-libatomic                              \
        --disable-libgomp                                \
        --disable-libitm                                 \
        --disable-libquadmath                            \
        --disable-libsanitizer                           \
        --disable-libssp                                 \
        --disable-libvtv                                 \
        --disable-libcilkrts                             \
        --disable-libstdc++-v3                           \
        --enable-languages=c,c++

    make
    make install

    rm -rf $LFS/sources/gcc-build
    post-build gcc-4.9.1
}

56-linux(){
    pre-build linux-3.16.2 xz 0.1
    make mrproper
    make INSTALL_HDR_PATH=dest headers_install
    mkdir $LFS/tools/include
    cp -rv dest/include/* $LFS/tools/include
    post-build linux-3.16.2 
}

57-glibc(){
    pre-build glibc-2.20 xz 5
    
    if [ ! -r /usr/include/rpc/types.h ]; then
        su -c 'mkdir -pv /usr/include/rpc'
        su -c 'cp -v sunrpc/rpc/*.h /usr/include/rpc'
    fi
    
    mkdir -v ../glibc-build
    cd ../glibc-build
    
    ../glibc-2.20/configure                             \
      --prefix=/tools                               \
      --host=$LFS_TGT                               \
      --build=$(../glibc-2.20/scripts/config.guess) \
      --disable-profile                             \
      --enable-kernel=2.6.32                        \
      --with-headers=/tools/include                 \
      libc_cv_forced_unwind=yes                     \
      libc_cv_ctors_header=yes                      \
      libc_cv_c_cleanup=yes
    
    make
    make install

    rm -rf $LFS/sources/glibc-build
    post-build glibc-2.20 
    c-check  
}

build-54-to-57(){
    54-binutils
    sleep 1
    55-gcc
    sleep 1
    56-linux
    sleep 1
    57-glibc
}


58-libstdc(){
    pre-build gcc-4.9.1 bz2 0.4
    mkdir -pv ../gcc-build
    cd ../gcc-build
    ../gcc-4.9.1/libstdc++-v3/configure \
        --host=$LFS_TGT                 \
        --prefix=/tools                 \
        --disable-multilib              \
        --disable-shared                \
        --disable-nls                   \
        --disable-libstdcxx-threads     \
        --disable-libstdcxx-pch         \
        --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/4.9.1
    make
    make install

    rm -rf $LFS/sources/gcc-build
    post-build gcc-4.9.1 
}

59-binutils(){
    pre-build binutils-2.24 bz2 1.1
    mkdir -v ../binutils-build
    cd ../binutils-build
    CC=$LFS_TGT-gcc                \
    AR=$LFS_TGT-ar                 \
    RANLIB=$LFS_TGT-ranlib         \
    ../binutils-2.24/configure     \
        --prefix=/tools            \
        --disable-nls              \
        --disable-werror           \
        --with-lib-path=/tools/lib \
        --with-sysroot
    make
    make install
    
    # Now prepare the linker for the “Re-adjusting” phase in the next chapter:
    make -C ld clean
    make -C ld LIB_PATH=/usr/lib:/lib
    cp -v ld/ld-new /tools/bin

    rm -rf $LFS/sources/binutils-build
    post-build binutils-2.24
}

510-gcc(){
    pre-build gcc-4.9.1 bz2 9.8
    
   cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h
  
for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

tar -xf ../mpfr-3.1.2.tar.xz
mv -v mpfr-3.1.2 mpfr
tar -xf ../gmp-6.0.0a.tar.xz
mv -v gmp-6.0.0 gmp
tar -xf ../mpc-1.0.2.tar.gz
mv -v mpc-1.0.2 mpc

sed -i 's/if \((code.*))\)/if (\1 \&\& \!DEBUG_INSN_P (insn))/' gcc/sched-deps.c

mkdir -v ../gcc-build
cd ../gcc-build

CC=$LFS_TGT-gcc                                      \
CXX=$LFS_TGT-g++                                     \
AR=$LFS_TGT-ar                                       \
RANLIB=$LFS_TGT-ranlib                               \
../gcc-4.9.1/configure                               \
    --prefix=/tools                                  \
    --with-local-prefix=/tools                       \
    --with-native-system-header-dir=/tools/include   \
    --enable-languages=c,c++                         \
    --disable-libstdcxx-pch                          \
    --disable-multilib                               \
    --disable-bootstrap                              \
    --disable-libgomp
    
    make
    make install
    
    ln -sv gcc /tools/bin/cc

    rm -rf $LFS/sources/gcc-build
    post-build gcc-4.9.1
    c-check  
}

build-58-to-510(){
    58-libstdc
    sleep 1
    59-binutils
    sleep 1
    510-gcc
}


511-tcl(){
    pre-build tcl8.6.2-src gz 1 tcl8.6.2
    
    cd unix
    ./configure --prefix=/tools
    make

    # Run test suite
   # TZ=UTC make test
    
    # Then install
    make install

    # Make the installed library writable so debugging symbols can be removed later:
    chmod -v u+w /tools/lib/libtcl8.6.so

    #Install Tcl's headers. The next package, Expect, requires them to build.
    make install-private-headers

    #Now make a necessary symbolic link:
    ln -sv tclsh8.6 /tools/bin/tclsh
    
}

512-expect(){
    pre-build expect5.45 gz 0.1
    
    cp -v configure{,.orig}
    sed 's:/usr/local/bin:/bin:' configure.orig > configure
   
   
    ./configure --prefix=/tools \
        --with-tcl=/tools/lib \
        --with-tclinclude=/tools/include
        
    make
  # make test
    make SCRIPTS="" install
            
    post-build expect5.45
}

513-dejagnu(){
    pre-build dejagnu-1.5.1 gz 0.1
    ./configure --prefix=/tools
    make install
    make-check
    post-build dejagnu-1.5.1
}

514-check(){
    pre-build check-0.9.14 gz 1
    PKG_CONFIG= ./configure --prefix=/tools
    make
    make-check
    make install
    post-build check-0.9.14
}

515-ncurses(){
    pre-build ncurses-5.9 gz 0.6
    
    ./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite
            
    make
    make install
    
    post-build ncurses-5.9
}

516-bash(){
    pre-build bash-4.3 gz 0.4
    
    ./configure --prefix=/tools --without-bash-malloc
    make
    #make tests
    make install
    ln -sv bash  /tools/bin/sh
    
    post-build bash-4.3
}

517-bzip2(){
    pre-build bzip2-1.0.6 gz 1
    make
    make PREFIX=/tools install
    post-build bzip2-1.0.6
}

518-coreutils(){
    pre-build coreutils-8.23 xz 1
    ./configure --prefix=/tools --enable-install-program=hostname
    make
    #make RUN_EXPENSIVE_TESTS=yes check
    make install
    post-build coreutils-8.23
}

build-511-to-518(){
    511-tcl
    sleep 1
    512-expect
    sleep 1
    513-dejagnu
    sleep 1
    514-check
    sleep 1
    515-ncurses
    sleep 1
    516-bash
    sleep 1
    517-bzip2
    sleep 1
    518-coreutils
}


519-diffutils(){
    pre-build diffutils-3.3 xz 1
    generic-install
    post-build diffutils-3.3
}

520-file(){
    pre-build file-5.19 gz 1
    generic-install
    post-build file-5.19
}

521-findutils(){
    pre-build findutils-4.4.2 gz 1
    generic-install    
    post-build findutils-4.4.2
}

522-gawk(){
    pre-build gawk-4.1.1 xz 1
    generic-install
    post-build gawk-4.1.1
}

523-gettext(){
    pre-build gettext-0.19.2 xz 1
    cd gettext-tools
    EMACS="no" ./configure --prefix=/tools --disable-shared
    
    make -C gnulib-lib
    make -C src msgfmt
    make -C src msgmerge
    make -C src xgettext
    cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin
    
    post-build gettext-0.19.2
}

524-grep(){
    pre-build grep-2.20 xz 1
    generic-install    
    post-build grep-2.20
}

525-gzip(){
    pre-build gzip-1.6 xz 1
    generic-install
    post-build gzip-1.6
}

526-m4(){
    pre-build m4-1.4.17 xz 1
    generic-install
    post-build m4-1.4.17
}

527-make(){
    pre-build make-4.0 bz2 1
    ./configure --prefix=/tools --without-guile
    make
    make-check
    make install
    post-build make-4.0
}

528-patch(){
    pre-build patch-2.7.1 xz 1
    generic-install
    post-build patch-2.7.1
}

529-perl(){
    pre-build perl-5.20.0 bz2 1
    sh Configure -des -Dprefix=/tools -Dlibs=-lm
    make
    cp -v perl cpan/podlators/pod2man /tools/bin
    mkdir -pv /tools/lib/perl5/5.20.0
    cp -Rv lib/* /tools/lib/perl5/5.20.0
    post-build perl-5.20.0
}

530-sed(){
    pre-build sed-4.2.2 bz2 0.1
    generic-install
    post-build sed-4.2.2
}

531-tar(){
    pre-build tar-1.28 xz 1
    generic-install
    post-build tar-1.28
}

532-texinfo(){
    pre-build texinfo-5.2 xz 1
    generic-install
    post-build texinfo-5.2
}

533-util-linux(){
    pre-build util-linux-2.25.1 xz 1
    ./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            PKG_CONFIG=""
    make
    make install
    post-build util-linux-2.25.1
}

534-xz(){
    pre-build xz-5.0.5 xz 1
    generic-install
    post-build xz-5.0.5
}

build-519-to-534(){
    519-diffutils
    sleep 1
    520-file
    sleep 1
    521-findutils
    sleep 1
    522-gawk
    sleep 1
    523-gettext
    sleep 1
    524-grep
    sleep 1
    525-gzip
    sleep 1
    526-m4
    sleep 1
    527-make
    sleep 1
    528-patch
    sleep 1
    529-perl
    sleep 1
    530-sed
    sleep 1
    531-tar
    sleep 1
    532-texinfo
    sleep 1
    533-util-linux
    sleep 1
    534-xz
}

535-optional-stripping(){
    # The executables and libraries built so far contain about 70 MB of unneeded debugging symbols. Remove those symbols with:
    strip --strip-debug /tools/lib/*
    /usr/bin/strip --strip-unneeded /tools/{,s}bin/*

    # To save more, remove the documentation. Requires first param to be 1
    if [ $1 -eq 1 ]; then
        rm -rf /tools/{,share}/{info,man,doc}
    fi
}

build-all(){
    build-54-to-57
    build-58-to-510
    build-511-to-518
    build-519-to-534
    clean-tools
}

$*