#ifndef __ICE_STATS_H__
#define __ICE_STATS_H__

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>

#include "ice_hw_autogen.h"

#undef BIT_ULL
#define BIT_ULL(n) (1ULL << (n))

static inline uint32_t get_reg32(const uint8_t* addr) 
{
    __asm__ volatile ("" : : : "memory");
    return *((volatile uint32_t*) (addr));
}

static inline void set_reg32(uint8_t* addr, uint32_t value) 
{
    __asm__ volatile ("" : : : "memory");
    *((volatile uint32_t*) (addr)) = value;
}

static inline uint64_t get_reg64(uint8_t* addr)
{
    uint32_t low;
    uint32_t high;
    
    low = get_reg32(addr);
    high = get_reg32(addr + 4);

    return low + ((uint64_t)high << 32);
}

static inline void set_reg64(uint8_t* addr, uint64_t value)
{
    uint32_t low;
    uint32_t high;

    low = value & ((1ULL << 32) - 1);
    high = value >> 32;

    set_reg32(addr, low);
    set_reg32(addr + 4, high);
}

static inline int get_max_idx(uint64_t *numbers, uint32_t n)
{
    uint64_t max = 0;
    int max_idx = 0;
    for(int i = 0; i < n; i++){
        if(numbers[i] > max){
            max = numbers[i];
            max_idx = i;
        }
    }

    return max_idx;
}

static inline uint32_t get_frequent_pkt_size(
        uint64_t size_64,
        uint64_t size_127,
        uint64_t size_255,
        uint64_t size_511,
        uint64_t size_1023,
        uint64_t size_1522,
        uint64_t size_big)
{
    uint64_t pkt_nums[7] = {size_64, size_127, size_255, size_511, size_1023, size_1522, size_big};

    uint32_t max_num_pkt_idx = get_max_idx(pkt_nums, 7);

    uint32_t pkt_size = 0;

    switch(max_num_pkt_idx){
    case 0:
        pkt_size = 64;
        break;
    case 1:
        pkt_size = 127;
        break;
    case 2:
        pkt_size = 255;
        break;
    case 3:
        pkt_size = 511;
        break;
    case 4:
        pkt_size = 1023;
        break;
    case 5:
        pkt_size = 1522;
        break;
    case 6:
        pkt_size = 4096;
        break;
    default:
        pkt_size = 0;
        break;
    }

    return pkt_size;
}


#if 0
#ifndef readq
static inline uint64_t readq(const volatile void *addr)
{
    const volatile uint32_t *p = addr;
    uint32_t low, high;

    low = readl(p);
    high = readl(p + 1);

    return low + ((uint64_t)high << 32);
}
#define readq readq
#endif

#ifndef writeq
static inline void writeq(uint64_t val, volatile void *addr)
{
    writel(val, addr);
    writel(val >> 32, addr + 4);
}
#define writeq writeq
#endif
#endif

struct ice_rx_stats{
    uint64_t rx_bytes;           /* gorc */
    uint64_t rx_unicast;         /* uprc */
    uint64_t rx_multicast;       /* mprc */
    uint64_t rx_broadcast;       /* bprc */
    uint64_t rx_total;
    uint64_t rx_discards;        /* rdpc */
    uint64_t rx_unknown_protocol;    /* rupp */

    /* additional port specific stats */
    uint64_t crc_errors;         /* crcerrs */
    uint64_t illegal_bytes;      /* illerrc */
    uint64_t error_bytes;        /* errbc */
    uint64_t rx_len_errors;      /* rlec */
    uint64_t link_xon_rx;        /* lxonrxc */
    uint64_t link_xoff_rx;       /* lxoffrxc */
    uint64_t priority_xon_rx[8];     /* pxonrxc[8] */
    uint64_t rx_size_64;         /* prc64 */
    uint64_t rx_size_127;        /* prc127 */
    uint64_t rx_size_255;        /* prc255 */
    uint64_t rx_size_511;        /* prc511 */
    uint64_t rx_size_1023;       /* prc1023 */
    uint64_t rx_size_1522;       /* prc1522 */
    uint64_t rx_size_big;        /* prc9522 */
    uint64_t rx_undersize;       /* ruc */
    uint64_t rx_fragments;       /* rfc */
    uint64_t rx_oversize;        /* roc */
    uint64_t rx_jabber;          /* rjc */
    uint64_t priority_xoff_rx[8];    /* pxoffrxc[8] */
    uint32_t rx_lpi_status;
    uint64_t rx_lpi_count;       /* erlpic */
};

struct ice_tx_stats{
    uint64_t tx_bytes;           /* gotc */
    uint64_t tx_unicast;         /* uptc */
    uint64_t tx_multicast;       /* mptc */
    uint64_t tx_broadcast;       /* bptc */
    uint64_t tx_discards;        /* tdpc */
    uint64_t tx_errors;          /* tepc */
    uint64_t tx_total;

    /* additional port specific stats */
    uint64_t mac_local_faults;       /* mlfc */
    uint64_t mac_remote_faults;      /* mrfc */
    uint64_t link_xon_tx;        /* lxontxc */
    uint64_t link_xoff_tx;       /* lxofftxc */
    uint64_t priority_xon_tx[8];     /* pxontxc[8] */
    uint64_t priority_xoff_tx[8];    /* pxofftxc[8] */
    uint64_t priority_xon_2_xoff[8]; /* pxon2offc[8] */
    uint64_t tx_size_64;         /* ptc64 */
    uint64_t tx_size_127;        /* ptc127 */
    uint64_t tx_size_255;        /* ptc255 */
    uint64_t tx_size_511;        /* ptc511 */
    uint64_t tx_size_1023;       /* ptc1023 */
    uint64_t tx_size_1522;       /* ptc1522 */
    uint64_t tx_size_big;        /* ptc9522 */
    uint64_t mac_short_pkt_dropped;  /* mspdc */
    /* EEE LPI */
    uint32_t tx_lpi_status;
    uint64_t tx_lpi_count;       /* etlpic */
    uint64_t tx_dropped_link_down;   /* tdold */
};

struct ice_stats{
    struct ice_rx_stats rx_stats;
    struct ice_tx_stats tx_stats;

    /* flow director stats */
    uint32_t fd_sb_status;
    uint64_t fd_sb_match;
    uint64_t ch_atr_match;
};

void mmap_bar_for_stats(void **bar_addr, int fd);

void ice_stat_update40(
        uint8_t *bar_addr, 
        uint32_t reg_offset, 
        uint64_t *prev_stat, 
        uint64_t *cur_stat);

void ice_stat_update32(
        uint8_t *bar_addr, 
        uint32_t reg_offset, 
        uint64_t *prev_stat, 
        uint64_t *cur_stat);

void ice_get_rx_pkt_size(
          struct ice_rx_stats *prev_stats,
          struct ice_rx_stats *cur_stats,
          uint32_t *pkt_size);

void ice_get_tx_pkt_size(
          struct ice_tx_stats *prev_stats,
          struct ice_tx_stats *cur_stats,
          uint32_t *pkt_size);

void ice_stat_update_rx(
        uint8_t *bar_addr, 
        uint32_t port, 
        struct ice_rx_stats *prev_stats, 
        struct ice_rx_stats *cur_stats, 
        uint32_t *pkt_size);

void ice_stat_update_tx(
        uint8_t *bar_addr, 
        uint32_t port, 
        struct ice_tx_stats *prev_stats, 
        struct ice_tx_stats *cur_stats,
        uint32_t *pkt_size);

#endif
