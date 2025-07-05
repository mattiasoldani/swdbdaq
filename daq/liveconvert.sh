#!/bin/bash

# argument 1: erase and redo whole run (0) or keep existing files (1)?
resetdefault=0
RESET=${1:-$resetdefault}

shopt -s "expand_aliases"
source setup.sh

echo "Starting live ROOT file creation"
echo "The input data path folder is:"
echo $ROOTCREATEINPATH
echo "The output data path folder is:"
echo $ROOTCREATEOUTPATH
echo "Kill the process to interrupt"
echo "---"

i=0
while true
do

trap "exit" SIGINT

echo "Iteration number $i"
i=$(($i + 1))

echo "---"

python pyconv.py $ROOTCREATEINPATH $ROOTCREATEOUTPATH $RESET

echo "---"

sleep 1

done

