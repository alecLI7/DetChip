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


extern int g_BE_SEND_MODE;              // 0 is Stable Mode, 1 is Burst Mode

int task_schedule(void)
{
    int ret;
    u32 pkt_len         = 64;
    u32* ts_tx_addr_tmp = (u32*)TS_SYSRAM_TX_PKT_ADDR;
    u32 interrupt_index = get_interrupt_index();
    u64 tx_window_lower, tx_window_upper;
    
    /*--- Packet processing test ---*/
    // pkt_len = (interrupt_index == 6) ? (1518) : (pkt_len << (interrupt_index - 1 ));
    tx_window_lower  = get_cur_time();
    tx_window_upper = ts_add(tx_window_lower, 0x1F400);       // window width is 1ms
    set_ts_tx_window(tx_window_lower, tx_window_upper);
    
    u64 cur_local_time  = get_local_time();
    build_ts_pkt_for_test(ts_tx_addr_tmp, pkt_len, cur_local_time, interrupt_index);
    
    while (check_tx_overdue() == 0)
    {
        ret = ts_tx_send(ts_tx_addr_tmp, pkt_len);
        if (ret == 0)
        {
            break;
        }
    }

    // change BE send mode after each schedule period (normal <-> burst)
    if (interrupt_index == 6)
    {
        g_BE_SEND_MODE = (g_BE_SEND_MODE == 0) ? (1) : (0);
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
