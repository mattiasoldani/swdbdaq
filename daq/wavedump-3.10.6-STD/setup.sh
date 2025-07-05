#!/bin/bash

export DAQPATH=$HOME/swdbdaq  # <------------------- set DAQ master path (dedicated sub-paths below)
export CONFFILE=$DAQPATH/conf/daqnow.txt  # <------------------ set DAQ configuration file
export LOCALDATAPATH=$DAQPATH/rawdata

export SYNCPATH=$HOME/eos_space_temp  # <---------------------- set sync destination master path (dedicated sub-paths below)
export SYNCDAQPATH=$SYNCPATH/daq_dev
export SYNCDATAPATH=$SYNCPATH/data_ascii

export REMOTEUSER=msoldani@lxplus.cern.ch  # <----------------- set the remote repo account here
export REMOTEPATH=/eos/experiment/nanocal/bt/24_04_btf  # <---- set the remote repo path (to be mounted in SYNCPATH)

echo "**********************"
echo "     MATTIA'S DAQ     "
echo "**********************"

echo "The DAQ path is:"
echo $DAQPATH

echo "---"

echo "The default configuration file is:"
echo $CONFFILE

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
echo "Mount the remote repo directory with the command 'mountsync'"

echo "---"

alias daqsync="rsync -avW --update --exclude 'rawdata' --exclude 'wfrootconvert_env' -e 'ssh -T -c arcfour -o Compression=no -x' $DAQPATH/ $SYNCDAQPATH"
echo "Manually sync the DAQ program (data excluded) to the sync space with the command 'daqsync'"

echo "---"

alias datasync="rsync -avW -e 'ssh -T -c arcfour -o Compression=no -x' $LOCALDATAPATH/ $SYNCDATAPATH"
echo "Manually sync the data to the sync space with the command 'datasync'"
echo "(For automated real-time sync check the livesync.sh script out)"

echo "---"

echo "ASCII to ROOT conversion should be managed in the remote repo, with wfrootconvert.py & liveconvert.sh"
echo "It should be managed with the Python virtualenv wfrootconvert_env:"

convertenvactivate () {
    local HERE=$(pwd)
    source ${1:-$HERE}/wfrootconvert_env/bin/activate
}
convertenvcreate () {
    local HERE=$(pwd)
    local INSTALLPATH=${1:-$HERE}
    echo "Installing in $INSTALLPATH..." && echo "---"
    cd $INSTALLPATH
    python3 -m venv wfrootconvert_env
    cd $HERE
    convertenvactivate $INSTALLPATH
    pip install --upgrade pip
    python3 -m pip install -r "$DAQPATH/wfrootconvert_req.txt"
    deactivate
}

echo "- activate it with the command 'convertenvactivate' (followed by installation path - default is current)"
echo "- deactivate it with the command 'deactivate'"
echo "- create it with the command 'convertenvcreate' (followed by installation path - default is current)"

echo "---"
