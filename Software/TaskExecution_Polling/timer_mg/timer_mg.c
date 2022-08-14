// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#include "timer_mg.h"

void config_period(u64 period)
{
    u32 *config_value_l   = (u32 *)CONFIG_VALUE_L_ADDR;
    u32 *config_value_h   = (u32 *)CONFIG_VALUE_H_ADDR;
    u32 *config_index     = (u32 *)CONFIG_INDEX_ADDR;
    u32 *config_en        = (u32 *)CONFIG_EN_ADDR;

    *config_value_l = (u32)(period);
    *config_value_h = (u32)(period >> 32);
    *config_index   = 0xffffffff;
    *config_en      = 0x1;
    return;
}

void config_table_value(u32 index, u64 value)
{
    u32 *config_value_l   = (u32 *)CONFIG_VALUE_L_ADDR;
    u32 *config_value_h   = (u32 *)CONFIG_VALUE_H_ADDR;
    u32 *config_index     = (u32 *)CONFIG_INDEX_ADDR;
    u32 *config_en        = (u32 *)CONFIG_EN_ADDR;

    *config_value_l = (u32)(value);
    *config_value_h = (u32)(value >> 32);
    *config_index   = index;
    *config_en      = 0x1;
    return;
}

void config_offset(u64 offset)
{
    u32 * offset_l  = (u32 *)OFFSET_L_ADDR;
    u32 * offset_h  = (u32 *)OFFSET_H_ADDR;
    u32 * offset_en = (u32 *)OFFSET_EN_ADDR;

    *offset_l       = (u32)(offset);
    *offset_h       = (u32)(offset >> 32);
    *offset_en      = 0x1;
    return;
}

u64 get_local_time(void)
{
    u64 result = 0;
    u32 * local_time_l     = (u32 *)LOCAL_TIME_L_ADDR;
    u32 * local_time_h     = (u32 *)LOCAL_TIME_H_ADDR;

    result = ((u64)(*local_time_h) << 32) + (u64)(*local_time_l);

    return result;
}

u64 get_cur_time(void)
{
    u64 result = 0;
    u32 * cur_time_l     = (u32 *)CUR_TIME_L_ADDR;
    u32 * cur_time_h     = (u32 *)CUR_TIME_H_ADDR;

    result = ((u64)(*cur_time_h) << 32) + (u64)(*cur_time_l);

    return result;
}

u32 get_interrupt_index(void)
{
    u32 * interrupt_index  = (u32 *)INTERRUPT_INDEX_ADDR;
    return *interrupt_index;
}

void set_ts_rx_window(u64 lower, u64 upper)
{
    u32 *  ts_rx_window_lower_l = (u32 *)TS_RX_WINDOW_LOWER_L_ADDR;
    u32 *  ts_rx_window_lower_h = (u32 *)TS_RX_WINDOW_LOWER_H_ADDR;
    u32 *  ts_rx_window_upper_l = (u32 *)TS_RX_WINDOW_UPPER_L_ADDR;
    u32 *  ts_rx_window_upper_h = (u32 *)TS_RX_WINDOW_UPPER_H_ADDR;
    u32 *  ts_rx_valid          = (u32 *)TS_RX_VALID_ADDR;

    *ts_rx_valid          = 0x0;
    clear_rx_overdue();
    *ts_rx_window_lower_l = (u32)(lower);
    *ts_rx_window_lower_h = (u32)(lower >> 32);
    *ts_rx_window_upper_l = (u32)(upper);
    *ts_rx_window_upper_h = (u32)(upper >> 32);
    *ts_rx_valid          = 0x1;

    return;   
}

void set_ts_tx_window(u64 lower, u64 upper)
{
    u32 *  ts_tx_window_lower_l = (u32 *)TS_TX_WINDOW_LOWER_L_ADDR;
    u32 *  ts_tx_window_lower_h = (u32 *)TS_TX_WINDOW_LOWER_H_ADDR;
    u32 *  ts_tx_window_upper_l = (u32 *)TS_TX_WINDOW_UPPER_L_ADDR;
    u32 *  ts_tx_window_upper_h = (u32 *)TS_TX_WINDOW_UPPER_H_ADDR;
    u32 *  ts_tx_valid          = (u32 *)TS_TX_VALID_ADDR;

    *ts_tx_valid          = 0x0;
    clear_tx_overdue();
    *ts_tx_window_lower_l = (u32)(lower);
    *ts_tx_window_lower_h = (u32)(lower >> 32);
    *ts_tx_window_upper_l = (u32)(upper);
    *ts_tx_window_upper_h = (u32)(upper >> 32);
    *ts_tx_valid          = 0x1;

    return;
}

int check_rx_overdue(void)
{
    u32 *  ts_rx_overdue        = (u32 *)TS_RX_OVERDUE_ADDR;

    return (*ts_rx_overdue & 0x00000001);
}

int check_tx_overdue(void)
{
    u32 *  ts_tx_overdue        = (u32 *)TS_TX_OVERDUE_ADDR;

    return (*ts_tx_overdue & 0x00000001);
}

void clear_rx_overdue(void)
{
    u32 *  ts_rx_overdue        = (u32 *)TS_RX_OVERDUE_ADDR;

    *ts_rx_overdue = 0x0;
    return;
}

void clear_tx_overdue(void)
{
    u32 *  ts_tx_overdue        = (u32 *)TS_TX_OVERDUE_ADDR;

    *ts_tx_overdue = 0x0;
    return;
}