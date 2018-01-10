#!/bin/bash
# http://www.nongnu.org/avr-libc/user-manual/install_tools.html

TIME_START=$(date +%s)
sleep 1
# Output locations for built toolchains

if [ -z $PREFIX ]; then
    export PREFIX="$(pwd)/output"
fi

echo "Prefix: $PREFIX"
sleep 5

# For optimum compile time this should generally be set to the number of CPU cores your machine has
JOBCOUNT=9

# Stop on errors
set -e

export PATH="$PATH:$PREFIX/bin"
NAME_BINUTILS="binutils-2.28"
NAME_GCC="gcc-5.4.0"
NAME_LIBC="avr-libc-2.0.0"

OPTS_BINUTILS="
    --target=avr
    --disable-nls
"

OPTS_GCC="--target=avr --enable-languages=c,c++ --disable-nls --disable-libssp --with-dwarf2"


# ---------------- Download ----------------------------
echo "Downloading sources..."
rm -f $NAME_BINUTILS.tar.bz2
rm -rf $NAME_BINUTILS/
wget ftp://ftp.mirrorservice.org/sites/ftp.gnu.org/gnu/binutils/$NAME_BINUTILS.tar.bz2
bunzip2 -c $NAME_BINUTILS.tar.bz2 | tar xf -

rm -f $NAME_GCC.tar.bz2
rm -rf $NAME_GCC/
wget ftp://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/$NAME_GCC/$NAME_GCC.tar.bz2
bunzip2 -c $NAME_GCC.tar.bz2 | tar xf -

rm -f $NAME_LIBC.tar.bz2
rm -rf $NAME_LIBC/
wget ftp://ftp.mirrorservice.org/sites/download.savannah.gnu.org/releases/avr-libc/$NAME_LIBC.tar.bz2
bunzip2 -c $NAME_LIBC.tar.bz2 | tar xf -


confMake()
{
    ../configure --prefix=$PREFIX $1 $2 $3 $4
    make -j $JOBCOUNT
    make install-strip
}

## ---------------- Binutils ----------------------------
echo "Making Binutils..."
mkdir -p $NAME_BINUTILS/obj-avr
cd $NAME_BINUTILS/obj-avr
confMake "$OPTS_BINUTILS"
cd ../../

## ---------------- GCC ----------------------------
echo "Making GCC..."
mkdir -p $NAME_GCC/obj-avr
cd $NAME_GCC
./contrib/download_prerequisites
wget gajoch.pl/gregg/avr/gcc-patch.txt
patch -p1 < gcc-patch.txt
cd obj-avr
confMake "$OPTS_GCC"
cd ../../


# ---------------- AVR-LibC ----------------------------
echo "Making AVR-LibC..."
mkdir -p $NAME_LIBC/obj-avr
cd $NAME_LIBC/obj-avr
build=$(../config.guess)
confMake --host=avr --build=${build}
cd ../../


## ---------------- LIBSTDC++v3 ----------------------------
echo "Making GCC..."
cd $NAME_GCC
rm -rf obj-avr
mkdir -p obj-avr
cd obj-avr
OPTS_LIBSTD="--enable-libstdcxx --disable-sjlj-exceptions"
confMake "$OPTS_GCC" "$OPTS_LIBSTD"
cd ../



TIME_END=$(date +%s)
TIME_RUN=$(($TIME_END - $TIME_START))

echo ""
echo "Done in $TIME_RUN seconds"

exit 0
