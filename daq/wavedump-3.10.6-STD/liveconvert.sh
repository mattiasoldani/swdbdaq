#!/bin/bash

# argument 1: run on remote repository (0) or on DAQ machine (1)?
machinedefault=0
MACHINE=${1:-$machinedefault}

# argument 2: erase and redo whole run (0) or keep existing files (1)?
resetdefault=0
RESET=${2:-$resetdefault}

shopt -s "expand_aliases"
source setup.sh

if [ $MACHINE -eq 0 ] ; then
    actualpath=$REMOTEPATH
else
    actualpath=$SYNCPATH
fi

echo "Starting live ROOT file creation"
echo "The data path folder is:"
echo $actualpath
echo "Kill the process to interrupt"
echo "---"

i=0
while true
do

trap "exit" SIGINT

echo "Iteration number $i"
i=$(($i + 1))

#if [ $RESET -eq 0 ] ; then
#    echo "Deleting already created files..."
#    rm -rf "$actualpath/data_root/$run*"
#else
#    echo "Already existing files are kept"
#fi

echo "---"

python pyconv.py $actualpath $RESET

echo "---"

sleep 1

done

