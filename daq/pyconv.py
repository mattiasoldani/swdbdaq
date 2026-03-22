# arg. 1: the raw-data path
# arg. 2: the output destination path
# arg. 3: if a run nr. is provided (see below), set to 0 (1) to erase and redo whole run (keep existing files)
# arg. 4: run nr. to process

import glob
import numpy as np
import os
import re
import string
import sys
import uproot

##########
# settings

nsamples = 1030
nchips = 1
nchannels = 8

bfitpix = False
fitpix_size = 256
shiftsize = 2
shiftvars = ["nr_pixels", "x_pixel", "y_pixel"]

blast = False

pathruns = sys.argv[1]
pathroot = sys.argv[2]

if bfitpix:
    print("Including FitPix\n---")
else:
    print("FitPix not included\n---")

if not os.path.exists(pathroot):
    print("Creating non-existing directory %s" % pathroot)
    print("(Or master path doesn't exist at all, please check)\n---")
    os.makedirs(pathroot)

#########################################################
# get the list of all runs and select the run of interest

lsruns = sorted(os.listdir(pathruns))

run = sys.argv[4] if (len(sys.argv) > 4) else lsruns[-1]
    
print("Doing run %s"%run)

#############################
# reset whole run if required

reset = int(sys.argv[3]) if (len(sys.argv) >= 4) else 0
if (reset==0):
    print("Deleting already created files...")
    for filetorm in glob.glob(os.path.join(pathroot, "%s_*.root"%run)):
        os.remove(filetorm)
else:
    print("Already existing files are kept")
    
###################################################
# get the list of all events in the run of interest
    
pathfiles = os.path.join(pathruns, run, "")
lsfiles = sorted([s for s in sorted(os.listdir(pathfiles)) if (s.startswith("wave") and not ("fitpix" in s))])
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

                try:
                    wfstream = np.loadtxt(
                        os.path.join(pathfiles, filename),
                        comments = list(string.ascii_uppercase), 
                    )

                    startindexcells = []
                    nrpix = []
                    triggerts = []
                    if checkfirstfilechip[chip]:
                        with open(os.path.join(pathfiles, filename),"r") as file:
                            for iline, line in enumerate(file):
                                if line.startswith("Start Index Cell:"):
                                    startindexcells.append(list(map(int, re.findall(r'\d+', line)))[0])
                                if line.startswith("Trigger Time Stamp:"):
                                    triggerts.append(list(map(int, re.findall(r'\d+', line)))[0])
                                if (bfitpix and line.startswith("FitPix 0 Nr. of Pixels:")):
                                    nrpix.append(list(map(int, re.findall(r'\d+', line)))[1])
                        checkfirstfilechip[chip] = False
                 
                except ValueError:
                    print("Error with input file, skipping this whole event")
                    lsevent0s = [i for i in lsevent0s if not (i==event0)]
                    checknewfiles = False
                    break

                if bfitpix and checkfirstfile:
                    x_pixel_dict, y_pixel_dict = {}, {}
                    try:
                        with open(os.path.join(pathfiles, filename.replace("_%d_%d."%(chip,channel), "_fitpix0.")),"r") as file:
                            triggerts_pix_temp = 0
                            for iline, line in enumerate(file):
                                if line.startswith("Trigger Time Stamp:"):
                                    triggerts_pix_temp = list(map(int, re.findall(r'\d+', line)))[0]
                                    if not (triggerts_pix_temp in x_pixel_dict.keys()):                                    
                                        x_pixel_dict.update({triggerts_pix_temp : []})
                                        y_pixel_dict.update({triggerts_pix_temp : []})
                                if not any([line.startswith(s) for s in list(string.ascii_uppercase)]):
                                    if (triggerts_pix_temp in x_pixel_dict.keys()):
                                        id_pix_temp = list(map(int, re.findall(r'\d+', line)))[0]
                                        x_pixel_dict[triggerts_pix_temp].append(int(np.floor(id_pix_temp / fitpix_size)))
                                        y_pixel_dict[triggerts_pix_temp].append(id_pix_temp%fitpix_size)

                    except ValueError:
                        print("Error with FitPix input file, skipping this whole event")
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
                    if len(triggerts)>0:
                        data.update({"trigger_ts" : np.array(triggerts[:-1])})
                    if (bfitpix and (len(nrpix)>0) and not ("nr_pixels" in data.keys())):
                        data.update({"nr_pixels" : np.array(nrpix[:-1])})
                    checkfirstfile = False

                wf = []
                for iwf in idwfs:
                    wf.append(wfstream[iwf : iwf + nsamples])

                data.update({wfkey : np.array(wf)})

                if (bfitpix and len(triggerts)>0):
                    data.update({"x_pixel" : []})
                    data.update({"y_pixel" : []})
                    for its, ts in enumerate(data["trigger_ts"]):
                        if ts in x_pixel_dict.keys():
                            data["x_pixel"].append(x_pixel_dict[ts])
                            data["y_pixel"].append(y_pixel_dict[ts])
                        else:
                            data["x_pixel"].append([-1])
                            data["y_pixel"].append([-1]) 
                            data["nr_pixels"][its] = 0
                            print("No FitPix data for trigger ts %d, setting pixel nr. (coords.) to 0 (-1)"%ts)

        if checknewfiles: 

            for chip in range(nchips):
                for channel in range(nchannels):
                    channel_abs = channel + chip*nchannels
                    wfkey = "wave%d"%channel_abs
                    if not (wfkey in data.keys()):
                        data.update({wfkey : np.zeros((nwfs, nsamples))})

            if (bfitpix and shiftsize!=0):
                for var in data.keys():
                    if any([var==var0 for var0 in shiftvars]):
                        data[var] = data[var][shiftsize:]                      
                    else:
                        data[var] = data[var][:-shiftsize]

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
