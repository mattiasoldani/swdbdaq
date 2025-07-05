#include "s_fitpix.h"
#include <libmemcached/memcached.h>

int k, l, jj, jjj, kk, ne, lop, zz, i;
l = 0;

memcached_server_st *servers = NULL;
memcached_st *memc;
memcached_return rcm;
memcached_return rcmv[MAX_DEV];

size_t key_length[MAX_DEV];
char return_key[MEMCACHED_MAX_KEY];
size_t return_key_length[MAX_DEV];
char *return_value[MAX_DEV];
size_t return_value_length[MAX_DEV];
uint32_t flags;

unsigned short dmstimevalue[MAX_DEV] = {0};
unsigned short mstimeold[MAX_DEV] = {0};
unsigned short *p[MAX_DEV];

int number_of_key = MAX_DEV;

unsigned int sec[MAX_DEV] = {0};

double utime_fit[MAX_DEV] = {0};
double utime_fit_old[MAX_DEV] = {0};

bool newevent[MAX_DEV];

void s_fitpix_initVarsLoop()
{
    for (k = 0; k < MAX_DEV; k++)
    {
        key_length[k] = strlen(keys[k]);
    }
}

bool s_fitpix_initMc()
{
    memc = memcached_create(NULL);
    servers = memcached_server_list_append(servers, MC_IP, 11211, &rcm);
    rcm = memcached_server_push(memc, servers);

    bool success = rcm == MEMCACHED_SUCCESS;

    if (success)
        printf("Added server successfully\n");
    else
        printf("Couldn't add server: %s\n", memcached_strerror(memc, rcm));

    return success;
}

s_fitpix_out_t s_fitpix_read()
{
    unsigned short devId0[MAX_DEV] = {0};
    char *devKey0[MAX_DEV] = {0};
    unsigned short TypeOfPack0[MAX_DEV] = {0};
    unsigned short hOffset0[MAX_DEV] = {0};
    unsigned short nFrame0[MAX_DEV] = {0};
    size_t fpixLength0[MAX_DEV] = {0};
    unsigned short fpix0[MAX_DEV][SINGLE_CHIP_PIXSIZE] = {0};
    s_fitpix_out_t outData;
    outData.fpixUTCsec = 0;
    outData.machineUTCsec = 0;
    outData.jitterUTCsec = 0;
    outData.k = 0;
    outData.nDevs = 0;
    for (i=0; i<MAX_DEV; i++) {
        outData.devId[i] = devId0[i];
        outData.devKey[i] = devKey0[i];
        outData.TypeOfPack[i] = TypeOfPack0[i];
        outData.hOffset[i] = hOffset0[i];
        outData.nFrame[i] = nFrame0[i];
        outData.fpixLength[i] = fpixLength0[i];
        for (jj = 0; jj < SINGLE_CHIP_PIXSIZE; jj++) {
            outData.fpix[i][jj] = fpix0[i][jj];
        }
    }

    int bool_rcvm = 1;
    int bool_ne = 1;
    int bool_time = 1;

    //struct timespec currentTime;
    //double utcMachineTime, utcJitter;

    rcm = memcached_mget(memc, keys, key_length, number_of_key);

    for (jj = 0; jj < MAX_DEV; jj++)
    {
        return_value[jj] = memcached_fetch(memc, return_key, &return_key_length[jj], &return_value_length[jj], &flags, &rcmv[jj]);
        if (FPIX_PRINT_INSIDE)
            printf("\nFetching MC for device %d, expected %s, returned %s\n", jj, keys[jj], return_key);
        //clock_gettime(CLOCK_REALTIME, &currentTime);
    }

    for (jjj = 0; jjj < MAX_DEV; jjj++)
    {
        bool_rcvm *= (rcmv[jjj] == MEMCACHED_SUCCESS);
    }

    if (bool_rcvm)
    {
        for (kk = 0; kk < MAX_DEV; kk++)
        {
            p[kk] = (unsigned short *)(return_value[kk]);
            sec[kk] = ((unsigned int)p[kk][2] << 16) | p[kk][1];
            dmstimevalue[kk] = p[kk][3];
            utime_fit[kk] = sec[kk] + dmstimevalue[kk] / 10000.0;
            newevent[kk] = (utime_fit[kk] == utime_fit_old[kk]) ? false : true;
            utime_fit_old[kk] = utime_fit[kk];
            if (FPIX_PRINT_INSIDE)
                printf("Will check data from device %d, time %f, bool for new event is %d\n", kk, utime_fit[kk], newevent[kk]);
        }
        for (ne = 0; ne < MAX_DEV; ne++)
            bool_ne *= newevent[ne];

        if (bool_ne)
        {
            for (lop = 0; lop < MAX_DEV; lop++)
                bool_time *= (fabs(utime_fit[lop] - utime_fit[0]) < MAX_DELAY);
            if (bool_time)
            {
                if (FPIX_PRINT_INSIDE)
                    printf("\n++++++++++++ NEW EVENT ++++++++++++\n");
                for (zz = 0; zz < MAX_DEV; zz++)
                {
                    if (FPIX_PRINT_INSIDE)
                    {
                        //utcMachineTime = currentTime.tv_sec + (double)currentTime.tv_nsec / 1e9;
                        //utcJitter = utime_fit[zz] - utcMachineTime;
                        printf("Device %s, new event (on time %f) nr. %d\n", keys[zz], utime_fit[zz], k);
                        //printf("Jitter wrt. DAQ time (%f) is %f\n", utcMachineTime, utcJitter);
                        printf("TypeOfPack %x, hOffset %d, nFrame %d, fpixLength %d\n", p[zz][0], p[zz][4], p[zz][5], return_value_length[zz] / sizeof(unsigned short) - HEADER_OFFSET_ULTRA);
                    }

                    outData.fpixUTCsec = utime_fit[0];
                    //outData.machineUTCsec = utcMachineTime;
                    //outData.jitterUTCsec = utcJitter;
                    outData.machineUTCsec = 0.0;
                    outData.jitterUTCsec = 0.0;
                    outData.k = k;
                    outData.nDevs = MAX_DEV;
                    outData.devId[zz] = zz;
                    outData.devKey[zz] = keys[zz];
                    outData.TypeOfPack[zz] = p[zz][0];
                    outData.hOffset[zz] = p[zz][4];
                    outData.nFrame[zz] = p[zz][5];
                    outData.fpixLength[zz] = return_value_length[zz] / sizeof(unsigned short) - HEADER_OFFSET_ULTRA;

                    for (i = HEADER_OFFSET_ULTRA; i < (return_value_length[zz] / sizeof(unsigned short)); i++)
                    {
                        outData.fpix[zz][i - HEADER_OFFSET_ULTRA] = p[zz][i];

                        if (FPIX_PRINT_INSIDE)
                            printf("Device %s, %d-th pixel: %d\n", keys[zz], i-HEADER_OFFSET_ULTRA, p[zz][i]);
                    }
                }
            }
            if (FPIX_PRINT_INSIDE)
                printf("++++++++++++ EVENT END ++++++++++++\n\n");
            k++;
        }
    }
    return outData;
}
