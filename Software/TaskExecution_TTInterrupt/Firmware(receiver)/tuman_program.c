// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#include <stdio.h>
// #include <time.h>
// #include <stdlib.h>
// #include <string.h>

#include "../ptp_riscv/ptp_riscv.h"
#include "../pkt_io/pkt_io.h"
#include "../timer_mg/timer_mg.h"
#include "firmware.h"


int slave_hardware_initial(void)
{
    unsigned int *start_cfg         = (unsigned int *)START_CFG_ADDR;
    unsigned int *interrupt_mask    = (unsigned int *)INTERRUPT_MASK_ADDR;
    unsigned int *fix_pps0_inv_l    = (unsigned int *)FIX_PPS0_INV_L_ADDR;
    unsigned int *fix_pps0_inv_h    = (unsigned int *)FIX_PPS0_INV_H_ADDR;

    unsigned int *ts_start_cfg      = (unsigned int *)TS_START_CFG_ADDR;

    /*--- init registers for BE task ---*/
    // *(interrupt_mask)               = 0x00000002;
    // *(fix_pps0_inv_l)               = 0x0001E848;       // 1ms
    // *(fix_pps0_inv_l)               = 0x001312D0;       // 10ms
    // *(fix_pps0_inv_l)               = 0x00bebc20;       // 100ms 
    // *(fix_pps0_inv_h)               = 0x80000000;       // enable
    *(interrupt_mask)               = 0x00000000;
    *(fix_pps0_inv_l)               = 0x00000000;
    *(fix_pps0_inv_h)               = 0x00000000;
    *(start_cfg)                    = 0x00000007;          // Big-end, TX_EN, RX_EN

    /*--- init registers for TS task ---*/
    timer_interrupt_table_init();
    *(ts_start_cfg)                 = 0x00000007;          // Big-end, TS_TX_EN, TS_RX_EN

    return 0;
}

void tuman_program(void)
{
    int ret;
    unsigned int i;

    ret = slave_hardware_initial();
    if (ret != 0)
    {
        return;
    }
    
    /*--> Receivce BE packet <--*/
    // i= 0;
    // u32 pkt_len;
    // u64 e2e_latency, send_timestamp, recv_timestamp;
    // u32* rx_addr_tmp = (u32*)BE_SYSRAM_RX_PKT_ADDR;
    // u32 *print_reg_tmp  = (u32 *)0x20006674;
    // while(1)
    // {
    //     pkt_len = be_rx_receive(rx_addr_tmp);
    //     recv_timestamp = get_local_time();
    //     send_timestamp = (u64)(*(rx_addr_tmp + 5)) + ((u64)(*(rx_addr_tmp + 6)) << 32);
    //     *print_reg_tmp = (u32)(send_timestamp);
    //     *print_reg_tmp = (u32)(send_timestamp >> 32);
    //     e2e_latency = ts_sub(recv_timestamp, send_timestamp);
    //     *print_reg_tmp = (u32)(e2e_latency);
    //     *print_reg_tmp = (u32)(e2e_latency >> 32);
    //     *print_reg_tmp = pkt_len;

    //     i = (i == 1024) ? 0: (i+1);
        
    // }

    /*--> No BE packet <--*/
    i= 0;
    while(1)
    {
        i = (i == 1024) ? 0: (i+1);
    }

    return;
}






    










    





