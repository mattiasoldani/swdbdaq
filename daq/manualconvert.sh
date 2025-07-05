#!/bin/bash

# argument 1: erase and redo whole run (0) or keep existing files (1)?
resetdefault=0
RESET=${1:-$resetdefault}

#argument 2: if it is not 0, override runarray and run on the latest file
latestdefault=0
LATEST=${2:-$latestdefault}

shopt -s "expand_aliases"
source setup.sh

echo "Starting ROOT file creation on manually selected runs"
echo "The input data path folder is:"
echo $ROOTCREATEINPATH
echo "The output data path folder is:"
echo $ROOTCREATEOUTPATH
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
1728985388
1729031164
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

    echo "---"

    # work on the run - core operations are performed in here
    if [ $LATEST -eq 0 ] ; then
        python pyconv.py $ROOTCREATEINPATH $ROOTCREATEOUTPATH $RESET $run
    else
        python pyconv.py $ROOTCREATEINPATH $ROOTCREATEOUTPATH $RESET
    fi

    echo "---"
    
done

echo "Done!"
