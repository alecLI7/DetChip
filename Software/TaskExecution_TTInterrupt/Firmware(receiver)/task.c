// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#include "firmware.h"
#include "../pkt_io/pkt_io.h"
#include "../timer_mg/timer_mg.h"
#include "../ptp_riscv/ptp_riscv.h"


int task_schedule(void)
{
    u32 pkt_len;
    u32* ts_rx_addr_tmp = (u32*)TS_SYSRAM_RX_PKT_ADDR;
    u32 interrupt_index = get_interrupt_index();
    u64 rx_window_lower, rx_window_upper;

    /*--- Packet processing test ---*/
    rx_window_lower = get_cur_time();
    rx_window_upper = ts_add(rx_window_lower, 0x1F400);       // window width is 1ms
    set_ts_rx_window(rx_window_lower, rx_window_upper);
    
    while (check_rx_overdue() == 0)
    {
        pkt_len = ts_rx_receive(ts_rx_addr_tmp);
        if (pkt_len != 0)
        {
            break;
        }
    }
    
    u64 cur_local_time  = get_local_time();
    u32 *print_reg_tmp  = (u32 *)0x20007774;
    u64 e2e_latency, send_timestamp;
    if (interrupt_index == *(ts_rx_addr_tmp+4))
    {
        send_timestamp = (u64)(*(ts_rx_addr_tmp + 5)) + ((u64)(*(ts_rx_addr_tmp + 6)) << 32);
        *print_reg_tmp = (u32)(send_timestamp);
        *print_reg_tmp = (u32)(send_timestamp >> 32);
        e2e_latency = ts_sub(cur_local_time, send_timestamp);
        *print_reg_tmp = (u32)(e2e_latency);
        *print_reg_tmp = (u32)(e2e_latency >> 32);
        *print_reg_tmp = pkt_len;
    }
    else{
        *print_reg_tmp = 0xdeadbeef;
    }

    return 0;
}

void timer_interrupt_table_init(void)
{
    unsigned int i;

    // set period = 10ms
    config_period(0x138800);

    // set time-triggered table[1]~[6] = 2, 3, ..., 7ms
    for (i = 1; i < 7; i++)
    {
        config_table_value(i, 0x1F400 * (i+1));
    }
    config_table_value(i, 0x0);     // clear the last entry of time-triggered table

    return;
}
