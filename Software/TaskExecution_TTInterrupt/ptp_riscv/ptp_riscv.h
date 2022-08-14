//delete by fsh and lcl7
//#include <iostream>
// #include <stdio.h>
// #include <stdlib.h>
// #include "string.h"
//#include <pthread.h>
// #include <malloc.h>
//#include <unistd.h>
//#include "../../include/np.h"
//#include "../timer/timer.h"
//#include "../../include/tools.h"

#include "../common.h"

typedef struct
{
    u8  offset_flag;
    u64 t1;
    u64 t2;
    u64 rorr1;
    u64 t3;
    u64 offset;
}ts_info;

typedef struct
{
    u32 inject_addr:5,
        pkttype:3,
        outport:9,
        lookup_en:1,
        reserve1:14;
    u32 reserve2;

}metedata;

typedef struct 
{
    u32 flow_type:3,
        flow_id:14,
        reserve1:15;
    u16 reserve2;
}ptp_TSNTag;

typedef struct
{
    u64 beats_field:7,
        microsecond_field:41,
        reserve:16;

}timeStamp;



typedef struct
{
	//MD
	u8 inject_addr:5,
        pkttype:3;
	u8 md[7];//
	
    u8 des_mac[6];  
    u8 src_mac[6];
    u16  eth_type:16;            // 16λ���������ֶ�
    u8   ptp_type:4,            //4λPTP�����ֶ�
         reserve1:4;
    u8  reserve2;
    u16 pkt_length;                 //16λ���ĳ���
    u16 reserve3;
    u16 reserve4;
    u8  corrField[8];             //�������ֶ�
    u16 reserve5;
    u32 reserve6[2];
    u32 reserve7[2];
    u16 reserve8;
    u8 timestamp[8];                       //ʱ����ֶ�
    u8 pad[6];                    //����ֶ�

}__attribute__((packed))ptp_pkt;

struct nmac_pkt
{

	u8 inject_addr:5,
        pkttype:3;
	u8 md[7];//

	u8 dst_mac[6];
	u8 src_mac[6];
	u16 ether_type;
	u8 count;
	u8 type;
	u32 addr;
	u32 data[27];
	
}__attribute__((packed));

int memset(void *s, int c, int n);

int memcpy(void *d, void *s, int n);

u64 corr_trans(u64 a);

u64 ts_add(u64 u1,u64 u2);

u64 ts_sub(u64 u1,u64 u2);

void ts_compute(void);

u32 htonl(u32 a);

u16 htons(u16 a);

u64 htonll(u64 a);

void htonl_pkt(u32* ptr);

void htonl_md_ts(u32* ptr);

void htonl_pkt_ts(u32* ptr);

u32 get_l_offset(u64 offset);

u32 get_h_offset(u64 offset, u8 offset_flag);

void md_transf_fun(u32 *tmp_md,u16 outport,u8 lookup_en,u8 frag_last);

void dmac_transf_tag(u32 *tmp_dmac,u8 flow_type,u16 flowid,u16 seqid,u8 frag_flag,u8 frag_id,u8 inject_addr,u8 submit_addr );

void smac_transf_tag(u32 *tmp_dmac,u8 flow_type,u16 flowid,u16 seqid,u8 frag_flag,u8 frag_id,u8 inject_addr,u8 submit_addr );

void   pkt_init(ptp_pkt* pkt);

u64  get_src_mac(ptp_pkt* pkt);

// void set_des_mac(ptp_pkt* pkt, u64 ptr);
u64 set_des_mac(ptp_pkt* pkt, u64 ptr);

u64 get_corr(ptp_pkt* pkt);

void set_corr(ptp_pkt* pkt, u64 corr);

u64 get_pkt_ts(ptp_pkt* pkt);

void set_pkt_ts(ptp_pkt* pkt,u64  ts);

u64 get_md_ts(ptp_pkt* pkt);

void set_md_ts(ptp_pkt* pkt,u64 ts);

int sync_pkt_build(ptp_pkt* pkt);   //����sync���ҷ���pkt

int delay_req_pkt_build(ptp_pkt* sync_pkt);   //����sync ����req

int delay_resp_pkt_build(ptp_pkt* req_pkt);         //����req ����resp

void delay_resp_pkt_handler(ptp_pkt* pkt);     //����

void print_pkt(ptp_pkt* pkt);

struct nmac_pkt *build_offset_pkt(u32 l_offset,u32 h_offset);

u64 mod_125(u64 a);

u64 divide_125(u64 a);


/*
void hx_ptp_contex_init();

int hx_ptp_contex_destroy();

void sync_ptp_msg_build(u8* pkt,u16 len,struct msg_node* msg);

void msg_rewrite(u8* pkt,u16 len,struct msg_node* msg );


void sync_handler_master(struct msg_quene* txq,struct buf_list * head_list,struct msg_node* msg);

void sync_handler_slave(struct msg_quene* txq,struct buf_list * head_list,struct msg_node* msg);

void delay_req_handler(struct msg_quene* txq,struct buf_list* head_list,struct msg_node* msg);

void delay_resp_handler(struct msg_node* msg,struct buf_list * head_list);
void hx_start_master_ptp();
void hx_start_slave_ptp();

void hx_star_ptp(void *argv);*/



