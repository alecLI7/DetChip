// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#include "pkt_io.h"

/* --> 阻塞式接收，没收到会持续等待 <--*/
int be_rx_receive(unsigned int *ptr)
{
    int i;
    /*- Registers for BE (regular) Rx_RAM -*/    
    unsigned int *rx_wr_pt          = (unsigned int *)RX_WR_PT_ADDR;        // 软硬件都可以访问的指针, 硬件写指针, 计算只用低3bit对应8个缓冲区
    unsigned int *rx_cur_pt         = (unsigned int *)RX_CUR_PT_ADDR;       // 当前指针，软件处理报文
    // unsigned int *rx_ram_full       = (unsigned int *)RX_RAM_FULL_ADDR;       // 判断缓存是否已满
    
    int result = 0;

    for (i = 0; ; i++)   // wait ready
    {          
        unsigned int tem1       = *rx_wr_pt       ;
        unsigned int tem2       = *rx_cur_pt      ;
        // unsigned int tem3       = *rx_ram_full    ;
        unsigned int bank_num   = 0               ;
        
        if (tem1 ^ tem2)  // rx_cur_pt != rx_wr_pt
        {    
            bank_num = tem2 & 0x7;

            unsigned int *rx_addr_tmp    = (unsigned int *)(RX_RAM_BASE_ADDR+bank_num*2048); //基地址+缓存块偏移
            unsigned int rx_desc_tmp     = *(rx_addr_tmp);
            unsigned int *rx_pkt_head_addr;
            
            unsigned int rx_pkt_size     = (rx_desc_tmp & 0x00FFF000) >> 12;

            unsigned int rx_pkt_des_addr = rx_desc_tmp & 0x00000FFC;   //地址映射
            
            rx_pkt_head_addr = rx_addr_tmp + (rx_pkt_des_addr >> 2);   //基地址+偏移地址（块内地址）
            
            //*(rx_pkt_head_addr) = 0xFFFFFFFF; // the first 4B set to 1;

            for(unsigned int k = 0; k < (rx_pkt_size >> 2); k++)
            {
                *(ptr + k) = *(rx_pkt_head_addr + k);
            }

            *rx_addr_tmp = rx_desc_tmp | 0x01000000;    //discard packet, to set the control bit
            // *rx_addr_tmp = rx_desc_tmp & 0xf0ffffff;    //forward packet, to set the control bit
            
            *rx_cur_pt = ((tem2 & 0xf) == 15) ? 0 : (tem2 + 1);  // only set low 4bit
            
            result = (int)rx_pkt_size;
            break;
        }    
    }
    return result;
}

/* --> 阻塞式发送，未能发送会持续等待 <--*/
void be_tx_send(unsigned int* ptr, unsigned int len)
{
    int i;
    /*- Registers for regular Tx_RAM -*/    
    unsigned int *tx_wr_pt      = (unsigned int *)TX_WR_PT_ADDR;       // 软件写指针
    // unsigned int *tx_rd_pt      = (unsigned int *)TX_RD_PT_ADDR;
    unsigned int *tx_ram_full   = (unsigned int *)TX_RAM_FULL_ADDR;

    for (i = 0; ; i++) {
        unsigned int tem1       = *tx_wr_pt       ;
        // unsigned int tem2       = *tx_rd_pt;
        unsigned int tem3       = *tx_ram_full    ;
        unsigned int bank_num   = 0               ;
        
        if ((tem3&0x00000001)!=0x00000001) {                        // not full
            bank_num = tem1 & 0x3;                                  // 计算只用低2bit对应4个缓冲区
            
            unsigned int *tx_addr_tmp = (unsigned int *)(TX_RAM_BASE_ADDR+bank_num*2048);
            *(tx_addr_tmp) = ( len << 12) | 0x00000010;             // set pkt_head_addr skip 4 32-bit block
            //*(tx_addr_tmp) = 0x00040012; // the first 4B set to 1;
            //tx_addr_tmp = tx_addr_tmp + (len>>2);
            tx_addr_tmp = tx_addr_tmp + 4;                          // skip 4 32-bit block
            for(unsigned int k = 0; k < ((len>>2)+1); k++)          // attention!! If len is not an integer multiple of 4
            {
                *(tx_addr_tmp + k) = *(ptr + k);
            }
            
            *(tx_wr_pt) = ((tem1 & 0xf) == 15) ? 0 : (tem1 + 1);    // only set low 4bit
            break;
        }
        else {
            continue;         // wait free ram block 
        }
    }
    return;    
}


int ts_rx_receive(unsigned int *ptr)
{
    /*- Registers for TS Rx_RAM -*/    
    unsigned int *ts_rx_wr_pt          = (unsigned int *)TS_RX_WR_PT_ADDR;       // 软硬件都可以访问的指针, 硬件写指针, 计算只用低3bit对应8个缓冲区
    unsigned int *ts_rx_cur_pt         = (unsigned int *)TS_RX_CUR_PT_ADDR;       // 当前指针，软件处理报文
    // unsigned int *ts_rx_ram_full       = (unsigned int *)TS_RX_RAM_FULL_ADDR;       // 判断缓存是否已满

    unsigned int tem1       = *ts_rx_wr_pt       ;
    unsigned int tem2       = *ts_rx_cur_pt      ;
    // unsigned int tem3       = *ts_rx_ram_full    ;
    unsigned int bank_num   = 0               ;
    
    if (tem1 ^ tem2)  // ts_rx_wr_pt != rx_wr_pt
    {    
        bank_num = tem2 & 0x7;

        unsigned int *ts_rx_addr_tmp    = (unsigned int *)(TS_RX_RAM_BASE_ADDR+bank_num*2048); //基地址+缓存块偏移
        unsigned int ts_rx_desc_tmp     = *(ts_rx_addr_tmp);
        unsigned int *ts_rx_pkt_head_addr;
        
        unsigned int ts_rx_pkt_size     = (ts_rx_desc_tmp & 0x00FFF000) >> 12;

        unsigned int ts_rx_pkt_des_addr = ts_rx_desc_tmp & 0x00000FFC;   //地址映射
        
        ts_rx_pkt_head_addr = ts_rx_addr_tmp + (ts_rx_pkt_des_addr >> 2);   //基地址+偏移地址（块内地址）
        
        //*(ts_rx_pkt_head_addr) = 0xFFFFFFFF; // the first 4B set to 1;

        for(unsigned int k = 0; k < (ts_rx_pkt_size >> 2); k++)
        {
            *(ptr + k) = *(ts_rx_pkt_head_addr + k);
        }

        *ts_rx_addr_tmp = ts_rx_desc_tmp | 0x01000000;      //discard packet, to set the control bit
        // *ts_rx_addr_tmp = ts_rx_desc_tmp & 0xf0ffffff;      //forward packet, to set the control bit
        
        *ts_rx_cur_pt = ((tem2 & 0xf) == 15) ? 0 : (tem2 + 1);  // only set low 4bit

        return ts_rx_pkt_size;   // receieve success
    }    
    
    return 0;      // did not receive packet
}

int ts_tx_send(unsigned int* ptr, unsigned int len)
{
    /*- Registers for regular Tx_RAM -*/    
    unsigned int *ts_tx_wr_pt      = (unsigned int *)TS_TX_WR_PT_ADDR;       // 软件写指针
    // unsigned int *ts_tx_rd_pt      = (unsigned int *)TS_TX_RD_PT_ADDR;
    unsigned int *ts_tx_ram_full   = (unsigned int *)TS_TX_RAM_FULL_ADDR;

    
    unsigned int tem1       = *ts_tx_wr_pt       ;
    // unsigned int tem2       = *ts_tx_rd_pt;
    unsigned int tem3       = *ts_tx_ram_full    ;
    unsigned int bank_num   = 0                  ;
    
    if ((tem3&0x00000001)!=0x00000001) {                        // not full
        bank_num = tem1 & 0x3;                                  // 计算只用低2bit对应4个缓冲区
        
        unsigned int *ts_tx_addr_tmp = (unsigned int *)(TS_TX_RAM_BASE_ADDR+bank_num*2048);
        *(ts_tx_addr_tmp) = ( len << 12) | 0x00000010;          // set pkt_head_addr skip 4 32-bit block
        //*(ts_tx_addr_tmp) = 0x00040012; // the first 4B set to 1;
        //ts_tx_addr_tmp = tx_addr_tmp + (len>>2);
        ts_tx_addr_tmp = ts_tx_addr_tmp + 4;                    // skip 4 32-bit block
        for(unsigned int k = 0; k < ((len>>2)+1); k++)          // attention!! If len is not an integer multiple of 4
        {
            *(ts_tx_addr_tmp + k) = *(ptr + k);
        }
        
        *(ts_tx_wr_pt) = ((tem1 & 0xf) == 15) ? 0 : (tem1 + 1);    // only set low 4bit
        
        return 0;   // send success
    }

    return -1;      // did not send packet
}

void build_be_pkt_for_test(unsigned int* ptr, unsigned int len, unsigned long long timestamp, unsigned int counter)
{ 
    unsigned int i; 
    *(ptr + 0) = 0xd27ddb87;
    *(ptr + 1) = 0x34b1d46d;
    *(ptr + 2) = 0x6d61685e;
    *(ptr + 3) = 0x08000000;        // IPv4 eth_type
    *(ptr + 4) = counter;
    *(ptr + 5) = (unsigned int)(timestamp);
    *(ptr + 6) = (unsigned int)(timestamp >> 32);
    for (i = 7; i < ((len >> 2)-1); i++)               // attention!! If len is not an integer multiple of 4
    {
        *(ptr + i) = 0x00000000;
    }
    *(ptr + i) = 0xbaadcafe;

    return;
}

void build_ts_pkt_for_test(unsigned int* ptr, unsigned int len, unsigned long long timestamp, unsigned int interrupt_index)
{  
    unsigned int i;
    *(ptr + 0) = 0x80220000;
    *(ptr + 1) = 0x08008090;
    *(ptr + 2) = 0x00000800;
    *(ptr + 3) = 0x98f70000;        // PTP eth_type
    *(ptr + 4) = interrupt_index;
    *(ptr + 5) = (unsigned int)(timestamp);
    *(ptr + 6) = (unsigned int)(timestamp >> 32);
    for (i = 7; i < ((len >> 2)-1); i++)               // attention!! If len is not an integer multiple of 4
    {
        *(ptr + i) = 0x00000000;
    }    
    *(ptr + i) = 0xbaadcafe;

    return;
}

/* 
 * return value:
 *      1  is TS pkt (skip check for BE pkt)
 *      0  is BE pkt (i.e. no TS pkt)
 *      -1 is no pkt
 */
int receive_pkt_type_check(void)
{
    unsigned int tem1;
    unsigned int tem2;

    /*- Registers for TS Rx_RAM -*/    
    unsigned int *ts_rx_wr_pt          = (unsigned int *)TS_RX_WR_PT_ADDR;       // 软硬件都可以访问的指针, 硬件写指针, 计算只用低3bit对应8个缓冲区
    unsigned int *ts_rx_cur_pt         = (unsigned int *)TS_RX_CUR_PT_ADDR;       // 当前指针，软件处理报文

    tem1       = *ts_rx_wr_pt       ;
    tem2       = *ts_rx_cur_pt      ;   
    if (tem1 ^ tem2)  // ts_rx_wr_pt != rx_wr_pt
    {
        return 1;
    }
    
    /*- Registers for BE (regular) Rx_RAM -*/    
    unsigned int *rx_wr_pt          = (unsigned int *)RX_WR_PT_ADDR;        // 软硬件都可以访问的指针, 硬件写指针, 计算只用低3bit对应8个缓冲区
    unsigned int *rx_cur_pt         = (unsigned int *)RX_CUR_PT_ADDR;       // 当前指针，软件处理报文

    tem1       = *rx_wr_pt       ;
    tem2       = *rx_cur_pt      ;
    if (tem1 ^ tem2)  // rx_cur_pt != rx_wr_pt
    {
        return 0;
    }
    
    return -1;
}