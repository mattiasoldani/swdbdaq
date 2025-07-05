#ifndef _S_FITPIX__H_
#define _S_FITPIX__H_

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <sys/time.h>
#include <libmemcached/memcached.h>
#include <stdbool.h>

#define MAX_DEV 1
#define SINGLE_CHIP_PIXSIZE 65536
#define ERRMSG_BUFF_SIZE    512
#define NANO 1000000000L
#define HEADER_OFFSET 2
#define HEADER_OFFSET_ULTRA 6
#define MAX_DELAY 0.005
#define DEBUG

typedef struct {
    double fpixUTCsec;
    size_t fpixLength;
    unsigned short devId;
    unsigned short TypeOfPack;
    unsigned short hOffset;
    unsigned short nFrame;
    unsigned short fpix[SINGLE_CHIP_PIXSIZE];
} s_fitpix_out_t;

void s_fitpix_initVarsLoop();

bool s_fitpix_initMc();

s_fitpix_out_t s_fitpix_read();

#endif
