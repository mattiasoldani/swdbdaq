#!/bin/bash

# argument 1: run on remote repository (0) or on DAQ machine (1)?
machinedefault=0
MACHINE=${1:-$machinedefault}

# argument 2: erase and redo whole run (0) or keep existing files (1)?
resetdefault=0
RESET=${2:-$resetdefault}

#argument 3: if it is not 0, override runarray and run on the latest file
latestdefault=0
LATEST=${3:-$latestdefault}

shopt -s "expand_aliases"
source setup.sh
    
if [ $MACHINE -eq 0 ] ; then
    actualpath=$REMOTEPATH
else
    actualpath=$SYNCPATH
fi

echo "Starting ROOT file creation on manually selected runs"
echo "The data path folder is:"
echo $actualpath
echo "Kill the process to interrupt"
echo "---"

# run list (set)
# ---------------
# to manually select runs:
# runarray=(  # set run numbers here
# 100000 100001 100002
# )
# alternatively, to process all runs, you can try: 
# RUNSTRL=1
# RUNSTRR=10
# runarray=(
# $(ls -1 $actualpath/data_ascii/. | cut -c$RUNSTRL-$RUNSTRR | sort -r | uniq)
# )
# ---------------
runarray=(  # set run numbers here
1710327192
1710328249
1710329716
1710335204
1710345661
1710348759
1710352655
1710354655
1710355035
1710405904
)

# if requested, overwrite runarray to run on the latest file
if [ $LATEST -ne 0 ] ; then
    runarray=(-1)
fi

# loop on all the requested runs
for run in "${runarray[@]}" ; do

    if [ $LATEST -eq 0 ] ; then
        echo "Iteration on run $run"
    else
        echo "Iteration on latest run"
    fi
    
    #if [ $RESET -eq 0 ] ; then
    #    echo "Deleting already created files..."
    #    rm -rf "$actualpath/data_root/$run*"
    #else
    #    echo "Already existing files are kept"
    #fi

    echo "---"

    # work on the run - core operations are performed in here
    if [ $LATEST -eq 0 ] ; then
        python pyconv.py $actualpath $RESET $run
    else
        python pyconv.py $actualpath $RESET
    fi

    echo "---"
    
done

echo "Done!"
