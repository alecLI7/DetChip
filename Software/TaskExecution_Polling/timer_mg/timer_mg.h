// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#include "../common.h"

#define LOCAL_TIME_L_ADDR         0x25000000
#define LOCAL_TIME_H_ADDR         0x25000004
#define INTERRUPT_INDEX_ADDR      0x25000008
#define OFFSET_EN_ADDR            0x2500000c
#define OFFSET_L_ADDR             0x25000010
#define OFFSET_H_ADDR             0x25000014
#define CONFIG_EN_ADDR            0x25000018
#define CONFIG_VALUE_L_ADDR       0x2500001c
#define CONFIG_VALUE_H_ADDR       0x25000020
#define CONFIG_INDEX_ADDR         0x25000024
#define CUR_TIME_L_ADDR           0x25000028
#define CUR_TIME_H_ADDR           0x2500002c

#define TS_RX_VALID_ADDR            0X20000104
#define TS_RX_OVERDUE_ADDR          0X20000108
#define TS_RX_WINDOW_LOWER_L_ADDR   0X2000010c
#define TS_RX_WINDOW_LOWER_H_ADDR   0X20000110
#define TS_RX_WINDOW_UPPER_L_ADDR   0X20000114
#define TS_RX_WINDOW_UPPER_H_ADDR   0X20000118
#define TS_TX_VALID_ADDR            0X2000011c
#define TS_TX_OVERDUE_ADDR          0X20000120
#define TS_TX_WINDOW_LOWER_L_ADDR   0X20000124
#define TS_TX_WINDOW_LOWER_H_ADDR   0X20000128
#define TS_TX_WINDOW_UPPER_L_ADDR   0X2000012c
#define TS_TX_WINDOW_UPPER_H_ADDR   0X20000130

// timer_mg.c
void config_period(u64 period);

void config_table_value(u32 index, u64 value);

void config_offset(u64 offset);

u64 get_local_time(void);

u64 get_cur_time(void);

u32 get_interrupt_index(void);

void set_ts_rx_window(u64 lower, u64 upper);

void set_ts_tx_window(u64 lower, u64 upper);

int check_rx_overdue(void);

int check_tx_overdue(void);

void clear_rx_overdue(void);

void clear_tx_overdue(void);