#ifndef __TSN_SCHED__
#define __TSN_SCHED__

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>

#define random(x) (rand()%x)

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long long u64;

#define DEFAULT_SLOT_CYCLE 100
/*队列长度*/
#define CQF_QUEUE_LEN 10
/*最小的时间槽长度*/
#define MIN_SLOT_CYCLE CQF_QUEUE_LEN * 12
/*最大周期长度*/
#define MAX_SCHED_SLOT 2000
/*最大流数目*/
// #define MAX_FLOW_NUM 2000
#define MAX_FLOW_NUM 2100       // Changed by LCL7 -> for potential unknown error
/*端口数目*/
#define PORT_NUM 4
/*每个叶节点连接的主机数目:最大值为PORT_NUM - 1*/
#define HOST_NUM_PER_NODE 1
/*最大跳数*/
#define MAX_HOP_NUM 20

/*节点数目*/
#define NODE_NUM ((PORT_NUM + 1) + (PORT_NUM - 1) * PORT_NUM)
/*测试次数*/
#define TEST_NUM 5


#define TRUE 1
#define FALSE 0

// Add by LCL7 -> Flag for new constrain
#define ENDSYSTEM_CONSTRAIN_FLAG 1
#define DetChipISR 0

typedef enum
{
    FAIL = 0,
    SUCCESS = 1
}SCHED_FLAG;

// Add by LCL7 -> task feature for new constrain
struct flow_task_feature
{
    u16 flow_id;
    u16 tx_wcet;
    u16 rx_wcet;

    u16 tx_wcet_slot;
    u16 rx_wcet_slot;
};

struct flow_task_set
{
    u32 cur_flow_num;
    int cur_slot_cycle;
    struct flow_task_feature flow_task[MAX_FLOW_NUM];
};


struct flow_feature
{
    u16 flow_id;
    u8 pad;
    u8 src_host_id;
    u8 dst_host_id;
    u8 src_sw_id;
    u8 dst_sw_id;
    u16 period;
    u16 pkt_num;
    u16 deadline;
};

struct flow_set
{
    u32 cur_flow_num;
    struct flow_feature flow[MAX_FLOW_NUM];
};

struct link_info
{
    u8 sw_id;
    u8 port_id;
};

struct map_info
{
    u8 leaf_sw;
    u8 parent_sw;
    u8 conn_port;
};

struct sched_info
{
    u16 flow_id;
    u16 path_len;
    struct link_info path_info[MAX_HOP_NUM];
    u8 src_sw_id;
    u8 dst_sw_id;
    u16 period;
    u16 period_slot;
    u16 pkt_num;
    u16 deadline;
    u16 deadline_slot;
    u16 offset;
    u32 density;
    u16 flag;
};

struct sched_set
{
    u32 cur_flow_num;
    u32 cur_suc_num;
    struct sched_info sched[MAX_FLOW_NUM];
};

struct cqf_resource
{
    int total_len;
    int used_len;
    int free_len;
};

struct global_resource
{
    u32 cur_sched_slot_num;
    struct cqf_resource cqf[NODE_NUM][PORT_NUM][MAX_SCHED_SLOT];
};

#endif
