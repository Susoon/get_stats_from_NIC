#include "ice_stats.cu.h"

void mmap_bar_for_stats(void **bar_addr, int fd)
{
    const uint32_t STATS_SIZE = 0x100000;

    *bar_addr = mmap(0, (STATS_SIZE), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0x00300000);
    if(*bar_addr == MAP_FAILED){
        printf("[%s] bar mmap Error!\n", __FUNCTION__);
        exit(1);
    }
}

void ice_stat_update40(
        uint8_t *bar_addr, 
        uint32_t reg_offset, 
        uint64_t *prev_stat, 
        uint64_t *cur_stat)
{
    uint64_t new_data = get_reg64(bar_addr + reg_offset) & (BIT_ULL(40) - 1);
    //printf("[%s] get_reg64 : %ld new_data : %ld\n", __FUNCTION__, get_reg64(bar_addr + reg_offset), new_data);

#if 0
    /* Calculate the difference between the new and old values, and then
     * add it to the software stat value.
     */
    if (new_data >= *prev_stat)
        *cur_stat += new_data - *prev_stat;
    else
        /* to manage the potential roll-over */
        *cur_stat += (new_data + BIT_ULL(40)) - *prev_stat;

    /* Update the previously stored value to prepare for next read */
    *prev_stat = new_data;
#else
    *prev_stat = *cur_stat;
    *cur_stat = new_data;
#endif
}

void ice_stat_update32(
        uint8_t *bar_addr, 
        uint32_t reg_offset, 
        uint64_t *prev_stat, 
        uint64_t *cur_stat)
{
    uint32_t new_data;

    new_data = get_reg32(bar_addr + reg_offset);

#if 0
    /* Calculate the difference between the new and old values, and then
     * add it to the software stat value.
     */
    if (new_data >= *prev_stat)
        *cur_stat += new_data - *prev_stat;
    else
        /* to manage the potential roll-over */
        *cur_stat += (new_data + BIT_ULL(32)) - *prev_stat;

    /* Update the previously stored value to prepare for next read */
    *prev_stat = new_data;
#else
    *prev_stat = *cur_stat;
    *cur_stat = new_data;
#endif
}

void ice_get_rx_pkt_size(
        struct ice_rx_stats *prev_stats, 
        struct ice_rx_stats *cur_stats,
        uint32_t *pkt_size)
{
    *pkt_size = get_frequent_pkt_size(
                        cur_stats->rx_size_64 - prev_stats->rx_size_64,
                        cur_stats->rx_size_127 - prev_stats->rx_size_127,
                        cur_stats->rx_size_255 - prev_stats->rx_size_255,
                        cur_stats->rx_size_511 - prev_stats->rx_size_511,
                        cur_stats->rx_size_1023 - prev_stats->rx_size_1023,
                        cur_stats->rx_size_1522 - prev_stats->rx_size_1522,
                        cur_stats->rx_size_big - prev_stats->rx_size_big);
}

void ice_get_tx_pkt_size(
        struct ice_tx_stats *prev_stats, 
        struct ice_tx_stats *cur_stats,
        uint32_t *pkt_size)
{
    *pkt_size = get_frequent_pkt_size(
                        cur_stats->tx_size_64 - prev_stats->tx_size_64,
                        cur_stats->tx_size_127 - prev_stats->tx_size_127,
                        cur_stats->tx_size_255 - prev_stats->tx_size_255,
                        cur_stats->tx_size_511 - prev_stats->tx_size_511,
                        cur_stats->tx_size_1023 - prev_stats->tx_size_1023,
                        cur_stats->tx_size_1522 - prev_stats->tx_size_1522,
                        cur_stats->tx_size_big - prev_stats->tx_size_big);

}

void ice_stat_update_rx(
        uint8_t *bar_addr, 
        uint32_t port, 
        struct ice_rx_stats *prev_stats, 
        struct ice_rx_stats *cur_stats,
        uint32_t *pkt_size)
{
    ice_stat_update40(bar_addr, GLPRT_GORCL(port) - MMAP_OFFSET,
            &prev_stats->rx_bytes,
            &cur_stats->rx_bytes);

    ice_stat_update40(bar_addr, GLPRT_UPRCL(port) - MMAP_OFFSET,
            &prev_stats->rx_unicast,
            &cur_stats->rx_unicast);

    ice_stat_update40(bar_addr, GLPRT_MPRCL(port) - MMAP_OFFSET,
            &prev_stats->rx_multicast,
            &cur_stats->rx_multicast);

    ice_stat_update40(bar_addr, GLPRT_BPRCL(port) - MMAP_OFFSET,
            &prev_stats->rx_broadcast,
            &cur_stats->rx_broadcast);

/*
    ice_stat_update32(bar_addr, PRTRPB_RDPC,
            &prev_stats->rx_discards,
            &cur_stats->rx_discards);
*/

    prev_stats->rx_total = cur_stats->rx_total;
    cur_stats->rx_total = cur_stats->rx_unicast + cur_stats->rx_multicast + cur_stats->rx_broadcast;
    //printf("[%s][RX] rx_bytes : %ld unicast : %ld multicast : %ld broadcast : %ld\n", __FUNCTION__, cur_stats->rx_bytes, cur_stats->rx_unicast, cur_stats->rx_multicast, cur_stats->rx_broadcast);

    ice_stat_update40(bar_addr, GLPRT_PRC64L(port) - MMAP_OFFSET,
            &prev_stats->rx_size_64, &cur_stats->rx_size_64);

    ice_stat_update40(bar_addr, GLPRT_PRC127L(port) - MMAP_OFFSET,
            &prev_stats->rx_size_127, &cur_stats->rx_size_127);

    ice_stat_update40(bar_addr, GLPRT_PRC255L(port) - MMAP_OFFSET,
            &prev_stats->rx_size_255, &cur_stats->rx_size_255);

    ice_stat_update40(bar_addr, GLPRT_PRC511L(port) - MMAP_OFFSET,
            &prev_stats->rx_size_511, &cur_stats->rx_size_511);

    ice_stat_update40(bar_addr, GLPRT_PRC1023L(port) - MMAP_OFFSET,
            &prev_stats->rx_size_1023, &cur_stats->rx_size_1023);

    ice_stat_update40(bar_addr, GLPRT_PRC1522L(port) - MMAP_OFFSET,
            &prev_stats->rx_size_1522, &cur_stats->rx_size_1522);

    ice_stat_update40(bar_addr, GLPRT_PRC9522L(port) - MMAP_OFFSET,
            &prev_stats->rx_size_big, &cur_stats->rx_size_big);

    ice_stat_update32(bar_addr, GLPRT_LXONRXC(port) - MMAP_OFFSET,
            &prev_stats->link_xon_rx, &cur_stats->link_xon_rx);

    ice_stat_update32(bar_addr, GLPRT_LXOFFRXC(port) - MMAP_OFFSET,
            &prev_stats->link_xoff_rx, &cur_stats->link_xoff_rx);

    ice_stat_update32(bar_addr, GLPRT_CRCERRS(port) - MMAP_OFFSET,
            &prev_stats->crc_errors, &cur_stats->crc_errors);

    ice_stat_update32(bar_addr, GLPRT_ILLERRC(port) - MMAP_OFFSET,
            &prev_stats->illegal_bytes, &cur_stats->illegal_bytes);

    ice_stat_update32(bar_addr, GLPRT_RLEC(port) - MMAP_OFFSET,
            &prev_stats->rx_len_errors, &cur_stats->rx_len_errors);

    ice_stat_update32(bar_addr, GLPRT_RUC(port) - MMAP_OFFSET,
            &prev_stats->rx_undersize, &cur_stats->rx_undersize);

    ice_stat_update32(bar_addr, GLPRT_RFC(port) - MMAP_OFFSET,
            &prev_stats->rx_fragments, &cur_stats->rx_fragments);

    ice_stat_update32(bar_addr, GLPRT_ROC(port) - MMAP_OFFSET,
            &prev_stats->rx_oversize, &cur_stats->rx_oversize);

    ice_stat_update32(bar_addr, GLPRT_RJC(port) - MMAP_OFFSET,
            &prev_stats->rx_jabber, &cur_stats->rx_jabber);

    ice_get_rx_pkt_size(prev_stats, cur_stats, pkt_size);
}

void ice_stat_update_tx(
        uint8_t *bar_addr, 
        uint32_t port, 
        struct ice_tx_stats *prev_stats, 
        struct ice_tx_stats *cur_stats,
        uint32_t *pkt_size)
{
    ice_stat_update40(bar_addr, GLPRT_GOTCL(port) - MMAP_OFFSET,
            &prev_stats->tx_bytes,
            &cur_stats->tx_bytes);

    ice_stat_update40(bar_addr, GLPRT_UPTCL(port) - MMAP_OFFSET,
            &prev_stats->tx_unicast,
            &cur_stats->tx_unicast);

    ice_stat_update40(bar_addr, GLPRT_MPTCL(port) - MMAP_OFFSET,
            &prev_stats->tx_multicast,
            &cur_stats->tx_multicast);

    ice_stat_update40(bar_addr, GLPRT_BPTCL(port) - MMAP_OFFSET,
            &prev_stats->tx_broadcast,
            &cur_stats->tx_broadcast);

    prev_stats->tx_total = cur_stats->tx_total;
    cur_stats->tx_total = cur_stats->tx_unicast + cur_stats->tx_multicast + cur_stats->tx_broadcast;
    //printf("[%s][TX] tx_bytes : %ld unicast : %ld multicast : %ld broadcast : %ld\n", __FUNCTION__, cur_stats->tx_bytes, cur_stats->tx_unicast, cur_stats->tx_multicast, cur_stats->tx_broadcast);

    ice_stat_update32(bar_addr, GLPRT_TDOLD(port) - MMAP_OFFSET,
            &prev_stats->tx_dropped_link_down,
            &cur_stats->tx_dropped_link_down);

    ice_stat_update40(bar_addr, GLPRT_PTC64L(port) - MMAP_OFFSET,
            &prev_stats->tx_size_64, &cur_stats->tx_size_64);

    ice_stat_update40(bar_addr, GLPRT_PTC127L(port) - MMAP_OFFSET,
            &prev_stats->tx_size_127, &cur_stats->tx_size_127);

    ice_stat_update40(bar_addr, GLPRT_PTC255L(port) - MMAP_OFFSET,
            &prev_stats->tx_size_255, &cur_stats->tx_size_255);

    ice_stat_update40(bar_addr, GLPRT_PTC511L(port) - MMAP_OFFSET,
            &prev_stats->tx_size_511, &cur_stats->tx_size_511);

    ice_stat_update40(bar_addr, GLPRT_PTC1023L(port) - MMAP_OFFSET,
            &prev_stats->tx_size_1023, &cur_stats->tx_size_1023);

    ice_stat_update40(bar_addr, GLPRT_PTC1522L(port) - MMAP_OFFSET,
            &prev_stats->tx_size_1522, &cur_stats->tx_size_1522);

    ice_stat_update40(bar_addr, GLPRT_PTC9522L(port) - MMAP_OFFSET,
            &prev_stats->tx_size_big, &cur_stats->tx_size_big);

    ice_stat_update32(bar_addr, GLPRT_LXONTXC(port) - MMAP_OFFSET,
            &prev_stats->link_xon_tx, &cur_stats->link_xon_tx);

    ice_stat_update32(bar_addr, GLPRT_LXOFFTXC(port) - MMAP_OFFSET,
            &prev_stats->link_xoff_tx, &cur_stats->link_xoff_tx);

    ice_stat_update32(bar_addr, GLPRT_MLFC(port) - MMAP_OFFSET,
            &prev_stats->mac_local_faults,
            &cur_stats->mac_local_faults);

    ice_stat_update32(bar_addr, GLPRT_MRFC(port) - MMAP_OFFSET,
            &prev_stats->mac_remote_faults,
            &cur_stats->mac_remote_faults);

    ice_get_tx_pkt_size(prev_stats, cur_stats, pkt_size);
}
