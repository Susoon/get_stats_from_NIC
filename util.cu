#include "util.cu.h"
#include "eth.cu.h"
#include "arp.cu.h" 
#include "icmp.cu.h"
#include "ip.cu.h"
#include "log.h"
#include <linux/ip.h>
#include <linux/udp.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

//#include <sys/types.h>
//#include <sys/socket.h>
#include <arpa/inet.h> // IPPROTO_TCP, IPPROTO_ICMP

// returns a timestamp in nanoseconds
// based on rdtsc on reasonably configured systems and is hence fast
uint64_t monotonic_time() {
	struct timespec timespec;
	clock_gettime(CLOCK_MONOTONIC, &timespec);
	return timespec.tv_sec * 1000 * 1000 * 1000 + timespec.tv_nsec;
}

uint32_t get_pkt_size_idx(uint32_t pkt_size)
{
    uint32_t idx = 0;

    switch(pkt_size){
        case 64:
            idx = 0;
            break;
        case 127:
            idx = 1;
            break;
        case 255:
            idx = 2;
            break;
        case 511:
            idx = 3;
            break;
        case 1023:
            idx = 4;
            break;
        case 1522:
            idx = 5;
            break;
        case 4096:
            idx = 6;
            break;
        default:
            idx = 0;
            break;
    }

    return idx;
}

void update_memcpy(uint32_t** pkt_cnt, uint32_t** pkt_size, uint32_t *prev_pkt, uint32_t *cur_pkt)
{
    char units[] = {' ', 'K', 'M', 'G', 'T'};
    double pkts[2];
    char pps[2][40];
    char bps[2][40];
    uint32_t p_size = 0;
    int i, j;
#if 1
    ASSERTRT(cudaMemcpy(&cur_pkt[0], &(*pkt_cnt)[0], sizeof(uint32_t), cudaMemcpyDeviceToHost));
    ASSERTRT(cudaMemcpy(&cur_pkt[1], &(*pkt_cnt)[1], sizeof(uint32_t), cudaMemcpyDeviceToHost));
#else

    ASSERTRT(cudaMemcpy(&cur_pkt[0], pkt_cnt[0], sizeof(int), cudaMemcpyDeviceToHost));
    ASSERTRT(cudaMemcpy(&cur_pkt[1], pkt_cnt[1], sizeof(int), cudaMemcpyDeviceToHost));
#endif
    ASSERTRT(cudaMemcpy(&p_size, *pkt_size, sizeof(uint32_t), cudaMemcpyDeviceToHost));
    p_size += 4;

    system("clear");	
    printf("[Memcpy] Using cudaMemcpy\n");
#if 0
    printf("[CKJUNG] buf #0\n");
    for(i = 0; i < 1024; i++){
        printf("%d ", data[i]);
    }
    printf("\n\n");
#endif
    for(i = 0; i < 2; i++){
        double tmp_pps;
        double tmp;
        //double batch;
        if (prev_pkt[i] != cur_pkt[i]){ // If we got a traffic flow
            //printf("prev != cur________________prev_pkt[%d]: %d, cur_pkt[%d]: %d\n", i, prev_pkt[i], i, cur_pkt[i]);
            pkts[i] = (double)(cur_pkt[i] - prev_pkt[i]);

#if 0
            if(i == 0)
                printf("RX_pkts: %d\n", (int)pkts[i]); 
            else
                printf("TX_pkts: %d\n", (int)pkts[i]); 
#endif
            tmp = tmp_pps = pkts[i];
            //batch = tmp/BATCH;
            for(j = 0; tmp >= 1000 && j < sizeof(units)/sizeof(char) -1; j++)
                tmp /= 1000;
            sprintf(pps[i],"%.3lf %c" ,tmp, units[j]);
#if 0
            p_size = PKT_SIZE;
#endif

            //tmp = pkts[i] * p_size * 8; // Bytes -> Bits
            tmp = pkts[i] * p_size * 8 + tmp_pps * 20 * 8; // Add IFG also, 20.01.15, CKJUNG
            for(j = 0; tmp >= 1000 && j < sizeof(units)/sizeof(char) -1; j++)
                tmp /= 1000;

            double percent = 100.0;
            percent = tmp/percent*100;
            sprintf(bps[i],"%.3lf %c" ,tmp, units[j]);

            if(i == 0){
                //printf("[RX] pps: %spps %sbps(%.2lf %), pkt_size: %d \n", pps[i], bps[i], percent, p_size);
                printf("[RX] pps: %spps %sbps(", pps[i], bps[i]);
                if(percent >= 99){
                    START_GRN
                        printf("%.2lf %%",percent);
                    END
                }else{
                    START_YLW
                        printf("%.2lf %%",percent);
                    END
                }
                printf("), pkt_size: ");
                START_RED
                    printf("%d \n", p_size);
                END
            }else{
                /*
                   printf("[TX] pps: %spps %sbps(%.2lf %%), pkt_size: ", pps[i], bps[i], percent);
                 */

                printf("[TX] pps: %spps %sbps(", pps[i], bps[i]);
                if(percent >= 99){
                    START_GRN
                        printf("%.2lf %%",percent);
                    END
                }else{
                    START_YLW
                        printf("%.2lf %%",percent);
                    END
                }
                printf("), pkt_size: ");
                START_RED
                    printf("%d \n", p_size);
                END
            }
        }else{
            if(i == 0)
                printf("[RX] pps: None\n");
            else
                printf("[TX] pps: None\n");
        }
    }
#if 0
    for(i = 0; i<STATUS_SIZE; i++)
    {
        if(i % 512 ==0)
            printf("\n\n");
        if(buf_idx[i] == 1){
            START_GRN
                printf("%d ", buf_idx[i]);
            END
        }else if(buf_idx[i] == 2){
            START_RED
                printf("%d ", buf_idx[i]);
            END
        }else if(buf_idx[i] == 3){
            START_BLU
                printf("%d ", buf_idx[i]);
            END
        }else{
            printf("%d ", buf_idx[i]);
        }
    }
    printf("\n");
#endif
    prev_pkt[0] = cur_pkt[0];
    prev_pkt[1] = cur_pkt[1];

    printf("\n");
}


void update_stats(
        uint8_t *bar_addr, 
        uint32_t port, 
        struct ice_stats *prev_stats, 
        struct ice_stats *cur_stats)
{
    char units[] = {' ', 'K', 'M', 'G', 'T'};
    char *pkt_sizes[] = {"64", "65-127", "128-255", "256-511", "512-1023", "1024-1522", "big"};
    double pkts;
    char pps[40];
    char bps[40];
    uint32_t pkt_size[2] = {0};
    int i;

    ice_stat_update_rx(bar_addr, port, &prev_stats->rx_stats, &cur_stats->rx_stats, &pkt_size[0]);
    ice_stat_update_tx(bar_addr, port, &prev_stats->tx_stats, &cur_stats->tx_stats, &pkt_size[1]);
    
/*
    printf("[%s] rx : %ld tx :%ld\n", __FUNCTION__, cur_stats->rx_stats.rx_total, cur_stats->tx_stats.tx_total);
    printf("[%s] rx : %ld tx :%ld\n", __FUNCTION__, prev_stats->rx_stats.rx_total, prev_stats->tx_stats.tx_total);
*/

    //system("clear");	

    double tmp_pps;
    double tmp;

    printf("[STATS] Using NIC stats\n");

    // If we got a RX traffic flow
    if (prev_stats->rx_stats.rx_total != cur_stats->rx_stats.rx_total){ 
        pkts = (double)(cur_stats->rx_stats.rx_total - prev_stats->rx_stats.rx_total);

        tmp = tmp_pps = pkts;
        for(i = 0; tmp >= 1000 && i < sizeof(units)/sizeof(char) -1; i++)
            tmp /= 1000;
        sprintf(pps, "%.3lf %c" ,tmp, units[i]);

        tmp = pkts * pkt_size[0] * 8 + tmp_pps * 20 * 8; // Add IFG also, 20.01.15, CKJUNG
        tmp = (cur_stats->rx_stats.rx_bytes - prev_stats->rx_stats.rx_bytes) * 8 + tmp_pps * 20 * 8;
        for(i = 0; tmp >= 1000 && i < sizeof(units)/sizeof(char) -1; i++)
            tmp /= 1000;

        double percent = 100.0;
        percent = tmp/percent*100;
        sprintf(bps, "%.3lf %c" ,tmp, units[i]);

        printf("[RX] pps: %spps %sbps(", pps, bps);
        if(percent >= 99){
            START_GRN
                printf("%.2lf %%",percent);
            END
        }else{
            START_YLW
                printf("%.2lf %%",percent);
            END
        }
        printf("), pkt_size: ");
        START_RED
            printf("%s \n", pkt_sizes[get_pkt_size_idx(pkt_size[0])]);
        END
    }
    else{
        printf("[RX] pps: None\n");
    }

    if(prev_stats->tx_stats.tx_total != cur_stats->tx_stats.tx_total){ 
        pkts = (double)(cur_stats->tx_stats.tx_total - prev_stats->tx_stats.tx_total);

        tmp = tmp_pps = pkts;
        for(i = 0; tmp >= 1000 && i < sizeof(units)/sizeof(char) -1; i++)
            tmp /= 1000;
        sprintf(pps, "%.3lf %c" ,tmp, units[i]);

        tmp = pkts * pkt_size[1] * 8 + tmp_pps * 20 * 8; // Add IFG also, 20.01.15, CKJUNG
        tmp = (cur_stats->tx_stats.tx_bytes - prev_stats->tx_stats.tx_bytes) * 8 + tmp_pps * 20 * 8;
        for(i = 0; tmp >= 1000 && i < sizeof(units)/sizeof(char) -1; i++)
            tmp /= 1000;

        double percent = 100.0;
        percent = tmp/percent*100;
        sprintf(bps, "%.3lf %c" ,tmp, units[i]);

        printf("[TX] pps: %spps %sbps(", pps, bps);
        if(percent >= 99){
            START_GRN
                printf("%.2lf %%", percent);
            END
        }else{
            START_YLW
                printf("%.2lf %%", percent);
            END
        }
        printf("), pkt_size: ");
        START_RED
            printf("%s \n", pkt_sizes[get_pkt_size_idx(pkt_size[1])]);
        END
    }
    else{
        printf("[TX] pps: None\n");
    }

    printf("\n");
}

void monitoring_loop(uint8_t *bar_addr, uint32_t** pkt_cnt, uint32_t** pkt_size)
{
    START_GRN
        printf("[Monitoring] Control is returned to CPU!\n");
    END

        struct ice_stats *cur_stats;
    struct ice_stats *prev_stats;

    uint32_t prev_pkt[2] = {0,}, cur_pkt[2] = {0,};
    int elapsed_time = 0;

    uint64_t last_stats_printed = monotonic_time();
    uint64_t time;

    cur_stats = (struct ice_stats *)calloc(1, sizeof(struct ice_stats));
    prev_stats = (struct ice_stats *)calloc(1, sizeof(struct ice_stats));

    while(1)                                           
    {
        time = monotonic_time();
        if(time - last_stats_printed > 1000 * 1000 * 1000){
            elapsed_time++; // 1 sec +
            last_stats_printed = time;

            update_memcpy(pkt_cnt, pkt_size, prev_pkt, cur_pkt);
            update_stats(bar_addr, 0, prev_stats, cur_stats);

            int second = elapsed_time%60;
            int minute = elapsed_time%3600/60;
            int hour   = elapsed_time/3600;

            printf("Elapsed: %3d h %3d m %3d s\n(ctrl + c) to stop.\n", hour, minute, second);
        }
        //sleep(1); 
    }                                                                  
}




__device__ void DumpPacket_raw(unsigned char* buf, int len)
{
    int i;

	START_YLW
	printf("[START]___________________________________________\n");
	END
	printf("DumpPkt_____________________________________HEX___\n");
	for(i = 0; i < len; i++)
	{
		if(i % 16 == 0)
			printf("\n");

		printf("%02x ", buf[i]);
	}
	printf("\n____________________________________________HEX___\n\n");

	START_YLW
	printf("[END]___________________________________________\n\n\n");
	END
}

__device__ void DumpARPPacket(struct arphdr *arph)
//void DumpARPPacket(struct arphdr *arph)
{
	uint8_t *t;

	printf("ARP header: \n");
	printf("Hardware type: %d (len: %d), "
			"protocol type: %d (len: %d), opcode: %d\n", 
			//ntohs(arph->ar_hrd), arph->ar_hln, 
			NTOHS(arph->ar_hrd), arph->ar_hln, 
			//ntohs(arph->ar_pro), arph->ar_pln, ntohs(arph->ar_op));
			NTOHS(arph->ar_pro), arph->ar_pln, NTOHS(arph->ar_op));
	t = (uint8_t *)&arph->ar_sip;
	printf("Sender IP: %u.%u.%u.%u, "
			"haddr: %02X:%02X:%02X:%02X:%02X:%02X\n", 
			t[0], t[1], t[2], t[3], 
			arph->ar_sha[0], arph->ar_sha[1], arph->ar_sha[2], 
			arph->ar_sha[3], arph->ar_sha[4], arph->ar_sha[5]);
	t = (uint8_t *)&arph->ar_tip;
	printf("Target IP: %u.%u.%u.%u, "
			"haddr: %02X:%02X:%02X:%02X:%02X:%02X\n", 
			t[0], t[1], t[2], t[3], 
			arph->ar_tha[0], arph->ar_tha[1], arph->ar_tha[2], 
			arph->ar_tha[3], arph->ar_tha[4], arph->ar_tha[5]);
}

__device__ void 
DumpICMPPacket(const char* type, struct icmphdr *icmph, uint32_t saddr, uint32_t daddr)
{
  uint8_t* _saddr = (uint8_t*) &saddr;
  uint8_t* _daddr = (uint8_t*) &daddr;

	printf("ICMP header: \n");
  printf("Type: %d, "
      "Code: %d, ID: %d, Sequence: %d\n", 
      icmph->icmp_type, icmph->icmp_code,
      NTOHS(ICMP_ECHO_GET_ID(icmph)), NTOHS(ICMP_ECHO_GET_SEQ(icmph)));

  printf("Sender IP: %u.%u.%u.%u\n",
      *_saddr++, *_saddr++, *_saddr++, *_saddr);
  printf("Target IP: %u.%u.%u.%u\n",
      *_daddr++, *_daddr++, *_daddr++, *_daddr);

  printf("%s--------------------------------------------\n", type);
  for(int i=0; i<64; i+=2) {
    printf("%x ", *(((uint8_t*)icmph) + i));
    printf("%x ", *(((uint8_t*)icmph) + i+1));
    if(i%20==0)
      printf("\n");
  }
  printf("\n--------------------------------------------\n");
}

__device__ void 
DumpICMPPacket(struct icmphdr *icmph, uint32_t saddr, uint32_t daddr)
{
  uint8_t* _saddr = (uint8_t*) &saddr;
  uint8_t* _daddr = (uint8_t*) &daddr;

	printf("ICMP header: \n");
  printf("Type: %d, "
      "Code: %d, ID: %d, Sequence: %d\n", 
      icmph->icmp_type, icmph->icmp_code,
      NTOHS(ICMP_ECHO_GET_ID(icmph)), NTOHS(ICMP_ECHO_GET_SEQ(icmph)));

  printf("Sender IP: %u.%u.%u.%u\n",
      *_saddr++, *_saddr++, *_saddr++, *_saddr);
  printf("Target IP: %u.%u.%u.%u\n",
      *_daddr++, *_daddr++, *_daddr++, *_daddr);

  printf("--------------------------------------------\n");
  for(int i=0; i<100; i+=2) {
    printf("%x ", *(((uint8_t*)icmph) + i));
    printf("%x ", *(((uint8_t*)icmph) + i+1));
    if(i%20==0)
      printf("\n");
  }
  printf("\n--------------------------------------------\n");
}

__device__ void 
DumpICMPPacket(struct icmphdr *icmph, uint8_t* saddr, uint8_t* daddr)
{
	printf("\nICMP header: \n");
  printf("Type: %d, "
      "Code: %d, ID: %d, Sequence: %d\n", 
      icmph->icmp_type, icmph->icmp_code,
      NTOHS(ICMP_ECHO_GET_ID(icmph)), NTOHS(ICMP_ECHO_GET_SEQ(icmph)));
	printf("ICMP_checksum: 0x%x\n", icmph->icmp_checksum);
  printf("Sender IP: %u.%u.%u.%u\n",
      *saddr++, *saddr++, *saddr++, *saddr);
  printf("Target IP: %u.%u.%u.%u\n",
      *daddr++, *daddr++, *daddr++, *daddr);
}

__device__ void DumpPacket(uint8_t *buf, int len)
{
  printf("\n\n\n<<<DumpPacket>>>----------------------------------------\n");
	struct ethhdr *ethh;
	struct iphdr *iph;
	struct udphdr *udph;
	//struct tcphdr *tcph;
	uint8_t *t;

	ethh = (struct ethhdr *)buf;
	if (NTOHS(ethh->h_proto) != ETH_P_IP) {
		printf("%02X:%02X:%02X:%02X:%02X:%02X -> %02X:%02X:%02X:%02X:%02X:%02X ",
				ethh->h_source[0],
				ethh->h_source[1],
				ethh->h_source[2],
				ethh->h_source[3],
				ethh->h_source[4],
				ethh->h_source[5],
				ethh->h_dest[0],
				ethh->h_dest[1],
				ethh->h_dest[2],
				ethh->h_dest[3],
				ethh->h_dest[4],
				ethh->h_dest[5]);

		//printf("protocol %04hx  \n", ntohs(ethh->h_proto));
		printf("protocol %04hx  \n", NTOHS(ethh->h_proto));

    //if(ntohs(ethh->h_proto) == ETH_P_ARP)
    if(NTOHS(ethh->h_proto) == ETH_P_ARP)
      DumpARPPacket((struct arphdr *) (ethh + 1));
	//	goto done;
	}

	iph = (struct iphdr *)(ethh + 1);
	udph = (struct udphdr *)((uint32_t *)iph + iph->ihl);
	//tcph = (struct tcphdr *)((uint32_t *)iph + iph->ihl);

	t = (uint8_t *)&iph->saddr;
	printf("%u.%u.%u.%u", t[0], t[1], t[2], t[3]);
	if (iph->protocol == IPPROTO_TCP || iph->protocol == IPPROTO_UDP)
		//printf("(%d)", ntohs(udph->source));
		printf("(%d)", NTOHS(udph->source));

	printf(" -> ");

	t = (uint8_t *)&iph->daddr;
	printf("%u.%u.%u.%u", t[0], t[1], t[2], t[3]);
	if (iph->protocol == IPPROTO_TCP || iph->protocol == IPPROTO_UDP)
		//printf("(%d)", ntohs(udph->dest));
		printf("(%d)", NTOHS(udph->dest));
	else if (iph->protocol == IPPROTO_ICMP){
		struct icmphdr *icmph = (struct icmphdr *) IP_NEXT_PTR(iph);
		DumpICMPPacket(icmph, (uint8_t*)&(iph->saddr), (uint8_t*)&(iph->daddr));
	}

	//printf(" IP_ID=%d", ntohs(iph->id));
	printf(" IP_ID=%d", NTOHS(iph->id));
	printf(" TTL=%d ", iph->ttl);

	switch (iph->protocol) {
	case IPPROTO_TCP:
		printf("TCP ");
		break;
	case IPPROTO_UDP:
		printf("UDP ");
		break;
	default:
		printf("protocol %d ", iph->protocol);
		goto done;
	}
done:
	printf("len=%d\n", len);
  printf("<<<DumpPacket>>>-----------------------------------END--\n");

}

__device__ void schedule_tester(unsigned int sch[], unsigned int *count) {
	if(threadIdx.x == 0){
		if((*count)++ == 10000000){
		//if((*count)++ == 100000){
			printf("--------------------------------------------\n");
			for(int i = 0; i < 512; i++){                            
				if(i % 32 == 0)                                        
					printf("\n");                                        
				printf("tid: %4d, cnt: %d\n", i, sch[i]);              
			}                                                        
			printf("------------------------------------------\n\n");
			*count = 0;
		}
	}

}
