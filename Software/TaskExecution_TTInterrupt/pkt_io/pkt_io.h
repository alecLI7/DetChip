// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#define RX_RAM_BASE_ADDR            0X21000000
#define TX_RAM_BASE_ADDR            0X22000000
#define TS_RX_RAM_BASE_ADDR         0X23000000
#define TS_TX_RAM_BASE_ADDR         0X24000000

#define START_CFG_ADDR              0X20000000
#define INTERRUPT_MASK_ADDR         0X20000040
#define FIX_PPS0_INV_L_ADDR         0X200000c8
#define FIX_PPS0_INV_H_ADDR         0X200000cc

#define RX_WR_PT_ADDR               0X20000080
#define RX_CUR_PT_ADDR              0X20000084
#define RX_RD_PT_ADDR               0X20000088
#define TX_WR_PT_ADDR               0X2000008c
#define TX_RD_PT_ADDR               0X20000090
#define RX_RAM_FULL_ADDR            0X20000094
#define TX_RAM_FULL_ADDR            0X20000098

#define TS_RX_WR_PT_ADDR            0X2000009c
#define TS_RX_CUR_PT_ADDR           0X200000a0
#define TS_RX_RD_PT_ADDR            0X200000a4
#define TS_TX_WR_PT_ADDR            0X200000a8
#define TS_TX_RD_PT_ADDR            0X200000ac
#define TS_RX_RAM_FULL_ADDR         0X200000b0
#define TS_TX_RAM_FULL_ADDR         0X200000b4

#define TS_START_CFG_ADDR           0X20000100

#define BE_SYSRAM_RX_PKT_ADDR       0x0000df00
#define BE_SYSRAM_TX_PKT_ADDR       0x0000e700
#define TS_SYSRAM_RX_PKT_ADDR       0x0000ef00
#define TS_SYSRAM_TX_PKT_ADDR       0x0000f700

// pkt_io.c
int be_rx_receive(unsigned int *ptr);

void be_tx_send(unsigned int* ptr, unsigned int len);

int ts_rx_receive(unsigned int *ptr);

int ts_tx_send(unsigned int* ptr, unsigned int len);

void build_be_pkt_for_test(unsigned int* ptr, unsigned int len, unsigned long long timestamp, unsigned int counter);

void build_ts_pkt_for_test(unsigned int* ptr, unsigned int len, unsigned long long timestamp, unsigned int interrupt_index);