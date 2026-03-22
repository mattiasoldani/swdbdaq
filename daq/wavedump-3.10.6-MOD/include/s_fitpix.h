#ifndef _S_FITPIX__H_
#define _S_FITPIX__H_

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <sys/time.h>
#include <libmemcached/memcached.h>

//#define RUNFITPIX  // comment to exclude the FitPix from the DAQ entirely

#define MAX_DEV 1
#define SINGLE_CHIP_PIXSIZE 65536
#define HEADER_OFFSET_ULTRA 6
#define MAX_DELAY 0.005
#define MC_IP "192.168.198.164"
#define FPIX_PRINT_INSIDE 0
#define FPIX_PRINT_OUTSIDE 0
#define FPIX_PRINT_DEV 0
#define FPIX_WRITE 0  // if 1, FitPix files will be written regardless of RUNFITPIX
#define FPIX_BYPASS_TRG 0
#define FPIX_BYPASS_SLEEP 0

static const char *keys[MAX_DEV] = {"F03-W0256"};

void s_fitpix_initVarsLoop();

bool s_fitpix_initMc();

typedef struct
{
    int k;
    int nDevs;
    double fpixUTCsec;
    double machineUTCsec;
    double jitterUTCsec;
    unsigned short devId[MAX_DEV];
    char *devKey[MAX_DEV];
    unsigned short TypeOfPack[MAX_DEV];
    unsigned short hOffset[MAX_DEV];
    unsigned short nFrame[MAX_DEV];
    size_t fpixLength[MAX_DEV];
    unsigned short fpix[MAX_DEV][SINGLE_CHIP_PIXSIZE];
} s_fitpix_out_t;

s_fitpix_out_t s_fitpix_read();

#endif
