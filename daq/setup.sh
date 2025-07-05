#!/bin/bash

NAMEDAQ=swdbdaq
export DAQPATH=$HOME/$NAMEDAQ  # <--- set DAQ master path (dedicated sub-paths below)
export CONFFILE=$DAQPATH/conf/daqnow.txt  # <--- set DAQ configuration file
export LOCALDATAPATH=$DAQPATH/rawdata

NAMESYNCDAQ=daq
export SYNCPATH=$HOME/eos_space_temp  # <--- set sync destination master path (dedicated sub-paths below)
export SYNCDAQPATH=$SYNCPATH/$NAMESYNCDAQ
export SYNCDATAPATH=$SYNCPATH/data_ascii
export REMOTEUSER=msoldani@lxplus.cern.ch  # <--- set the remote repo account here
export REMOTEPATH=/eos/experiment/nanocal/misc_dev/24_10_daq_release  # <--- set the remote repo path (to be mounted in SYNCPATH)
export REMOTEDAQPATH=$REMOTEPATH/$NAMESYNCDAQ

PYENVNAME=${NAMEDAQ}_pyenv
export ROOTCREATEINPATH=$REMOTEPATH/data_ascii  # <--- set the input path for ASCII to ROOT conversion
export ROOTCREATEOUTPATH=$REMOTEPATH/data_root/splitted  # <--- set the output path for ASCII to ROOT conversion

echo "**********************"
echo "     MATTIA'S DAQ     "
echo "**********************"

echo "The DAQ path is:"
echo $DAQPATH

if [ -d $LOCALDATAPATH ] ; then
    echo "Directory for raw data ($LOCALDATAPATH) already present"
else
    mkdir -p $LOCALDATAPATH
    echo "Created directory for raw data ($LOCALDATAPATH)"
fi

echo "---"

echo "The default configuration file is:"
echo $CONFFILE

echo "---"

alias recompiledaq="source $DAQPATH/recompiledaq.sh"

echo "The DAQ software can be (re)compiled with the command 'recompiledaq'"

echo "---"

echo "The sync destination remote repo is:"
echo $REMOTEUSER:$REMOTEPATH
echo "It should be mounted ('mountsync') in:"
echo $SYNCPATH
echo "(Have you mounted it?)"

echo "---"

daqstart () { wavedump ${1:-$CONFFILE}; }
echo "Run the DAQ with the command 'daqstart' (followed by custom conf. file if needed)"

echo "---"

alias mountsync="sshfs $REMOTEUSER:$REMOTEPATH $SYNCPATH"
alias daqsync="rsync -avW --update --exclude 'rawdata' --exclude $PYENVNAME -e 'ssh -T -c arcfour -o Compression=no -x' $DAQPATH/ $SYNCDAQPATH"
alias datasync="rsync -avW -e 'ssh -T -c arcfour -o Compression=no -x' $LOCALDATAPATH/ $SYNCDATAPATH"
alias daqsyncback="rsync -avW --update --exclude 'rawdata' --exclude $PYENVNAME -e 'ssh -T -c arcfour -o Compression=no -x' $SYNCDAQPATH/ $DAQPATH"
#alias livesync="source $DAQPATH/livesync.sh"

echo "Mount the remote repo directory with the command 'mountsync'"
echo "Manually sync the DAQ program (data excluded) to the sync space with the command 'daqsync'"
echo "Can also sync the DAQ program back from the sync space with the command 'daqsyncback'"
echo "Manually sync the data to the sync space with the command 'datasync'"
echo "Continuously sync the data to the sync space with the script $DAQPATH/livesync.sh"
#echo "Continuously sync the data to the sync space with the command 'livesync'"

echo "---"

#liveconvert () {
#    if [ ${1:-0} -eq 0 ] ; then
#        EXEPATH=$REMOTEDAQPATH
#    else
#        EXEPATH=$DAQPATH
#    fi
#    source $EXEPATH/liveconvert.sh ${2:-0}
#}
manualconvert () {
    if [ ${1:-0} -eq 0 ] ; then
        EXEPATH=$REMOTEDAQPATH
    else
        EXEPATH=$DAQPATH
    fi
    source $EXEPATH/manualconvert.sh ${2:-0} ${3:-0}
}
pyenvact () {
    local HERE=$(pwd)
    source ${1:-$HERE}/$PYENVNAME/bin/activate
}
pyenvremake () {
    local HERE=$(pwd)
    local INSTALLPATH=${1:-$HERE}
    echo "Installing in $INSTALLPATH..."
    if [ -d $INSTALLPATH/$PYENVNAME ] ; then
        echo "First, removing existing environment path $INSTALLPATH/$PYENVNAME"
        read -p "Are you sure? Type 1: " YES
        if  [ $YES -eq 1 ] ; then
            rm -r $INSTALLPATH/$PYENVNAME
        fi
    fi
    echo "---"
    cd $INSTALLPATH
    python3 -m venv $PYENVNAME
    cd $HERE
    pyenvact $INSTALLPATH
    pip install --upgrade pip
    python3 -m pip install -r "$INSTALLPATH/pyenv_req.txt"
    deactivate
}
pyenvrm () {
    local HERE=$(pwd)
    local INSTALLPATH=${1:-$HERE}
    if [ -d $INSTALLPATH/$PYENVNAME ] ; then
        echo "Removing the whole $INSTALLPATH/$PYENVNAME folder"
        rm -rf $INSTALLPATH/$PYENVNAME
    else
        echo "Environment not found!"    
    fi
}

echo "ASCII to ROOT conversion can be managed with:"
#echo "- liveconvert [B_LOC] [B_RDO] - for continuous conversion"
echo "- [DAQ_PATH]/liveconvert.sh [B_RDO] - for continuous conversion"
echo "- manualconvert [B_LOC] [B_RDO] [B_LAT] - for manual conversion"
echo "Here:"
echo "- [B_LOC] - run on remote repository (0) or on DAQ machine (1)? - does not affect file paths"
echo "- [B_RDO] - erase and redo whole run (0) or keep existing files (1)?"
echo "- [B_LAT] - if it is not 0, override runarray and run on the latest file"
echo "Further settings can be found in pyconv.py (backend)"
echo "The conversion should be managed with the Python virtualenv pyenv:"
echo "- (re-)create it with the command 'pyenvremake' (followed by installation path - default is current, must have pyenv_req.txt)"
echo "- activate it with the command 'pyenvact' (followed by installation path - default is current)"
echo "- deactivate it with the command 'deactivate'"
echo "- delete it with the command 'pyenvrm'"
echo "ASCII files are sought in $ROOTCREATEINPATH, to be set independently of [B_LOC]"
echo "ROOT files are saved in $ROOTCREATEOUTPATH, to be set independently of [B_LOC]"

echo "---"
