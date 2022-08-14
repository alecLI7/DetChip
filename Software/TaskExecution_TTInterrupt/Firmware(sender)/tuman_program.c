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

int g_BE_SEND_MODE = 0;                           // 0 is Stable Mode, 1 is Burst Mode

int master_hardware_initial(void)
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
    *(ts_start_cfg)                    = 0x00000007;       // Big-end, TS_TX_EN, TS_RX_EN

    return 0;
}

void tuman_program(void)
{
    int ret;

    ret = master_hardware_initial();
    if (ret != 0)
    {
        return;
    }
    
    /*--> Send BE packet <--*/
    unsigned int i = 0;
    unsigned int j = 0;
    unsigned long long cur_local_time;
    u32* tx_addr_tmp = (u32*)BE_SYSRAM_TX_PKT_ADDR;
    unsigned int be_pkt_len = 64;
    unsigned int block_num = 128;
    unsigned int rand_tmp;

    while(1)
    {
        /* --> Version 1: burst send interval <-- */
        // cur_local_time = get_local_time();
        // build_be_pkt_for_test(tx_addr_tmp, be_pkt_len, cur_local_time, i);
        // be_tx_send((unsigned int *)tx_addr_tmp, be_pkt_len);
        // memset(tx_addr_tmp, 0, be_pkt_len);

        // if (g_BE_SEND_MODE == 0)        // Stable Mode
        // {
        //     j = 0;
        //     while(j < block_num)
        //     {
        //         j = j + 1;
        //     }
        // }
        // else if (g_BE_SEND_MODE == 1)   // Burst Mode
        // {
        //     rand_tmp = (1 + ((unsigned int)cur_local_time & 0x7)) << 7;     // get random method is (local_time mod 8)
        //     j = 0;
        //     while(j < rand_tmp)
        //     {
        //         j = j + 1;
        //     }
        // }

        /* --> Version 2: burst packet length <-- */
        cur_local_time = get_local_time();
        if (g_BE_SEND_MODE == 0)        // Stable Mode
        {
            build_be_pkt_for_test(tx_addr_tmp, be_pkt_len, cur_local_time, i);
            be_tx_send((unsigned int *)tx_addr_tmp, be_pkt_len);
            memset(tx_addr_tmp, 0, be_pkt_len);
        }
        else if (g_BE_SEND_MODE == 1)   // Burst Mode
        {
            rand_tmp = be_pkt_len << ((unsigned int)cur_local_time & 0x3);      // get random method is (local_time mod 4)
            if (rand_tmp == 512) { rand_tmp = 64;}                              // random BE packet length arrange is [64, 128, 256, 64]
            
            build_be_pkt_for_test(tx_addr_tmp, rand_tmp, cur_local_time, i);
            be_tx_send((unsigned int *)tx_addr_tmp, rand_tmp);
            memset(tx_addr_tmp, 0, rand_tmp);
        }     
        
        j = 0;
        while(j < block_num)
        {
            j = j + 1;
        }
        i = (i == 1024) ? 0: (i+1);   
    }
    return;   
}
