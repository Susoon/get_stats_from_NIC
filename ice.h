#ifndef ICE_H
#define ICE_H

#include <linux/types.h>

#define QTX_COMM_DBELL(_DBQM)           (0x002C0000 + ((_DBQM) * 4)) /* _i=0...16383 */ /* Reset Source: CORER */
#define QTX_COMM_DBELL_WITH_MMAP_OFFSET(_DBQM)           (0x000C0000 + ((_DBQM) * 4)) /* _i=0...16383 */ /* Reset Source: CORER */

#define QRX_TAIL(_QRX)              (0x00290000 + ((_QRX) * 4)) /* _i=0...2047 */ /* Reset Source: CORER */
#define QRX_TAIL_WITH_MMAP_OFFSET(_QRX)              (0x00090000 + ((_QRX) * 4)) /* _i=0...2047 */ /* Reset Source: CORER */

//#define IXGBE_TXD_STAT_DD 0x00000001 /* Descriptor Done */

#define ICE_TXD_QW1_DTYPE_S 0
#define ICE_TXD_QW1_DTYPE_M (0xFUL << ICE_TXD_QW1_DTYPE_S)

#define ICE_TXD_QW1_OFFSET_S    16
#define ICE_TXD_QW1_OFFSET_M    (0x3FFFFULL << ICE_TXD_QW1_OFFSET_S)

#define ICE_TXD_QW1_CMD_S   4
#define ICE_TXD_QW1_CMD_M   (0xFFFUL << ICE_TXD_QW1_CMD_S)

#define ICE_TXD_QW1_TX_BUF_SZ_S 34
#define ICE_TXD_QW1_TX_BUF_SZ_M (0x3FFFULL << ICE_TXD_QW1_TX_BUF_SZ_S)

#define ICE_TXD_QW1_L2TAG1_S    48
#define ICE_TXD_QW1_L2TAG1_M    (0xFFFFULL << ICE_TXD_QW1_L2TAG1_S)

enum ice_tx_desc_dtype_value {
    ICE_TX_DESC_DTYPE_DATA      = 0x0,
    ICE_TX_DESC_DTYPE_CTX       = 0x1,
    ICE_TX_DESC_DTYPE_IPSEC     = 0x3,
    ICE_TX_DESC_DTYPE_FLTR_PROG = 0x8,
    ICE_TX_DESC_DTYPE_HLP_META  = 0x9,
    /* DESC_DONE - HW has completed write-back of descriptor */
    ICE_TX_DESC_DTYPE_DESC_DONE = 0xF,
};

enum ice_tx_desc_cmd_bits {
    ICE_TX_DESC_CMD_EOP         = 0x0001,
    ICE_TX_DESC_CMD_RS          = 0x0002,
    ICE_TX_DESC_CMD_RSVD            = 0x0004,
    ICE_TX_DESC_CMD_IL2TAG1         = 0x0008,
    ICE_TX_DESC_CMD_DUMMY           = 0x0010,
    ICE_TX_DESC_CMD_IIPT_NONIP      = 0x0000,
    ICE_TX_DESC_CMD_IIPT_IPV6       = 0x0020,
    ICE_TX_DESC_CMD_IIPT_IPV4       = 0x0040,
    ICE_TX_DESC_CMD_IIPT_IPV4_CSUM      = 0x0060,
    ICE_TX_DESC_CMD_RSVD2           = 0x0080,
    ICE_TX_DESC_CMD_L4T_EOFT_UNK        = 0x0000,
    ICE_TX_DESC_CMD_L4T_EOFT_TCP        = 0x0100,
    ICE_TX_DESC_CMD_L4T_EOFT_SCTP       = 0x0200,
    ICE_TX_DESC_CMD_L4T_EOFT_UDP        = 0x0300,
    ICE_TX_DESC_CMD_RE          = 0x0400,
    ICE_TX_DESC_CMD_RSVD3           = 0x0800,
};

#define ICE_TXD_LAST_DESC_CMD (ICE_TX_DESC_CMD_EOP | ICE_TX_DESC_CMD_RS)

#define ICE_RX_FLX_DESC_PKT_LEN_M   (0x3FFF) /* 14-bits */

enum ice_rx_desc_status_bits {
    /* Note: These are predefined bit offsets */
    ICE_RX_DESC_STATUS_DD_S         = 0,
    ICE_RX_DESC_STATUS_EOF_S        = 1,
    ICE_RX_DESC_STATUS_L2TAG1P_S        = 2,
    ICE_RX_DESC_STATUS_L3L4P_S      = 3,
    ICE_RX_DESC_STATUS_CRCP_S       = 4,
    ICE_RX_DESC_STATUS_TSYNINDX_S       = 5,
    ICE_RX_DESC_STATUS_TSYNVALID_S      = 7,
    ICE_RX_DESC_STATUS_EXT_UDP_0_S      = 8,
    ICE_RX_DESC_STATUS_UMBCAST_S        = 9,
    ICE_RX_DESC_STATUS_FLM_S        = 11,
    ICE_RX_DESC_STATUS_FLTSTAT_S        = 12,
    ICE_RX_DESC_STATUS_LPBK_S       = 14,
    ICE_RX_DESC_STATUS_IPV6EXADD_S      = 15,
    ICE_RX_DESC_STATUS_RESERVED2_S      = 16,
    ICE_RX_DESC_STATUS_INT_UDP_0_S      = 18,
    ICE_RX_DESC_STATUS_LAST /* this entry must be last!!! */
};

enum ice_rx_flex_desc_status_error_0_bits {
    /* Note: These are predefined bit offsets */
    ICE_RX_FLEX_DESC_STATUS0_DD_S = 0,
    ICE_RX_FLEX_DESC_STATUS0_EOF_S,
    ICE_RX_FLEX_DESC_STATUS0_HBO_S,
    ICE_RX_FLEX_DESC_STATUS0_L3L4P_S,
    ICE_RX_FLEX_DESC_STATUS0_XSUM_IPE_S,
    ICE_RX_FLEX_DESC_STATUS0_XSUM_L4E_S,
    ICE_RX_FLEX_DESC_STATUS0_XSUM_EIPE_S,
    ICE_RX_FLEX_DESC_STATUS0_XSUM_EUDPE_S,
    ICE_RX_FLEX_DESC_STATUS0_LPBK_S,
    ICE_RX_FLEX_DESC_STATUS0_IPV6EXADD_S,
    ICE_RX_FLEX_DESC_STATUS0_RXE_S,
    ICE_RX_FLEX_DESC_STATUS0_CRCP_S,
    ICE_RX_FLEX_DESC_STATUS0_RSS_VALID_S,
    ICE_RX_FLEX_DESC_STATUS0_L2TAG1P_S,
    ICE_RX_FLEX_DESC_STATUS0_XTRMD0_VALID_S,
    ICE_RX_FLEX_DESC_STATUS0_XTRMD1_VALID_S,
    ICE_RX_FLEX_DESC_STATUS0_LAST /* this entry must be last!!! */
};

#define BIT(nr)         (1UL << (nr))

#define ICE_RXD_QW1_STATUS_S    0
#define ICE_RXD_QW1_STATUS_M    ((BIT(ICE_RX_DESC_STATUS_LAST) - 1) << \
                 ICE_RXD_QW1_STATUS_S)


// CKJUNG. 21.11.01. We never used this variable.. lol.
//#define IXGBE_RXD_STAT_EOP  0x02 /* End of Packet */

/* Tx Descriptor */
struct ice_tx_desc {
    __le64 buf_addr; /* Address of descriptor's data buf */
    __le64 cmd_type_offset_bsz;
    //uint8_t padding[112];
};

#define u8 uint8_t

/* Rx Flex Descriptors
 * These descriptors are used instead of the legacy version descriptors when
 * ice_rlan_ctx.adv_desc is set
 */

union ice_32b_rx_flex_desc {
    struct {
        __le64 pkt_addr; /* Packet buffer address */
        __le64 hdr_addr; /* Header buffer address */
                 /* bit 0 of hdr_addr is DD bit */
        __le64 rsvd1;
        __le64 rsvd2;
    } read;
    struct {
        /* Qword 0 */
        u8 rxdid; /* descriptor builder profile ID */
        u8 mir_id_umb_cast; /* mirror=[5:0], umb=[7:6] */
        __le16 ptype_flex_flags0; /* ptype=[9:0], ff0=[15:10] */
        __le16 pkt_len; /* [15:14] are reserved */
        __le16 hdr_len_sph_flex_flags1; /* header=[10:0] */
                        /* sph=[11:11] */
                        /* ff1/ext=[15:12] */

        /* Qword 1 */
        __le16 status_error0;
        __le16 l2tag1;
        __le16 flex_meta0;
        __le16 flex_meta1;

        /* Qword 2 */
        __le16 status_error1;
        u8 flex_flags2;
        u8 time_stamp_low;
        __le16 l2tag2_1st;
        __le16 l2tag2_2nd;

        /* Qword 3 */
        __le16 flex_meta2;
        __le16 flex_meta3;
        union {
            struct {
                __le16 flex_meta4;
                __le16 flex_meta5;
            } flex;
            __le32 ts_high;
        } flex_ts;
    } wb; /* writeback */
    //uint8_t padding[96];
};

union ice_32byte_rx_desc {
    struct {
        __le64 pkt_addr; /* Packet buffer address */
        __le64 hdr_addr; /* Header buffer address */
            /* bit 0 of hdr_addr is DD bit */
        __le64 rsvd1;
        __le64 rsvd2;
    } read;
    struct {
        struct {
            struct {
                __le16 mirroring_status;
                __le16 l2tag1;
            } lo_dword;
            union {
                __le32 rss; /* RSS Hash */
                __le32 fd_id; /* Flow Director filter ID */
            } hi_dword;
        } qword0;
        struct {
            /* status/error/PTYPE/length */
            __le64 status_error_len;
        } qword1;
        struct {
            __le16 ext_status; /* extended status */
            __le16 rsvd;
            __le16 l2tag2_1;
            __le16 l2tag2_2;
        } qword2;
        struct {
            __le32 reserved;
            __le32 fd_id;
        } qword3;
    } wb; /* writeback */
    uint8_t padding[96];
};


#endif /* ICE_H */
