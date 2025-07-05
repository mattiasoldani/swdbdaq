#!/bin/bash

shopt -s "expand_aliases"
source setup.sh

echo "Starting live sync between local:"
echo $LOCALDATAPATH
echo "and remote (is it mounted?):"
echo $SYNCDATAPATH
echo "Kill the process to interrupt"
echo "---"

i=0
while true
do

trap "exit" SIGINT

echo "Iteration number $i..."
i=$(($i + 1))

datasync > /dev/null

echo "---"

echo "Done"

echo "---"

sleep 1

done
