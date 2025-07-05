#!/bin/bash

# argument: the DAQ software version, e.g. STD or MOD
verdefault=MOD
VER=${1:-$verdefault}

source $DAQPATH/setup.sh

cwd=$PWD

cd $DAQPATH/wavedump-3.10.6-$VER/
autoreconf -f -i
make clean
./configure
make
sudo make install
cd $cwd
