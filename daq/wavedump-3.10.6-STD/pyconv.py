import glob
import numpy as np
import os
import re
import string
import sys
import uproot

##########
# settings

blast = True

nsamples = 1024
nchips = 2
nchannels = 8

path0 = sys.argv[1]
pathruns = os.path.join(path0, "data_ascii/")
pathroot = os.path.join(path0, "data_root/splitted/")

if not os.path.exists(pathroot):
    print("Creating non-existing directory %s" % pathroot)
    print("(Or master path doesn't exist at all, please check)\n---")
    os.makedirs(pathroot)

#########################################################
# get the list of all runs and select the run of interest

lsruns = sorted(os.listdir(pathruns))

run = sys.argv[3] if (len(sys.argv) > 3) else lsruns[-1]
    
print("Doing run %s"%run)

#############################
# reset whole run if required

reset = int(sys.argv[2]) if (len(sys.argv) >= 3) else 0
if (reset==0):
    print("Deleting already created files...")
    for filetorm in glob.glob(os.path.join(pathroot, "%s_*.root"%run)):
        os.remove(filetorm)
else:
    print("Already existing files are kept")
    
###################################################
# get the list of all events in the run of interest
    
pathfiles = os.path.join(pathruns, run, "")
lsfiles = sorted([s for s in sorted(os.listdir(pathfiles)) if s.startswith("wave")])
lsevent0s = sorted(list(set([list(map(int, re.findall(r'\d+', s)))[0] for s in lsfiles])))

###############################################################################################
# loop on all the events, build them and write them to the ROOT file (ASCII file by ASCII file)

if len(lsevent0s)>int(not blast):
    for ievent0, event0 in enumerate(lsevent0s if blast else lsevent0s[:-1]):

        checknewfiles = False
        checkfirstfile = True
        checkfirstfilechip = [True for i in range(nchips)]

        for ifilename, filename in enumerate([s for s in lsfiles if "wave%010d"%event0 in s]):

            pathfileroot = os.path.join(pathroot, "%s_%010d.root"%(run, event0))
            if ((ifilename==0) & (not os.path.exists(pathfileroot))):
                checknewfiles = True

            if checknewfiles:
                print("Doing event %010d, file %s..." % (event0, filename))

                filenrs = re.findall(r'\d+', filename)
                _, chip, channel = list(map(int, filenrs))
                channel_abs = channel + chip*nchannels
                wfkey = "wave%d"%channel_abs

                try :
                    wfstream = np.loadtxt(
                        os.path.join(pathfiles, filename),
                        comments = list(string.ascii_uppercase), 
                    )

                    startindexcells = []
                    if checkfirstfilechip[chip]:
                        with open(os.path.join(pathfiles, filename),"r") as file:
                            for iline, line in enumerate(file):
                                if line.startswith("Start Index Cell:"):
                                    startindexcells.append(list(map(int, re.findall(r'\d+', line)))[0])
                        checkfirstfilechip[chip] = False
                 
                except ValueError:
                    print("Error with input file, skipping this whole event")
                    lsevent0s = [i for i in lsevent0s if not (i==event0)]
                    checknewfiles = False
                    break
                    
                idwfs = range(0, int(np.floor(len(wfstream) - nsamples)), nsamples)
                nwfs = len(idwfs)

                if checkfirstfile:
                    data = {
                        "run" : np.ones(nwfs) * int(run),
                        "event0" : np.ones(nwfs) * event0,
                    }

                    if len(startindexcells)>0:
                        data.update({"start_index_cell_%d"%chip : np.array(startindexcells[:-1])})
                    checkfirstfile = False

                wf = []
                for iwf in idwfs:
                    wf.append(wfstream[iwf : iwf + nsamples])

                data.update({wfkey : np.array(wf)})

        if checknewfiles: 

            for chip in range(nchips):
                for channel in range(nchannels):
                    channel_abs = channel + chip*nchannels
                    wfkey = "wave%d"%channel_abs
                    if not (wfkey in data.keys()):
                        data.update({wfkey : np.zeros((nwfs, nsamples))})

            with uproot.recreate(pathfileroot) as outfile:
                outfile["t"] = data

            del data

        else:
            if event0==(lsevent0s[-1] if blast else lsevent0s[-2]):
                print("Event %010d (latest) already converted or broken"%event0)

    print("Done")
        
else:
    if blast:
        print("No files in this run (still?)")
    else:
        print("Only 1 file or less in this run (still?), and chose to discard it")
