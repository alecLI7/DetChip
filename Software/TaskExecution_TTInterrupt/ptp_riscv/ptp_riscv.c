
#include "ptp_riscv.h"
//#include "types.h"

#define mod_128(x) (x & (128-1))

//int m_s_flag = 0;         //锟斤拷志位为1时 为锟斤拷时锟接ｏ拷为0时为锟斤拷时锟斤拷

u16 ptp_multicast_imac  = 0x1000;
u16 ptp_master_imac     = 0x3;
u16 ptp_slave_imac      = 0x0;

u64 global_t1           = 0x22684;
u64 global_t2           = 0x22b84;
u64 global_t3           = 0x304;
u64 global_t4           = 0x285;

ts_info global_ts_info = {0};


int memset(void *s, int c, int n)
{
	// if (NULL == s || n < 0)
    if (n < 0)
		return -1;
	unsigned int * tmpS = (unsigned int *)s;
    while(1)
    {
        if(n-4 > 0)
        {
            *tmpS = c;
            tmpS = tmpS + 1;
        }
        else
        {
            *tmpS = c;
            tmpS = tmpS + 1;
            return 0;
        }
        n = n - 4;
    }
}

int memcpy(void *d, void *s, int n)
{
	// if (NULL == s || n < 0)
    if (n < 0)
		return -1;
	unsigned int * tmpS = (unsigned int *)s;
    unsigned int * tmpD = (unsigned int *)d;
    while(1)
    {
        if(n-4 > 0)
        {
            *tmpD = *tmpS;
            tmpS = tmpS + 1;
            tmpD = tmpD + 1;
        }
        else
        {
            // changed by LCL7. --> maybe error
            *tmpD = ((*tmpS << (4-n)) >> (4-n)) + ((*tmpD >> n) << n);
            return 0;
        }
        n = n - 4;
    }
}

u64 mod_125(u64 a)
{
    while (a >= 125)
    {
        if (a < 125)
            break;
        a = a -125; 
    }
    return a;
}

u64 divide_125(u64 a)
{
    u64 count = 0;
    while (a >= 125)
    {
        if (a < 125)
            break;
        a = a -125; 
        count++;
    }
    return count;
}

u64 corr_trans(u64 a)
{ 
    // u64 corr_7 = a%125;
    // u64 corr_41 = (a/125)*128 ;
	// return corr_41+corr_7;

    u64 corr_7 = mod_125(a);
    u64 corr_41 = divide_125(a) << 7;
	return corr_41 + corr_7;
}
	

u64 ts_add(u64 u1,u64 u2){
    u64 u_sum;
    // u64 u1_41 = (u1/128)*128;
    u64 u1_41 = (u1 >> 7) << 7;
    // u64 u2_41 = (u2/128)*128;
    u64 u2_41 = (u2 >> 7) << 7;
    // u8 u1_7 = u1%128;
    u8 u1_7 = mod_128(u1);
    // u8 u2_7 = u2%128;
    u8 u2_7 = mod_128(u2);
    u1_41 = u1_41+u2_41;
    u1_7 = u1_7+u2_7;
    if(u1_7>124){
        u1_41 = u1_41+128;
        u1_7 = u1_7-125;
    }
    u_sum = u1_41+u1_7;
    return u_sum;
}

u64 ts_sub(u64 u1, u64 u2){               // 鏃堕棿鎴崇浉鍑忓嚱鏁�
    int flag;
    u64 u_sub = 0;
    // u64 u1_41 = (u1/128)*128;
    u64 u1_41 = u1 & 0xffffffffffffff80;
    // u64 u2_41 = (u2/128)*128;
    u64 u2_41 = (u2 >> 7) << 7;
    // u64 u1_7 = u1%128;
    u64 u1_7 = u1&0x7f;
    u64 u2_7 = u2&0x7f;
    if(u1>=u2){
        flag = 0;
    }else {
        flag = 1;
    }
    if(flag == 0){
      if(u1_7>u2_7){
        u_sub = (u1_7-u2_7)+(u1_41-u2_41);
      }else if (u1_7<u2_7){
          u1_7 = u1_7 + 125 -u2_7;
          u1_41 = u1_41 - 128 -u2_41;
          u_sub = ts_add(u1_7,u1_41);
      }else if(u1_41>u2_41){
          u_sub = u1_41-u2_41;
      }else {
          u_sub = 0;
      }
    }else{
        if(u2_7>u1_7){
            u_sub = (u2_7-u1_7)+(u2_41-u1_41) +0x1000000000000;
        }else if (u2_7<u1_7){
            u1_7 = u2_7+125-u1_7;
            u1_41 = u2_41 -128 -u1_41;
            u_sub = ts_add(u1_7,u1_41)+0x1000000000000;
        }else if(u2_41>u1_41){
          u_sub = u2_41-u1_41+0x1000000000000;
      }
    }
    return u_sub;
}

void ts_compute(void)
{
    u64 t4 = ts_sub(global_ts_info.t2,ts_add(global_ts_info.t1,global_ts_info.rorr1));
    if(t4<0x1000000000000&&global_ts_info.t3<0x1000000000000)
	{
        if(t4>=global_ts_info.t3)
		{
            // global_ts_info.offset = ts_sub(t4,global_ts_info.t3)/2;
            global_ts_info.offset = ts_sub(t4,global_ts_info.t3) >> 1;
            global_ts_info.offset_flag = 0;
        }
		else if(t4<global_ts_info.t3)
		{
            // global_ts_info.offset = ts_sub(global_ts_info.t3,t4)/2;
            global_ts_info.offset = ts_sub(global_ts_info.t3,t4) >> 1;
            global_ts_info.offset_flag = 1;
        }
    }
	else if(t4<0x1000000000000&&global_ts_info.t3>0x1000000000000)
	{
        global_ts_info.offset_flag = 0;
        // global_ts_info.offset = ts_add(t4,global_ts_info.t3-0x1000000000000)/2;
        global_ts_info.offset = ts_add(t4,global_ts_info.t3-0x1000000000000) >> 1;
    }
	else if(t4>0x1000000000000&&global_ts_info.t3<0x1000000000000)
	{
        global_ts_info.offset_flag = 1 ;
        // global_ts_info.offset = ts_add(t4-0x1000000000000,global_ts_info.t3)/2;
        global_ts_info.offset = ts_add(t4-0x1000000000000,global_ts_info.t3) >> 1;
    }
	else
	{
        if((t4-0x1000000000000)>=(global_ts_info.t3-0x1000000000000))
		{
            global_ts_info.offset_flag = 1;
            // global_ts_info.offset = ts_sub(t4,global_ts_info.t3)/2;
            global_ts_info.offset = ts_sub(t4,global_ts_info.t3) >> 1;
        }
		else
		{
            global_ts_info.offset_flag = 0;
            // global_ts_info.offset = ts_sub(global_ts_info.t3,t4)/2;
            global_ts_info.offset = ts_sub(global_ts_info.t3,t4) >> 1;
        }
    }
}


u32 htonl(u32 a){

    return ((a >> 24) & 0x000000ff) | ((a >>  8) & 0x0000ff00) | ((a <<  8) & 0x00ff0000) | ((a << 24) & 0xff000000);

}

u16 htons(u16 a){

  return ((a >> 8) & 0x00ff) | ((a << 8) & 0xff00);

}

u64 htonll(u64 a){
    return ((a>>56)&0x00000000000000ff) | ((a>>40)&0x000000000000ff00) | ((a>>24)&0x0000000000ff0000) | ((a>>8)&0x00000000ff000000) | ((a<<8)&0x000000ff00000000)| ((a<<24)&0x0000ff0000000000)| ((a<<40)&0x00ff000000000000)| ((a<<56)&0xff00000000000000);
}

void htonl_pkt(u32* ptr)
{
    // for(unsigned int i = 0; i < sizeof(ptp_pkt)/4; i++) // changed by LCL7.
    for(unsigned int i = 0; i < (sizeof(ptp_pkt) >> 2); i++)
    {
        *(ptr+i) = htonl(*(ptr+i));
    }
}

void htonl_md_ts(u32* ptr)
{
    ptr = ptr + 0;      // input ptr is the pointer of packet head
    *(ptr) = htonl(*(ptr));
    *(ptr+1) = htonl(*(ptr+1));
}

void htonl_pkt_ts(u32* ptr)
{
    ptr = ptr + 14;      // input ptr is the pointer of packet head
    *(ptr) = htonl(*(ptr));
    *(ptr+1) = htonl(*(ptr+1));
    *(ptr+2) = htonl(*(ptr+2));
}


void md_transf_fun(unsigned int* tmp_md,u16 outport,u8 lookup_en,u8 frag_last){
    unsigned int tmp = *tmp_md;
    tmp = tmp | ((u32)lookup_en << 14); /////******
    tmp = tmp | ((u32)frag_last << 13); /////******
    tmp = tmp | ((u32)outport << 15);   /////******
    *tmp_md = tmp;
}
/*
void md_transf_fun(u8 *tmp_md,u16 outport,u8 lookup_en,u8 frag_last){
	tmp_md[0] = 0;
	tmp_md[0] = outport>>1;

	tmp_md[1] = 0;
	tmp_md[1] = tmp_md[1] | (outport<<7);

	tmp_md[1] = tmp_md[1] | (lookup_en<<6);
	tmp_md[1] = tmp_md[1] | (frag_last<<5);

}*/
void dmac_transf_tag(u32 *tmp_dmac,u8 flow_type,u16 flowid,u16 seqid,u8 frag_flag,u8 frag_id,u8 inject_addr,u8 submit_addr )
{
    *(tmp_dmac) = 0;        //add by hxj. 
    *(tmp_dmac) = *(tmp_dmac) | ((u32)flow_type << 29);
    *(tmp_dmac) = *(tmp_dmac) | ((u32)flowid << 15);
    *(tmp_dmac) = *(tmp_dmac) | ((u32)seqid >> 1);
    tmp_dmac = tmp_dmac + 1;
    *(tmp_dmac) = 0;         //add by hxj.
    *(tmp_dmac) = *(tmp_dmac) | ((u32)seqid << 31);
    *(tmp_dmac) = *(tmp_dmac) | ((u32)frag_flag << 30);
    *(tmp_dmac) = *(tmp_dmac) | ((u32)frag_id << 26);
    *(tmp_dmac) = *(tmp_dmac) | ((u32)inject_addr << 21);
    *(tmp_dmac) = *(tmp_dmac) | ((u32)submit_addr<<16);
}

void smac_transf_tag(u32 *tmp_dmac,u8 flow_type,u16 flowid,u16 seqid,u8 frag_flag,u8 frag_id,u8 inject_addr,u8 submit_addr )
{
    // tmp_dmac = tmp_dmac + 1;//smac start addr
    tmp_dmac = tmp_dmac;   //smac start addr 
    *(tmp_dmac) = *(tmp_dmac) & 0xff00;    //add by hxj.
    *(tmp_dmac) = *(tmp_dmac) | ((u32)flow_type << 13);
    *(tmp_dmac) = *(tmp_dmac) | ((u32)flowid >> 1);
    tmp_dmac = tmp_dmac + 1;
    *(tmp_dmac) = 0;       //add by hxj.
    *(tmp_dmac) = *(tmp_dmac) | ((u32)flowid << 31);
    *(tmp_dmac) = *(tmp_dmac) | ((u32)seqid << 15);
    *(tmp_dmac) = *(tmp_dmac) | ((u32)frag_flag << 14);
    *(tmp_dmac) = *(tmp_dmac) | ((u32)frag_id << 10);
    *(tmp_dmac) = *(tmp_dmac) | ((u32)inject_addr << 5);
    *(tmp_dmac) = *(tmp_dmac) | ((u32)submit_addr);
}
/*
void dmac_transf_tag(u8 *tmp_dmac,u8 flow_type,u16 flowid,u16 seqid,u8 frag_flag,u8 frag_id,u8 inject_addr,u8 submit_addr ){
	tmp_dmac[0] = 0;
	tmp_dmac[0] = flow_type<<5;
	tmp_dmac[0] = tmp_dmac[0] | (flowid>>9);

	tmp_dmac[1] = 0;
	tmp_dmac[1] = flowid >> 1;

	tmp_dmac[2] = 0;
	tmp_dmac[2] = flowid << 7;
	tmp_dmac[2] = tmp_dmac[2] | (seqid >> 9);

	tmp_dmac[3] = 0;
	tmp_dmac[3] = seqid >> 1;
	tmp_dmac[3] = tmp_dmac[3] | (seqid >> 9);

	tmp_dmac[4] = 0;
	tmp_dmac[4] = seqid << 7;
	tmp_dmac[4] = tmp_dmac[4] | (frag_flag << 6);
	tmp_dmac[4] = tmp_dmac[4] | (frag_id << 2);
	tmp_dmac[4] = tmp_dmac[4] | (inject_addr >> 3);

	tmp_dmac[5] = 0;
	tmp_dmac[5] = inject_addr << 5;
	tmp_dmac[5] = tmp_dmac[5] | submit_addr;

}*/

void pkt_init(ptp_pkt* pkt)
{
    memset(pkt,0,sizeof(ptp_pkt));
    return ;
}

/*
char*  get_src_mac(ptp_pkt* pkt)
{
    char src_mac[6];
    char* ptr = NULL;
    int i;
    for(i=0;i<6;i++){
        src_mac[i]=pkt->src_mac[i];
    }
    ptr = src_mac;
   // src_mac =(ptp_TSNTag *)(&(pkt->src_mac));
    return ptr;
}*/

//***************
//u32 get_src_mac(ptp_pkt* pkt)
u64 get_src_mac(ptp_pkt* pkt)
{
    u32 *ptr = (u32*)pkt;
    // u64 result = (*(ptr + 3) & 0x0000ffff);
    u64 result = (u64)(*(ptr + 3) & 0x0000ffff);    //add by hxj.
    result = result << 32;

    result += (u64)(*(ptr + 4));    
    return result;
}

//u32 set_des_mac(ptp_pkt * pkt)
u64 set_des_mac(ptp_pkt* pkt, u64 mac)  
{
    u64 result; 
    u32* ptr = (u32*)pkt;
    *(ptr + 2) = (u32)(mac >> 16);
    result = (u64)(*(ptr + 2)) << 16;
    *(ptr + 3) = *(ptr + 3) & 0x0000ffff;
    *(ptr + 3) = *(ptr + 3) | (u32)(mac << 16);
    result = result | (u64)*((ptr + 3)) >> 16;
    return result;
    // u32* ptr = (u32*)pkt;
    // *(ptr + 2) = (u32)(mac >> 16);        
    // *(ptr + 3) = (u32)(mac << 16);
}

/*
long long get_corr(ptp_pkt* pkt)
{
    long long * ptr;
    ptr = (long long *)(pkt->corrField);
    return htonll(*ptr);
}
*/
u64 get_corr(ptp_pkt * pkt)
{
    u32 *tmp = (u32*)pkt + 7;
    u64 corr = 0;
    corr += (u64)(*tmp & 0x0000ffff) << 48;
    corr += (u64)(*(tmp+1)) << 16;
    corr += (u64)(*(tmp+2) >> 16);
    
    return corr;
}

/*
void set_corr(ptp_pkt* pkt,long long  corr)
{
    long long * ptr;
    ptr = (long long *)(pkt->corrField) ;
    *ptr = htonll(corr);

}*/
void set_corr(ptp_pkt * pkt, u64 corr)
{
   u32 *tmp = (u32*)pkt + 7;
   *(tmp + 2) = *(tmp + 2) & 0x0000ffff;

   *tmp = (*tmp & 0xffff0000) | (u32)(corr >> 48);
   *(tmp + 1) = (u32)((corr << 16) >> 32);
   *(tmp + 2) = (*(tmp + 2) & 0x0000ffff) | (u32)((corr << 48) >> 32);
}

/*
long long get_pkt_ts(ptp_pkt* pkt)
{
    long long * ptr;
    ptr = (long long *)(pkt->timestamp);
    return htonll(*ptr);
}
*/
u64 get_pkt_ts(ptp_pkt* pkt)
{
    u32* s_ptr = (u32*)pkt;
    u64 result = 0;
    result += (u64)(*(s_ptr + 14) & 0x0000ffff) << 48;
    result += (u64)(*(s_ptr + 15)) << 16 ;
    result += (u64)(*(s_ptr + 16) >> 16);
    
    return result; 
}

/*
void set_pkt_ts(ptp_pkt* pkt,long long  ts)
{
    long long * ptr;
    ptr = (long long *)(pkt->timestamp) ;
    *ptr = htonll(ts);
}
*/
void set_pkt_ts(ptp_pkt* pkt, u64 ts)
{
    u32 * s_ptr = (u32*)pkt;
    *(s_ptr + 14) = (*(s_ptr + 14) & 0xffff0000) + (u32)(ts >> 48);     // for sign bit. add by LCL7
    *(s_ptr + 15) = (u32)(ts >> 16);
    *(s_ptr + 16) = (u32)((ts << 48) >> 32);
}
/*
long long get_md_ts(ptp_pkt* pkt)
{
    long long * ptr;
    ptr = (long long *)(pkt);
    return htonll(*ptr)>>16;//锟斤拷锟斤拷时锟斤拷锟轿拷锟�??48位锟斤拷锟斤拷锟斤拷锟揭猯ong long锟斤拷锟斤拷锟斤拷锟斤拷16位
}
*/
u64 get_md_ts(ptp_pkt* pkt)
{
    u32* ptr = (u32*)pkt;
    u64 result = 0;
    result += (u64)(*ptr) << 16;
    result += (u64)(*(ptr + 1) >> 16);
    
    return result; 
}

/*
void set_md_ts(ptp_pkt* pkt,long long ts )
{
    long long * ptr;
    char * ptr1 = (char*)pkt;
    ptr = (long long *)(ptr1+4);    //original code change by hxj
    *ptr = htonll(ts<<16);
}
*/

void set_md_ts(ptp_pkt* pkt, u64 ts)
{
    u32 *ptr = (u32*)pkt;
    *ptr = (u32)(ts >> 16);
    ptr = ptr + 1;
    *ptr = (u32)((ts & 0x000000000000ffff) << 16) + (*ptr & 0x0000ffff);
}

int delay_req_pkt_build(ptp_pkt* sync_pkt){

    //u16* ptr =NULL;   
    global_ts_info.t1 = get_pkt_ts(sync_pkt);
    global_ts_info.t2 = get_md_ts(sync_pkt);
    global_ts_info.rorr1 = corr_trans(get_corr(sync_pkt));
    // printf("t1 is 0x%llx, t2 is 0x%llx, corr is 0x%llx \n", global_ts_info.t1, global_ts_info.t2, global_ts_info.rorr1);
    
    memset(sync_pkt,0,8);
    //sync_pkt->pkttype= 0x4;
    u32* ptr = (u32*)sync_pkt;
    *ptr = (unsigned int)(0x4 << 29);
    //md_transf_fun(sync_pkt->md,0x0000,0x01,0x00);
    md_transf_fun(ptr,0x0000,0x01,0x00);
    set_des_mac(sync_pkt,get_src_mac(sync_pkt));
    //(delete by fsh)dmac_transf_tag(sync_pkt->src_mac,0x4,12345,0x0000,0x00,0x00,0x00,0x00);
    // smac_transf_tag((ptr + 2),0x4,ptp_slave_imac,0x0000,0x00,0x00,0x00,0x00);
    smac_transf_tag((ptr + 3),0x4,ptp_slave_imac,0x0000,0x00,0x00,0x00,0x00);   //change by hxj.
    //sync_pkt->ptp_type=0x3;
    *(ptr + 5) = 0x98F7 << 16;
    *(ptr + 5) = *(ptr + 5) & 0xfffff0ff;
    *(ptr + 5) = *(ptr + 5) + (unsigned int)(0x3 << 8);

    //memset(sync_pkt->timestamp,0,8);
    //u32* ptr = (u32*)sync_pkt;
    //ptr += 14;
    *(ptr + 14) = *(ptr + 14) & 0xffff0000;
    *(ptr + 15) = *(ptr + 15) & 0x00000000;
    *(ptr + 16) = *(ptr + 16) & 0x0000ffff;
    //memset(sync_pkt->corrField,0,8);
    u32* ptr1 = (u32*)sync_pkt;
    ptr1 += 7;
    *ptr1 = *ptr1 & 0xffff0000;
    *(ptr1 + 1) = *(ptr1 + 1) & 0x00000000;
    *(ptr1 + 2) = *(ptr1 + 2) & 0x0000ffff;
    //pkt->eth_type=htons(0x98F7);
    
    return sizeof(ptp_pkt);
}

int delay_resp_pkt_build(ptp_pkt* req_pkt)
{   
    u64 sub = ts_sub(get_md_ts(req_pkt),ts_add(get_pkt_ts(req_pkt),corr_trans(get_corr(req_pkt))));
    // printf("t3 is 0x%llx, t4 is 0x%llx, corr is 0x%llx, sub is 0x%llx \n", get_pkt_ts(req_pkt), get_md_ts(req_pkt), corr_trans(get_corr(req_pkt)), sub);
    
	memset(req_pkt,0,8);
    //req_pkt->pkttype= 0x4;
    u32* ptr = (u32*)req_pkt;
    *ptr = (unsigned int)(0x4 << 29);
    md_transf_fun(ptr,0x0000,0x01,0x00);
    set_des_mac(req_pkt, get_src_mac(req_pkt));
    // smac_transf_tag((unsigned int*)req_pkt->des_mac,0x4,ptp_master_imac,0x0000,0x00,0x00,0x00,0x00);  
    smac_transf_tag((ptr + 3),0x4,ptp_master_imac,0x0000,0x00,0x00,0x00,0x00);     //change by hxj.
    //req_pkt->ptp_type=0x4;
    *(ptr + 5) = 0x98F7 << 16;
    *(ptr + 5) = *(ptr + 5) & 0xfffff0ff;
    *(ptr + 5) = *(ptr + 5) + (unsigned int)(0x4 << 8);

    //memset(req_pkt->timestamp, 0, 8);
    *(ptr + 14) = *(ptr + 14) & 0xffff0000;//pkt_init(pkt); 
    *(ptr + 15) = *(ptr + 15) & 0x00000000;
    *(ptr + 16) = *(ptr + 16) & 0x0000ffff;
    
    //memset(req_pkt->corrField, 0, 8);
    *(ptr + 7) = *(ptr + 7) & 0xffff0000;
    *(ptr + 8) = *(ptr + 8) & 0x00000000;
    *(ptr + 9) = *(ptr + 9) & 0x0000ffff;
    
    set_pkt_ts(req_pkt, sub);
    return sizeof(ptp_pkt);
}

void delay_resp_pkt_handler(ptp_pkt* pkt)
{   
    global_ts_info.t3 = get_pkt_ts(pkt);//t3锟窖撅拷为t4-t3-透锟斤拷时锟接碉拷值
    //u64 t4 = ts_sub(tsinfo.t2,ts_add(tsinfo.t1,tsinfo.rorr1));
    ts_compute();
}

u32 get_l_offset(u64 offset)
{
    return (u32)offset;
}

u32 get_h_offset(u64 offset, u8 offset_flag)
{
    
    if(offset_flag == 0 )
    {
        offset = offset + 0x1000000000000;    // sign bit. add by LCL7
    }
    return (u32)(offset>>32);
}

/*
struct nmac_pkt *build_offset_pkt(u32 l_offset,u32 h_offset)
{
	struct nmac_pkt *nmac = (nmac_pkt*)malloc(sizeof(nmac_pkt));
    u32* ptr_pointer = nmac;

	//nmac->pkttype   	= 5;
    *ptr_pointer = (unsigned int)(0x5 << 29);
	//nmac->inject_addr   = 0;
    *ptr_pointer = *ptr_pointer & 0xe0000000;

	//md_transf_fun((unsigned int*)nmac,0,0,0);//锟斤拷mD锟斤拷锟叫革拷值
    md_transf_fun(ptr_pointer,0x0000,0x00,0x00);
	
	//dmac_transf_tag((unsigned int*)nmac->dst_mac,5,0,0,0,0,0,0);//锟斤拷锟斤拷锟斤拷锟斤拷011       flowID=0000  
    dmac_transf_tag((ptr_pointer + 2),5,0,0,0,0,0,0);


	//nmac->src_mac[0] = 0;
    *(ptr_pointer + 3) = *(ptr_pointer + 3) & 0xffff0000;
	//nmac->src_mac[1] = 1;
    *(ptr_pointer + 3) = *(ptr_pointer + 3) | 0x00000001;
	//nmac->src_mac[2] = 1;
	//nmac->src_mac[3] = 3;
	//nmac->src_mac[4] = 4;
	//nmac->src_mac[5] = 6;
    *(ptr_pointer + 4) = 0x01030406;

    //(unsigned int*)nmac->ether_type = 0x0000;
    *(ptr_pointer + 5) = 0x00000000;
	*(ptr_pointer + 5) = NtoHs(0x1662) << 16;
	//nmac->count = 2;
    *(ptr_pointer + 5) = *(ptr_pointer + 5) | 0x02 << 8;
	//nmac->type  = 3;
    *(ptr_pointer + 5) = *(ptr_pointer + 5) | 0x03;
	//(unsigned int*)nmac->addr = NtoHl(0);
    *(ptr_pointer + 6) = (u32)(NtoHl(0));

	//nmac->data[0] = l_offset;    //锟窖撅拷锟斤拷锟斤拷锟斤拷小锟斤拷转锟斤拷
    *(ptr_pointer + 7) = l_offset << 24; 
	//nmac->data[1] = h_offset;    //锟窖撅拷锟斤拷锟斤拷锟斤拷小锟斤拷转锟斤拷
    *(ptr_pointer + 7) = *(ptr_pointer + 7) | h_offset << 16; 

	//return nmac;
    return nmac;

}*/


int sync_pkt_build(ptp_pkt* sync_pkt)                    //?sync?????
{
    memset(sync_pkt,0,sizeof(ptp_pkt));
    u32* ptr = (u32*)sync_pkt;
    //pkt->pkttype= 0x4;
    *ptr = (unsigned int)(0x4 << 29);
                                      
    //md_transf_fun(pkt->md,0x0000,0x01,0x00);            //??metadata??
    md_transf_fun(ptr,0x0000,0x01,0x00);
    // printf("pkttype and md %02x\n", *ptr);
    //dmac_transf_tag(pkt->des_mac,0x4,0x123,0x0000,0x00,0x00,0x00,0x00);      // DMAC
    dmac_transf_tag((ptr + 2),0x4,ptp_multicast_imac,0x0000,0x00,0x00,0x00,0x00);
    //dmac_transf_tag(pkt->src_mac,0x4,0x123,0x0000,0x00,0x00,0x00,0x00);     // SMAC
    smac_transf_tag((ptr + 3),0x4,ptp_master_imac,0x0000,0x00,0x00,0x00,0x00);
    //pkt->eth_type=htons(0x98F7);                         //?????????
    *(ptr + 5) = 0x98F7 << 16; 
    //pkt->ptp_type=0x1;                                   //ptp??????
    *(ptr + 5) = *(ptr + 5) & 0xfffff0ff;
    *(ptr + 5) = *(ptr + 5) + (0x1 << 8); 
    //pkt->pkt_length = htons(72);                         //????????
    *(ptr + 6) = 72 << 16;
    
    return sizeof(ptp_pkt);
}

