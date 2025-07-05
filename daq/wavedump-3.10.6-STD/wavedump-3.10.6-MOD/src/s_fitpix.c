#include "s_fitpix.h"
#include <libmemcached/memcached.h>

int k, jj, jjj, kk, ne, lop, zz, i;

unsigned short frameBuffstat[SINGLE_CHIP_PIXSIZE];
unsigned int data_mem_n=0;

unsigned short *vout;

memcached_server_st *servers = NULL; 
memcached_st *memc;
unsigned rcmv_t;
memcached_return rcm;
memcached_return rcmv[MAX_DEV];

char *keys[MAX_DEV]= {"F03-W0256"};
size_t key_length[MAX_DEV];
char return_key[MEMCACHED_MAX_KEY];
size_t return_key_length[MAX_DEV];
char *return_value[MAX_DEV];
size_t return_value_length[MAX_DEV];
uint32_t flags;

unsigned short dmstimevalue[MAX_DEV]={0};
unsigned short mstimeold[MAX_DEV]={0};    
unsigned short *p[MAX_DEV];

int number_of_key =MAX_DEV;

unsigned int sec[MAX_DEV]={0};

double utime_fit[MAX_DEV]={0};
double utime_fit_old[MAX_DEV]={0};

bool newevent[MAX_DEV];

void s_fitpix_initVarsLoop()
{
	for (k=0;k<MAX_DEV;k++) {
		key_length[k] = strlen(keys[k]);
	}
}

bool s_fitpix_initMc()
{
  memc= memcached_create(NULL);
  servers= memcached_server_list_append(servers, "192.168.198.164", 11211, &rcm);
  rcm= memcached_server_push(memc, servers);
  
  bool success = rcm == MEMCACHED_SUCCESS;

  if (success)
    printf("Added server successfully\n");
  else
    printf("Couldn't add server: %s\n",memcached_strerror(memc, rcm));

  return success; 
}

s_fitpix_out_t s_fitpix_read()
{
    unsigned short fpix0[SINGLE_CHIP_PIXSIZE] = {0};
    s_fitpix_out_t outData = {
	.fpixUTCsec = 0,
	.devId = 0,
	.TypeOfPack = 0,
	.hOffset = 0,
	.nFrame = 0,
 	.fpix = fpix0
    };

    int bool_rcvm=1;
    int bool_ne=1;
    int bool_time=1;

    rcm= memcached_mget(memc, keys, key_length, number_of_key); 

    for(jj=0;jj<MAX_DEV;jj++){
      return_value[jj]= memcached_fetch(memc, return_key, &return_key_length[jj],&return_value_length[jj], &flags, &rcmv[jj]);
      //printf("Loop %d, error multiple MC=%d %s\n\n",jj, rcmv[jj], return_key );
    }
    
    //printf("Loop %d, error multiple MC=%d,%d\n\n",l, rcmv[0],rcmv[1] );
    for(jjj=0;jjj<MAX_DEV;jjj++){
        bool_rcvm *= (rcmv[jjj] == MEMCACHED_SUCCESS);
    }

    if (bool_rcvm){
        for(kk=0;kk<MAX_DEV;kk++){	
            p[kk] = (unsigned short*)(return_value[kk]);
            sec[kk]=( (unsigned int)p[kk][2] << 16) |p[kk][1] ;
            dmstimevalue[kk]=p[kk][3]; 
            utime_fit[kk]=sec[kk]+dmstimevalue[kk]/10000.0;
            newevent[kk] = (utime_fit[kk]==utime_fit_old[kk])?false:true;
            utime_fit_old[kk]=utime_fit[kk];
            //printf("Device %d, Time %f, newevent=%d\n",kk,utime_fit[kk], newevent[kk]);
        }
        for(ne=0;ne<MAX_DEV;ne++) 
	        bool_ne *= newevent[ne];

        if(bool_ne){
            for(lop=0;lop<MAX_DEV;lop++) 
                bool_time *= (fabs(utime_fit[lop]-utime_fit[0])<MAX_DELAY);
            if (bool_time){
                //printf("+++++++++NEW EVENT++++++++++");  
                for(zz=0;zz<MAX_DEV;zz++){
                    //printf("\n\n----FITPIX %s--%d\n",keys[zz],k);
                    //printf("FITPIX %s TIME %f\n",keys[zz],utime_fit[zz]);
                    //printf("data header p0(Type of packing)=%x p4(j-HeaderOffet)=%d p5(Nframe_in_acqusition)=%d\n", p[zz][0],p[zz][4],p[zz][5]);
                    //printf("%zu, %zu, %zu, %d\n",return_value_length[zz],sizeof(unsigned short),(return_value_length[zz]/sizeof(unsigned short)),HEADER_OFFSET_ULTRA);
                    for(i=HEADER_OFFSET_ULTRA;i<(return_value_length[zz]/sizeof(unsigned short));i++){
                    
			    //printf("Pixel on %d\n",p[zz][i]);
		            outData.fpixUTCsec=utime_fit[0];
				outData.fpixLength=return_value_length[zz]/sizeof(unsigned short)-HEADER_OFFSET_ULTRA;
		            outData.devId=zz;
		            outData.TypeOfPack=p[zz][0];
		            outData.hOffset=p[zz][4];
		            outData.nFrame=p[zz][5];
		            outData.fpix[i-HEADER_OFFSET_ULTRA]=p[zz][i];
		            
		            //printf("---FITPIX %s data-%d=%d on loop %d\n",keys[zz],i,p[zz][i],l);
                    }
                } 
            }
            //printf("+++++++++NEW EVENT END++++++++++\n\n\n");  
            k++;
        }
    }
    return outData;
}
