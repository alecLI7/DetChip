#include "static_sched.h"

struct sched_set tsn_sched_set = {0};
struct global_resource g_resource = {0};
struct flow_set tsn_flow_set = {0};
int max_slot_cycle = 0;
int min_slot_cycle = 0;
int loop_num = 0;
//u16 period_slot_set[5] = {20, 40, 60, 80, 100};
// u16 period_slot_set[2] = {40, 80};
u16 period_slot_set[4] = {40, 60, 80, 100};
//u16 period_slot_set[6] = {20, 30, 40, 60, 80, 100};
struct map_info snow_map[PORT_NUM * (PORT_NUM - 1)] = {0};

int back_num = 0;

// Add by LCL7 -> for new constrain
int     ENDSYSTEM_CONSTRAIN_INSERT_CHECK_FLAG = 0;
double  NEW_CONSTRAIN_TASK_RATIO = 1;
struct  flow_task_set tsn_flow_task_set = {0};
int     NEW_CONSTRAIN_INSERT_CHECK_CALL_COUNT = 0;
int     NEW_CONSTRAIN_INSERT_CHECK_FLOW_PAIR_COUNT = 0;
#define NEW_CONSTRAIN_DEBUG 0

int gcd_two(int x,int y)
{
    int a = 1;

    if(x < y)
    {
        a = x;
        x = y;
        y = a;
    }

    while(x % y != 0)
    {
        a = x % y;
        x = y;
        y = a;
    }
    return y;
}

int lcm(struct sched_set tsn_sched_set)  
{
    int result = tsn_sched_set.sched[0].period_slot, i = 0;

    for(i = 1; i < tsn_sched_set.cur_flow_num; i++)
    {
        result = (tsn_sched_set.sched[i].period_slot * result) / gcd_two(tsn_sched_set.sched[i].period_slot, result);
    }
    return result;
}

int gcd(struct flow_set tsn_flow_set)
{
    int result = tsn_flow_set.flow[0].period, i = 0;

    for(i = 1; i < tsn_flow_set.cur_flow_num; i++)
    {
        result = gcd_two(tsn_flow_set.flow[i].period, result);
    }
    return result;
}


/*初始化资源*/
int init_global_resource()
{
    int i = 0, j = 0, k = 0;
    
    memset(&g_resource, 0, sizeof(struct global_resource));
    g_resource.cur_sched_slot_num = lcm(tsn_sched_set);
//    printf("cur_sched_slot_num: %d!\n", g_resource.cur_sched_slot_num);
    for(i = 0; i < NODE_NUM; i++)
    {
        for(j = 0; j < PORT_NUM; j++)
        {
            for(k = 0; k < MAX_SCHED_SLOT; k++)
            {
                g_resource.cqf[i][j][k].total_len = CQF_QUEUE_LEN;
                g_resource.cqf[i][j][k].free_len = CQF_QUEUE_LEN;
            }
        }
    }
}

/*更新资源*/
int update_global_resource_increment()
{
    int s = 0, i = 0, j = 0, k = 0;
    int temp_cur_sched_slot_num = 0;
    u8 node = 0;
    u8 port = 0;
    u8 src_node = 0;
    int slot = 0;
    int flag = 0;

    back_num = 0;
    temp_cur_sched_slot_num = g_resource.cur_sched_slot_num * 2;
    memset(&g_resource, 0, sizeof(struct global_resource));
    g_resource.cur_sched_slot_num = temp_cur_sched_slot_num;
    for(i = 0; i < NODE_NUM; i++)
    {
        for(j = 0; j < PORT_NUM; j++)
        {
            for(k = 0; k < MAX_SCHED_SLOT; k++)
            {
                g_resource.cqf[i][j][k].total_len = CQF_QUEUE_LEN;
                g_resource.cqf[i][j][k].free_len = CQF_QUEUE_LEN;
            }
        }
    }

    for(s = 0; s < tsn_sched_set.cur_flow_num; s++)
    {
        if(tsn_sched_set.sched[s].flag == FAIL)
            continue;
        src_node = tsn_sched_set.sched[s].src_sw_id;
        flag = 1;
        for(i = 0; i < tsn_sched_set.sched[s].path_len; i++)
        {
            node = tsn_sched_set.sched[s].path_info[i].sw_id;
            port = tsn_sched_set.sched[s].path_info[i].port_id;
            for(j = 0; j < (g_resource.cur_sched_slot_num / tsn_sched_set.sched[s].period_slot); j++)
            {
                slot = (tsn_sched_set.sched[s].offset + j * tsn_sched_set.sched[s].period_slot + i + 1) % g_resource.cur_sched_slot_num;
                g_resource.cqf[node][port][slot].free_len -= tsn_sched_set.sched[s].pkt_num;
                g_resource.cqf[node][port][slot].used_len += tsn_sched_set.sched[s].pkt_num;
                if(g_resource.cqf[node][port][slot].used_len > CQF_QUEUE_LEN)
                {
                    flag = 0;
                    back_num++;
                   //printf("exceed: used_len: %d, free_len: %d!\n", g_resource.cqf[node][slot].used_len, g_resource.cqf[node][slot].free_len);
                }
            }
        }

        if(flag == 0)
        {
            for(i = 0; i < tsn_sched_set.sched[s].path_len; i++)
            {
                node = tsn_sched_set.sched[s].path_info[i].sw_id;
                port = tsn_sched_set.sched[s].path_info[i].port_id;
                for(j = 0; j < (g_resource.cur_sched_slot_num / tsn_sched_set.sched[s].period_slot); j++)
                {
                    slot = (tsn_sched_set.sched[s].offset + j * tsn_sched_set.sched[s].period_slot + i + 1) % g_resource.cur_sched_slot_num;
                    g_resource.cqf[node][port][slot].free_len += tsn_sched_set.sched[s].pkt_num;
                    g_resource.cqf[node][port][slot].used_len -= tsn_sched_set.sched[s].pkt_num;
                }
            }

            tsn_sched_set.sched[s].flag = FAIL;
            tsn_sched_set.cur_suc_num--;
        }
    }


//    printf("before_sched_slot_num: %d, cur_sched_slot_num: %d!\n", \
           temp_sched_slot, g_resource.cur_sched_slot_num);
/*    for(i = 0; i < NODE_NUM; i++)
    {
        for(j = temp_sched_slot - 1; j >= 0; j--)
        {
            if(g_resource.cqf[i][j].used_len > 0)
            {
                g_resource.cqf[i][j * 2].used_len = g_resource.cqf[i][j].used_len;
                g_resource.cqf[i][j * 2].free_len = g_resource.cqf[i][j].free_len;
                g_resource.cqf[i][j].free_len = CQF_QUEUE_LEN;
                g_resource.cqf[i][j].used_len = 0;
            }
        }
    }
*/    
}

int update_global_resource_restart()
{
    int i = 0, j = 0, k = 0;
    int temp_cur_sched_slot_num = 0;

    /*--- Changed by LCL7 -> for restart without changing slot when testing new constrain ---*/
    // temp_cur_sched_slot_num = g_resource.cur_sched_slot_num * 2;
    temp_cur_sched_slot_num = g_resource.cur_sched_slot_num;
    memset(&g_resource, 0, sizeof(struct global_resource));
    g_resource.cur_sched_slot_num = temp_cur_sched_slot_num;
    for(i = 0; i < NODE_NUM; i++)
    {
        for(j = 0; j < PORT_NUM; j++)
        {
            for(k = 0; k < MAX_SCHED_SLOT; k++)
            {
                g_resource.cqf[i][j][k].total_len = CQF_QUEUE_LEN;
                g_resource.cqf[i][j][k].free_len = CQF_QUEUE_LEN;
            }
        }
    }
}


int init_all_flow_feature(u32 flow_num)
{
    int i = 0, j = 0;
	int pre_slot_cycle = 0;

    memset(&tsn_flow_set, 0, sizeof(struct flow_set));
    tsn_flow_set.cur_flow_num = flow_num;

    // Add by LCL7 -> new constrain from end-system
    memset(&tsn_flow_task_set, 0, sizeof(struct flow_task_set));
    tsn_flow_task_set.cur_flow_num = flow_num;
    
    for(i = 0; i < flow_num; i++)
    {
        tsn_flow_set.flow[i].flow_id = i;
        tsn_flow_set.flow[i].src_host_id = random(HOST_NUM_PER_NODE);
        tsn_flow_set.flow[i].dst_host_id = random(HOST_NUM_PER_NODE);
        tsn_flow_set.flow[i].src_sw_id = random(PORT_NUM * (PORT_NUM - 1)) + (PORT_NUM + 1);
REPEAT:
        tsn_flow_set.flow[i].dst_sw_id = random(PORT_NUM * (PORT_NUM - 1)) + (PORT_NUM + 1);
        if(tsn_flow_set.flow[i].src_sw_id == tsn_flow_set.flow[i].dst_sw_id)
            goto REPEAT;
        j = random(sizeof(period_slot_set) / sizeof(period_slot_set[0]));           // Change by LCL7
        tsn_flow_set.flow[i].period = period_slot_set[j] * DEFAULT_SLOT_CYCLE;
//        tsn_flow_set.flow[i].pkt_num = 1; // pkt_num [64, 1500]
        tsn_flow_set.flow[i].pkt_num = (random(2) + 1); // pkt_num [64, 1500]
        tsn_flow_set.flow[i].deadline = (random(16) + 64) * 125; 

        // Add by LCL7 -> new constrain from end-system
        tsn_flow_task_set.flow_task[i].flow_id = i;
        tsn_flow_task_set.flow_task[i].tx_wcet = (((double)rand()) / RAND_MAX) * NEW_CONSTRAIN_TASK_RATIO * 125; 
        tsn_flow_task_set.flow_task[i].rx_wcet = (((double)rand()) / RAND_MAX) * NEW_CONSTRAIN_TASK_RATIO * 125; 
    
    }
    
    max_slot_cycle = gcd(tsn_flow_set);
	min_slot_cycle = max_slot_cycle;
	while(min_slot_cycle >= MIN_SLOT_CYCLE)
	{
		pre_slot_cycle = min_slot_cycle;
		min_slot_cycle = min_slot_cycle / 2;
	}
	min_slot_cycle = pre_slot_cycle;
    printf("min_slot_cycle: %d\n", min_slot_cycle);
}

int compute_all_flow_sched_info(int slot_cycle)
{
    int i = 0 , j = 0;
    int id = 0;
    struct map_info src_map = {0};
    struct map_info dst_map = {0};

    for(i = 0; i < PORT_NUM; i++)
    {
        for(j = 0; j < PORT_NUM - 1; j++)
        {
            id = i * (PORT_NUM - 1) + j;
            snow_map[id].leaf_sw = PORT_NUM + 1 + id;
            snow_map[id].parent_sw = i + 1;
            snow_map[id].conn_port = j + 1;
        }
    }

    memset(&tsn_sched_set, 0, sizeof(struct sched_set));
    tsn_sched_set.cur_flow_num = tsn_flow_set.cur_flow_num;
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        tsn_sched_set.sched[i].flow_id = tsn_flow_set.flow[i].flow_id;
        tsn_sched_set.sched[i].src_sw_id = tsn_flow_set.flow[i].src_sw_id;
        tsn_sched_set.sched[i].dst_sw_id = tsn_flow_set.flow[i].dst_sw_id;
        src_map = snow_map[tsn_sched_set.sched[i].src_sw_id - PORT_NUM - 1];
        dst_map = snow_map[tsn_sched_set.sched[i].dst_sw_id - PORT_NUM - 1];
        if(src_map.parent_sw == dst_map.parent_sw)
        {
            tsn_sched_set.sched[i].path_len = 3;
            tsn_sched_set.sched[i].path_info[0].sw_id = tsn_sched_set.sched[i].src_sw_id;
            tsn_sched_set.sched[i].path_info[0].port_id = 0; 
            tsn_sched_set.sched[i].path_info[1].sw_id = dst_map.parent_sw;
            tsn_sched_set.sched[i].path_info[1].port_id = dst_map.conn_port; 
            tsn_sched_set.sched[i].path_info[2].sw_id = tsn_sched_set.sched[i].dst_sw_id;
            tsn_sched_set.sched[i].path_info[2].port_id = tsn_flow_set.flow[i].dst_host_id + 1; 
        }
        else
        {
            tsn_sched_set.sched[i].path_len = 5;
            tsn_sched_set.sched[i].path_info[0].sw_id = tsn_sched_set.sched[i].src_sw_id;
            tsn_sched_set.sched[i].path_info[0].port_id = 0; 
            tsn_sched_set.sched[i].path_info[1].sw_id = src_map.parent_sw;
            tsn_sched_set.sched[i].path_info[1].port_id = 0; 
            tsn_sched_set.sched[i].path_info[2].sw_id = 0;
            tsn_sched_set.sched[i].path_info[2].port_id = dst_map.parent_sw - 1; 
            tsn_sched_set.sched[i].path_info[3].sw_id = dst_map.parent_sw;
            tsn_sched_set.sched[i].path_info[3].port_id = dst_map.conn_port; 
            tsn_sched_set.sched[i].path_info[4].sw_id = tsn_sched_set.sched[i].dst_sw_id;
            tsn_sched_set.sched[i].path_info[4].port_id = tsn_flow_set.flow[i].dst_host_id + 1; 
        }

        tsn_sched_set.sched[i].period = tsn_flow_set.flow[i].period;
        tsn_sched_set.sched[i].period_slot = tsn_flow_set.flow[i].period / slot_cycle;
        tsn_sched_set.sched[i].pkt_num = tsn_flow_set.flow[i].pkt_num;
        tsn_sched_set.sched[i].deadline = tsn_flow_set.flow[i].deadline;
        tsn_sched_set.sched[i].deadline_slot = tsn_sched_set.sched[i].deadline / slot_cycle;
        tsn_sched_set.sched[i].flag = FAIL;
//        tsn_sched_set.sched[i].deadline_slot = random(tsn_sched_set.sched[i].period_slot) + tsn_sched_set.sched[i].path_len + 1;
        //printf("flow id: %d, src_sw_id: %d, dst_sw_id: %d, path_len: %d, period: %d, pkt_num: %d, deadline: %d!\n",\
        tsn_sched_set.sched[i].flow_id, tsn_sched_set.sched[i].src_sw_id, tsn_sched_set.sched[i].dst_sw_id,\
        tsn_sched_set.sched[i].path_len, tsn_sched_set.sched[i].period_slot, tsn_sched_set.sched[i].pkt_num,\
        tsn_sched_set.sched[i].deadline_slot);
        
        // Add by LCL7 --> compute task slot for new constrain
        tsn_flow_task_set.cur_slot_cycle = slot_cycle;
        tsn_flow_task_set.flow_task[i].rx_wcet_slot = tsn_flow_task_set.flow_task[i].rx_wcet / slot_cycle;
        tsn_flow_task_set.flow_task[i].tx_wcet_slot = tsn_flow_task_set.flow_task[i].tx_wcet / slot_cycle;
    }
}

int update_all_flow_sched_info_increment()
{
    int i = 0;
    
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        tsn_sched_set.sched[i].period_slot = tsn_sched_set.sched[i].period_slot * 2;
        tsn_sched_set.sched[i].deadline_slot = tsn_sched_set.sched[i].deadline_slot * 2;
//        tsn_sched_set.sched[i].offset = tsn_sched_set.sched[i].offset * 2;
//        tsn_sched_set.sched[i].deadline_slot = random(tsn_sched_set.sched[i].period_slot) + tsn_sched_set.sched[i].path_len + 1;
        //printf("flow id: %d, src_sw_id: %d, dst_sw_id: %d, path_len: %d, period: %d, pkt_num: %d, deadline: %d!\n",\
        tsn_sched_set.sched[i].flow_id, tsn_sched_set.sched[i].src_sw_id, tsn_sched_set.sched[i].dst_sw_id,\
        tsn_sched_set.sched[i].path_len, tsn_sched_set.sched[i].period_slot, tsn_sched_set.sched[i].pkt_num,\
        tsn_sched_set.sched[i].deadline_slot);
    }
}

int update_all_flow_sched_info_restart()
{
    int i = 0;
    
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        tsn_sched_set.sched[i].flag = FAIL;
        /*--- Changed by LCL7 -> for restart without changing slot when testing new constrain ---*/
        // tsn_sched_set.sched[i].period_slot = tsn_sched_set.sched[i].period_slot * 2;
        // tsn_sched_set.sched[i].deadline_slot = tsn_sched_set.sched[i].deadline_slot * 2;
        tsn_sched_set.sched[i].offset = 0;
//        tsn_sched_set.sched[i].offset = tsn_sched_set.sched[i].offset * 2;
//        tsn_sched_set.sched[i].deadline_slot = random(tsn_sched_set.sched[i].period_slot) + tsn_sched_set.sched[i].path_len + 1;
        //printf("flow id: %d, src_sw_id: %d, dst_sw_id: %d, path_len: %d, period: %d, pkt_num: %d, deadline: %d!\n",\
        tsn_sched_set.sched[i].flow_id, tsn_sched_set.sched[i].src_sw_id, tsn_sched_set.sched[i].dst_sw_id,\
        tsn_sched_set.sched[i].path_len, tsn_sched_set.sched[i].period_slot, tsn_sched_set.sched[i].pkt_num,\
        tsn_sched_set.sched[i].deadline_slot);
    }
    tsn_sched_set.cur_suc_num = 0;
}


float compute_resource_ratio()
{
    float ratio = 0;
    int i = 0, j = 0, k = 0;
    int port_sum = 0;

    for(i = 0; i < NODE_NUM; i++)
    {
        for(j = 0; j < PORT_NUM; j++)
        {
			if(i > PORT_NUM && j > 0)
				continue;
            for(k = 0; k < g_resource.cur_sched_slot_num; k++)
            {
                if(g_resource.cqf[i][j][k].used_len > 0)
                {
                    if(g_resource.cqf[i][j][k].used_len > CQF_QUEUE_LEN)
                        printf("node: %d, port: %d, slot: %d, used_len: %d, free_len: %d\n", \
                               i, j, k, g_resource.cqf[i][j][k].used_len, g_resource.cqf[i][j][k].free_len);
                    ratio += g_resource.cqf[i][j][k].used_len;
                }
            }
        }
    }
    port_sum = (PORT_NUM) * (1 + PORT_NUM) + (PORT_NUM - 1) * PORT_NUM;
    return ratio / (CQF_QUEUE_LEN * g_resource.cur_sched_slot_num * port_sum);
}


/*增量调度*/
int static_schedule_increment(user_defined_flow_sched sched_func1, \
                    user_defined_flow_sched sched_func2, user_defined_flow_sort sort_func, u32 flow_num)
{
    int cur_slot_cycle = 0;
    int count = 0;
	int i = 0, j = 0;
    time_t start, finish;
	int suc_num[TEST_NUM][10] = {0};
    int min_suc_num = 0xFFFFFF;
    int max_suc_num = 0;
    int ave_suc_num = 0;
    int sloop_num[TEST_NUM][10] = {0};
    int min_loop_num = 0xFFFFFF;
    int max_loop_num = 0;
    int ave_loop_num = 0;
    double duration[TEST_NUM][10] = {0};
    double min_duration = 0xFFFFFF;
    double max_duration = 0;
    double ave_duration = 0;
    float resource_ratio[TEST_NUM][10] = {0};
    float min_resource_ratio = 0xFFFFFF;
    float max_resource_ratio = 0;
    float ave_resource_ratio = 0;


	for(i = 0; i < TEST_NUM; i++)
	{
        init_all_flow_feature(flow_num);
        count = 0;
        start = clock();
        cur_slot_cycle = max_slot_cycle;
        compute_all_flow_sched_info(cur_slot_cycle);
        init_global_resource();
        if(sort_func != NULL)
        {
            sort_func();
        }
        
        back_num = 0;
        while(cur_slot_cycle >= MIN_SLOT_CYCLE)
        {
            sched_func1();
            if(sched_func2 != NULL)
                sched_func2();
            finish = clock();
            duration[i][count] = ((double)(finish - start) / CLOCKS_PER_SEC);
            sloop_num[i][count] = loop_num;
            suc_num[i][count] = tsn_sched_set.cur_suc_num;
            resource_ratio[i][count] = compute_resource_ratio();

            printf("TEST_NUM: %d, Increment [%d]th: slot_cycle: %d, sched_cycle: %d, suc_num: %d, back_num: %d\n", \
                   i, count, cur_slot_cycle, g_resource.cur_sched_slot_num, tsn_sched_set.cur_suc_num, back_num);

            printf("TEST_NUM: %d, Increment [%d]th: flow_num: %d, loop_num: %d, time_consumed: %lf, resource_ratio: %f\n", \
                   i, count, tsn_sched_set.cur_flow_num, loop_num, duration[i][count], resource_ratio[i][count]);

            if(tsn_sched_set.cur_suc_num < tsn_sched_set.cur_flow_num)
            {
                cur_slot_cycle = cur_slot_cycle / 2;
                update_all_flow_sched_info_increment();  
                update_global_resource_increment();  
                count++;
            }
            else
                break;
        }

	}

    cur_slot_cycle = max_slot_cycle;
    for(i = 0; i < count; i++)
    {
        min_suc_num = 0xFFFFFF;
        max_suc_num = 0;
        ave_suc_num = 0;
        min_loop_num = 0xFFFFFF;
        max_loop_num = 0;
        ave_loop_num = 0;
        min_duration = 0xFFFFFF;
        max_duration = 0;
        ave_duration = 0;
        min_resource_ratio = 0xFFFFFF;
        max_resource_ratio = 0;
        ave_resource_ratio = 0;

        for(j = 0; j < TEST_NUM; j++)
        {
            if(min_suc_num > suc_num[j][i])
                min_suc_num = suc_num[j][i];
            if(max_suc_num < suc_num[j][i])
                max_suc_num = suc_num[j][i];
            ave_suc_num += suc_num[j][i];
        }
        ave_suc_num = ave_suc_num / TEST_NUM;
        
        for(j = 0; j < TEST_NUM; j++)
        {
            if(min_loop_num > sloop_num[j][i])
                min_loop_num = sloop_num[j][i];
            if(max_loop_num < sloop_num[j][i])
                max_loop_num = sloop_num[j][i];
            ave_loop_num += sloop_num[j][i];
        }
        ave_loop_num = ave_loop_num / TEST_NUM;
        
        for(j = 0; j < TEST_NUM; j++)
        {
            if(min_duration > duration[j][i])
                min_duration = duration[j][i];
            if(max_duration < duration[j][i])
                max_duration = duration[j][i];
            ave_duration += duration[j][i];
        }
        ave_duration = ave_duration / TEST_NUM;
        
        for(j = 0; j < TEST_NUM; j++)
        {
            if(min_resource_ratio > resource_ratio[j][i])
                min_resource_ratio = resource_ratio[j][i];
            if(max_resource_ratio < resource_ratio[j][i])
                max_resource_ratio = resource_ratio[j][i];
            ave_resource_ratio += resource_ratio[j][i];
        }
        ave_resource_ratio = ave_resource_ratio / TEST_NUM;
        printf("SUM Increment [%d]th: flow_num: %d, cur_slot_cycle: %d, min_suc_num: %d, max_suc_num: %d, ave_suc_num: %d\n", \
               i, flow_num, cur_slot_cycle, min_suc_num, max_suc_num, ave_suc_num);
        printf("SUM Increment [%d]th: min_loop_num: %d, max_loop_num: %d, ave_loop_num: %d\n", i, min_loop_num, max_loop_num, ave_loop_num);
        printf("SUM Increment [%d]th: min_duration: %lf, max_duration: %lf, ave_duration: %lf\n", i, min_duration, max_duration, ave_duration);
        printf("SUM Increment [%d]th: min_resource_ratio: %f, max_resource_ratio: %f, ave_resource_ratio: %f\n", i, \
               min_resource_ratio, max_resource_ratio, ave_resource_ratio);
               
        cur_slot_cycle = cur_slot_cycle / 2;           
    }


}

int static_schedule_restart(user_defined_flow_sched sched_func1, \
                    user_defined_flow_sched sched_func2, user_defined_flow_sort sort_func, u32 flow_num)
{
    int cur_slot_cycle = 0;
    int count = 0;
    int i = 0, j = 0;
    time_t start, finish;
    int suc_num[TEST_NUM] = {0};
    int min_suc_num = 0xFFFFFF;
    int max_suc_num = 0;
    int ave_suc_num = 0;
    int sloop_num[TEST_NUM] = {0};
    int min_loop_num = 0xFFFFFF;
    int max_loop_num = 0;
    int ave_loop_num = 0;
    double duration[TEST_NUM] = {0};
    double min_duration = 0xFFFFFF;
    double max_duration = 0;
    double ave_duration = 0;
    float resource_ratio[TEST_NUM] = {0};
    float min_resource_ratio = 0xFFFFFF;
    float max_resource_ratio = 0;
    float ave_resource_ratio = 0;

    // Add by LCL7 -> for new constrain
    int fail_flow_num[TEST_NUM] = {0};
    int ave_fail_flow_num = 0;
    int new_constrain_call_num[TEST_NUM] = {0};
    int ave_new_constrain_call_num = 0;
    int fail_flow_num_ec[TEST_NUM] = {0};
    int ave_fail_flow_num_ec = 0;
    int suc_num_ec[TEST_NUM] = {0};
    int min_suc_num_ec = 0xFFFFFF;
    int max_suc_num_ec = 0;
    int ave_suc_num_ec = 0;
    int sloop_num_ec[TEST_NUM] = {0};
    int min_loop_num_ec = 0xFFFFFF;
    int max_loop_num_ec = 0;
    int ave_loop_num_ec = 0;
    double duration_ec[TEST_NUM] = {0};
    double min_duration_ec = 0xFFFFFF;
    double max_duration_ec = 0;
    double ave_duration_ec = 0;
    float resource_ratio_ec[TEST_NUM] = {0};
    float min_resource_ratio_ec = 0xFFFFFF;
    float max_resource_ratio_ec = 0;
    float ave_resource_ratio_ec = 0;
    int new_constrain_call_num_ec[TEST_NUM] = {0};
    int ave_new_constrain_call_num_ec = 0;
    int new_constrain_check_flow_pair_num_ec[TEST_NUM] = {0};
    int ave_new_constrain_check_flow_pair_num_ec = 0;

    for(i = 0; i < TEST_NUM; i++)
    {
        // disable flag for original ITP. add by LCL7
        ENDSYSTEM_CONSTRAIN_INSERT_CHECK_FLAG = 0;

        init_all_flow_feature(flow_num);                // Updated by LCL7
        count = 0;
        start = clock();
        cur_slot_cycle = min_slot_cycle;
        compute_all_flow_sched_info(cur_slot_cycle);    // Updated by LCL7
        init_global_resource();
        if(sort_func != NULL)
        {
            sort_func();
        }
       
		sched_func1();
        
	    if(sched_func2 != NULL)
			sched_func2();

		finish = clock();
		duration[i] = ((double)(finish - start) / CLOCKS_PER_SEC);
		sloop_num[i] = loop_num;
		suc_num[i] = tsn_sched_set.cur_suc_num;
		resource_ratio[i] = compute_resource_ratio();
        new_constrain_call_num[i] = NEW_CONSTRAIN_INSERT_CHECK_CALL_COUNT;      // Add by LCL7.

        // Add by LCL7 -> for new constrain
        if (ENDSYSTEM_CONSTRAIN_FLAG)
        {
            fail_flow_num[i] = new_constrain_result_check(cur_slot_cycle);
        }
	
		printf("<-- Original ITP -->\n");
        printf("TEST_NUM: %d, Restart [%d]th: slot_cycle: %d, sched_cycle: %d, suc_num: %d, ave_fail_flow_num: %d\n", \
		   i, count, cur_slot_cycle, g_resource.cur_sched_slot_num, tsn_sched_set.cur_suc_num, fail_flow_num[i]);     // Changed by LCL7

		printf("TEST_NUM: %d, Restart [%d]th: flow_num: %d, loop_num: %d, time_consumed: %lf, resource_ratio: %f\n", \
                   i, count, tsn_sched_set.cur_flow_num, loop_num, duration[i], resource_ratio[i]);

        
        /*--- Add by LCL7 --> for new constrain test ----------------------------------------------*/
        // First, update and enable flag for ITP-EC. add by LCL7
        update_global_resource_restart();
        update_all_flow_sched_info_restart();
        ENDSYSTEM_CONSTRAIN_INSERT_CHECK_FLAG = 1;

        count = 0;
        start = clock();
        cur_slot_cycle = min_slot_cycle;
        compute_all_flow_sched_info(cur_slot_cycle);    // Updated by LCL7
        init_global_resource();
        if(sort_func != NULL)
        {
            sort_func();
        }
       
		sched_func1();
        
	    if(sched_func2 != NULL)
			sched_func2();

		finish = clock();
		duration_ec[i] = ((double)(finish - start) / CLOCKS_PER_SEC);
		sloop_num_ec[i] = loop_num;
		suc_num_ec[i] = tsn_sched_set.cur_suc_num;
		resource_ratio_ec[i] = compute_resource_ratio();
        new_constrain_call_num_ec[i] = NEW_CONSTRAIN_INSERT_CHECK_CALL_COUNT;
        new_constrain_check_flow_pair_num_ec[i] = NEW_CONSTRAIN_INSERT_CHECK_FLOW_PAIR_COUNT;

        // Add by LCL7 -> for new constrain
        if (ENDSYSTEM_CONSTRAIN_FLAG)
        {
            fail_flow_num_ec[i] = new_constrain_result_check(cur_slot_cycle);
        }
	
		printf("<-- EC ITP -->\n");
        printf("TEST_NUM: %d, Restart [%d]th: slot_cycle: %d, sched_cycle: %d, suc_num: %d, ave_fail_flow_num: %d\n", \
		   i, count, cur_slot_cycle, g_resource.cur_sched_slot_num, tsn_sched_set.cur_suc_num, fail_flow_num_ec[i]);     // Changed by LCL7

		printf("TEST_NUM: %d, Restart [%d]th: flow_num: %d, loop_num: %d, time_consumed: %lf, resource_ratio: %f\n", \
                   i, count, tsn_sched_set.cur_flow_num, loop_num, duration_ec[i], resource_ratio_ec[i]);

    }

    for(j = 0; j < TEST_NUM; j++)
    {
    	if(min_suc_num > suc_num[j])
        	min_suc_num = suc_num[j];
       	if(max_suc_num < suc_num[j])
        	max_suc_num = suc_num[j];
       	ave_suc_num += suc_num[j];
        // Add by LCL7 -> for new constrain
        ave_fail_flow_num += fail_flow_num[j];
   	}
    ave_suc_num = ave_suc_num / TEST_NUM;
     // Add by LCL7 -> for new constrain
    ave_fail_flow_num = ave_fail_flow_num / TEST_NUM;
        
	for(j = 0; j < TEST_NUM; j++)
	{
		if(min_loop_num > sloop_num[j])
			min_loop_num = sloop_num[j];
		if(max_loop_num < sloop_num[j])
			max_loop_num = sloop_num[j];
		ave_loop_num += sloop_num[j];
	}
	ave_loop_num = ave_loop_num / TEST_NUM;

	for(j = 0; j < TEST_NUM; j++)
	{
		if(min_duration > duration[j])
			min_duration = duration[j];
		if(max_duration < duration[j])
			max_duration = duration[j];
		ave_duration += duration[j];
	}
	ave_duration = ave_duration / TEST_NUM;

	for(j = 0; j < TEST_NUM; j++)
	{
		if(min_resource_ratio > resource_ratio[j])
			min_resource_ratio = resource_ratio[j];
		if(max_resource_ratio < resource_ratio[j])
			max_resource_ratio = resource_ratio[j];
		ave_resource_ratio += resource_ratio[j];
	}
	ave_resource_ratio = ave_resource_ratio / TEST_NUM;
    
    for(j = 0; j < TEST_NUM; j++)
	{
        ave_new_constrain_call_num += new_constrain_call_num[j];
    }
    ave_new_constrain_call_num = ave_new_constrain_call_num / TEST_NUM;
    
    printf("#=== Original ITP ===#\n");
    printf("SUM Restart: flow_num: %d, cur_slot_cycle: %d\n", flow_num, cur_slot_cycle);
	printf("SUM Restart: min_suc_num: %d, max_suc_num: %d, ave_suc_num: %d\n", min_suc_num, max_suc_num, ave_suc_num);
    printf("SUM Restart: ave_fail_flow_num: %d, ave_fail_flow_ratio: %f, ave_real_suc_flow_ratio: %f\n", ave_fail_flow_num, ave_fail_flow_num / (double)ave_suc_num, 1 - ave_fail_flow_num / (double)ave_suc_num);      // Added by LCL7
	printf("SUM Restart: ave_new_constrain_call_num: %d\n", ave_new_constrain_call_num);
    printf("SUM Restart: min_loop_num: %d, max_loop_num: %d, ave_loop_num: %d\n", min_loop_num, max_loop_num, ave_loop_num);
	printf("SUM Restart: min_duration: %lf, max_duration: %lf, ave_duration: %lf\n", min_duration, max_duration, ave_duration);
	printf("SUM Restart: min_resource_ratio: %f, max_resource_ratio: %f, ave_resource_ratio: %f\n", min_resource_ratio, max_resource_ratio, ave_resource_ratio);


    /*--- Add by LCL7 --> for new constrain test ----------------------------------------------*/
    for(j = 0; j < TEST_NUM; j++)
    {
    	if(min_suc_num_ec > suc_num_ec[j])
        	min_suc_num_ec = suc_num_ec[j];
       	if(max_suc_num_ec < suc_num_ec[j])
        	max_suc_num_ec = suc_num_ec[j];
       	ave_suc_num_ec += suc_num_ec[j];
        // Add by LCL7 -> for new constrain
        ave_fail_flow_num_ec += fail_flow_num_ec[j];
   	}
    ave_suc_num_ec = ave_suc_num_ec / TEST_NUM;
    // Add by LCL7 -> for new constrain
    ave_fail_flow_num_ec = ave_fail_flow_num_ec / TEST_NUM;
        
	for(j = 0; j < TEST_NUM; j++)
	{
		if(min_loop_num_ec > sloop_num_ec[j])
			min_loop_num_ec = sloop_num_ec[j];
		if(max_loop_num_ec < sloop_num_ec[j])
			max_loop_num_ec = sloop_num_ec[j];
		ave_loop_num_ec += sloop_num_ec[j];
	}
	ave_loop_num_ec = ave_loop_num_ec / TEST_NUM;

	for(j = 0; j < TEST_NUM; j++)
	{
		if(min_duration_ec > duration_ec[j])
			min_duration_ec = duration_ec[j];
		if(max_duration_ec < duration_ec[j])
			max_duration_ec = duration_ec[j];
		ave_duration_ec += duration_ec[j];
	}
	ave_duration_ec = ave_duration_ec / TEST_NUM;

	for(j = 0; j < TEST_NUM; j++)
	{
		if(min_resource_ratio_ec > resource_ratio_ec[j])
			min_resource_ratio_ec = resource_ratio_ec[j];
		if(max_resource_ratio_ec < resource_ratio_ec[j])
			max_resource_ratio_ec = resource_ratio_ec[j];
		ave_resource_ratio_ec += resource_ratio_ec[j];
	}
	ave_resource_ratio_ec = ave_resource_ratio_ec / TEST_NUM;

    for(j = 0; j < TEST_NUM; j++)
    {
        ave_new_constrain_call_num_ec += new_constrain_call_num_ec[j];
        ave_new_constrain_check_flow_pair_num_ec += new_constrain_check_flow_pair_num_ec[j];
    }
    ave_new_constrain_call_num_ec = ave_new_constrain_call_num_ec / TEST_NUM;
    ave_new_constrain_check_flow_pair_num_ec = ave_new_constrain_check_flow_pair_num_ec / TEST_NUM;

    printf("\n#=== End-system Constrain ITP ===#\n");
	printf("SUM Restart: flow_num: %d, cur_slot_cycle: %d\n", flow_num, cur_slot_cycle);
	printf("SUM Restart: min_suc_num: %d, max_suc_num: %d, ave_suc_num: %d\n", min_suc_num_ec, max_suc_num_ec, ave_suc_num_ec);
    printf("SUM Restart: ave_fail_flow_num: %d, ave_fail_flow_ratio: %f, ave_real_suc_flow_ratio: %f\n", ave_fail_flow_num_ec, ave_fail_flow_num_ec / (double)ave_suc_num_ec, 1 - ave_fail_flow_num_ec / (double)ave_suc_num_ec);      // Added by LCL7
	printf("SUM Restart: ave_new_constrain_call_num_ec: %d, ave_new_constrain_check_flow_pair_num_ec: %d\n", ave_new_constrain_call_num_ec, ave_new_constrain_check_flow_pair_num_ec);
    printf("SUM Restart: min_loop_num: %d, max_loop_num: %d, ave_loop_num: %d\n", min_loop_num_ec, max_loop_num_ec, ave_loop_num_ec);
	printf("SUM Restart: min_duration: %lf, max_duration: %lf, ave_duration: %lf\n", min_duration_ec, max_duration_ec, ave_duration_ec);
	printf("SUM Restart: min_resource_ratio: %f, max_resource_ratio: %f, ave_resource_ratio: %f\n", min_resource_ratio_ec, max_resource_ratio_ec, ave_resource_ratio_ec);
}

/***********************************************
 * Add by LCL7 -> for new constrain            *
 * Planning Result Check Version               *
 ***********************************************
 */
int new_constrain_result_check(int cur_slot_cycle)
{
    int i, j;
    int a, b;
    int cur_case_flag;
    int case_value, cur_lcm_value;
    int cur_rx_wcet_i, cur_rx_wcet_j;
    int cur_tx_wcet_i, cur_tx_wcet_j;
    struct sched_set cur_sched_set;
    struct sched_info cur_sched_i, cur_sched_j;
    int remove_flow_num;
    
    int case1_num, case2_num, case3_4_num;
    int case1_fail_num, case2_fail_num, case3_4_fail_num;

    int lcl7_count = 0;

    memset(&cur_sched_set, 0, sizeof(struct sched_set));
    memset(&cur_sched_i, 0, sizeof(struct sched_info));
    memset(&cur_sched_j, 0, sizeof(struct sched_info));
    cur_sched_set.cur_flow_num = 2;

    if (NEW_CONSTRAIN_DEBUG)
    {
        printf("--> %s: begin ...\n", __func__);
    }
    case1_num = 0;
    case2_num = 0;
    case3_4_num = 0;
    case1_fail_num = 0;
    case2_fail_num = 0;
    case3_4_fail_num = 0;
    remove_flow_num = 0;

    for(i = 0; i < (int)(tsn_sched_set.cur_flow_num)-1; i++)
    {
        // cur_sched_i = tsn_sched_set.sched[i];
        memcpy(&cur_sched_i, &(tsn_sched_set.sched[i]), sizeof(struct sched_info));

        if (cur_sched_i.flag == FAIL)
        {
            // printf("--> FAIL flag\n");
            continue;
        }

        lcl7_count += 1;

        // cur_sched_set.sched[0] = cur_sched_i;
        memcpy(&(cur_sched_set.sched[0]), &cur_sched_i, sizeof(struct sched_info));
        cur_rx_wcet_i = tsn_flow_task_set.flow_task[cur_sched_i.flow_id].rx_wcet;
        cur_tx_wcet_i = tsn_flow_task_set.flow_task[cur_sched_i.flow_id].tx_wcet;

        for(j = i+1; j < (int)(tsn_sched_set.cur_flow_num); j++) 
        {
            // cur_sched_j = tsn_sched_set.sched[j];
            memcpy(&cur_sched_j, &(tsn_sched_set.sched[j]), sizeof(struct sched_info));

            if (cur_sched_j.flag == FAIL)
            {
                // printf("--> FAIL flag\n");
                continue;
            }            
            
            // cur_sched_set.sched[1] = cur_sched_j;
            memcpy(&(cur_sched_set.sched[1]), &cur_sched_j, sizeof(struct sched_info));
            cur_lcm_value = lcm(cur_sched_set);
            cur_rx_wcet_j = tsn_flow_task_set.flow_task[cur_sched_j.flow_id].rx_wcet;
            cur_tx_wcet_j = tsn_flow_task_set.flow_task[cur_sched_j.flow_id].tx_wcet;

            case_value = (cur_sched_i.dst_sw_id == cur_sched_j.dst_sw_id) ? 1 : \
                            (cur_sched_i.src_sw_id == cur_sched_j.src_sw_id) ? 2 : \
                            (cur_sched_i.dst_sw_id == cur_sched_j.src_sw_id) ? 3 : \
                            (cur_sched_i.src_sw_id == cur_sched_j.dst_sw_id) ? 4: 0;

            cur_case_flag = SUCCESS;
            
            switch (case_value)
            {
                case 1:     // both rx tasks
                    case1_num += 1;
                    for(a = 0; a < cur_lcm_value; a++)
                    {
                        for(b = 0; b < cur_lcm_value; b++)
                        {
                            if ((a*cur_sched_i.period_slot + cur_sched_i.offset + cur_sched_i.path_len) == (b*cur_sched_j.period_slot + cur_sched_j.offset + cur_sched_j.path_len))
                            {// both rx task in the same slot
                                if (cur_rx_wcet_i + cur_rx_wcet_j + 2*DetChipISR > cur_slot_cycle)
                                {
                                    case1_fail_num += 1;
                                    cur_case_flag = FAIL;
                                }
                                
                            }
                            else if (((a*cur_sched_i.period_slot + cur_sched_i.offset + cur_sched_i.path_len + (u16)ceil((cur_rx_wcet_i + (u16)(DetChipISR)) / (double)cur_slot_cycle) <= b*cur_sched_j.period_slot + cur_sched_j.offset + cur_sched_j.path_len) \
                                || (b*cur_sched_j.period_slot + cur_sched_j.offset + cur_sched_j.path_len + (u16)ceil((cur_rx_wcet_j + (u16)(DetChipISR)) / (double)cur_slot_cycle) <= a*cur_sched_i.period_slot + cur_sched_i.offset + cur_sched_i.path_len)) \
                                    == FALSE)
                            {   
                                case1_fail_num += 1;
                                cur_case_flag = FAIL;
                            }
                            
                            if (cur_case_flag == FAIL)
                            {
                                break;
                            }
                        }
                        
                        if (cur_case_flag == FAIL)
                        {
                            if (NEW_CONSTRAIN_DEBUG)
                            {
                                printf("--> %s: case 1 ...\n", __func__);
                                printf("i: %d, j: %d, a: %d, b: %d\n", i, j, a, b);
                                printf("f_i -> flow_id: %d, flag: %d, src_sw_id: %d, dst_sw_id: %d, period_slot: %d, offset: %d, path_len: %d, rx_wcet_slot: %d, tx_wcet_slot: %d, rx_wcet: %d, tx_wcet: %d \n", cur_sched_i.flow_id, cur_sched_i.flag, cur_sched_i.src_sw_id, cur_sched_i.dst_sw_id, cur_sched_i.period_slot, cur_sched_i.offset, cur_sched_i.path_len, (u16)ceil(cur_rx_wcet_i / (double)cur_slot_cycle), (u16)ceil(cur_tx_wcet_i / (double)cur_slot_cycle), cur_rx_wcet_i, cur_tx_wcet_i);
                                printf("f_j -> flow_id: %d, flag: %d, src_sw_id: %d, dst_sw_id: %d, period_slot: %d, offset: %d, path_len: %d, rx_wcet_slot: %d, tx_wcet_slot: %d, rx_wcet: %d, tx_wcet: %d \n", cur_sched_j.flow_id, cur_sched_j.flag, cur_sched_j.src_sw_id, cur_sched_j.dst_sw_id, cur_sched_j.period_slot, cur_sched_j.offset, cur_sched_j.path_len, (u16)ceil(cur_rx_wcet_j / (double)cur_slot_cycle), (u16)ceil(cur_tx_wcet_j / (double)cur_slot_cycle), cur_rx_wcet_j, cur_tx_wcet_j);
                            }
                            break;
                        }
                        
                    }
                    break;
                
                case 2:     // both tx tasks
                    case2_num += 1;
                    for(a = 0; a < cur_lcm_value; a++)
                    {
                        for(b = 0; b < cur_lcm_value; b++)
                        {
                            if ((a*cur_sched_i.period_slot + cur_sched_i.offset) == (b*cur_sched_j.period_slot + cur_sched_j.offset))
                            {
                                if (cur_tx_wcet_i + cur_tx_wcet_j + 2*DetChipISR > cur_slot_cycle)
                                {
                                    case2_fail_num += 1;
                                    cur_case_flag = FAIL;
                                }                      
                            }
                            else if (((a*cur_sched_i.period_slot + cur_sched_i.offset + (u16)ceil((cur_tx_wcet_j + (u16)(DetChipISR)) / (double)cur_slot_cycle) <= b*cur_sched_j.period_slot + cur_sched_j.offset) \
                                || (b*cur_sched_j.period_slot + cur_sched_j.offset + (u16)ceil((cur_tx_wcet_i + (u16)(DetChipISR)) / (double)cur_slot_cycle) <= a*cur_sched_i.period_slot + cur_sched_i.offset)) \
                                    == FALSE)
                            {
                                case2_fail_num += 1;
                                cur_case_flag = FAIL;
                            }

                            if (cur_case_flag == FAIL)
                            {
                                break;
                            }
                        }
                        if (cur_case_flag == FAIL)
                        {
                            if (NEW_CONSTRAIN_DEBUG)
                            {
                                printf("--> %s: case 2 ...\n", __func__);
                                printf("i: %d, j: %d, a: %d, b: %d\n", i, j, a, b);
                                printf("f_i -> flow_id: %d, flag: %d, src_sw_id: %d, dst_sw_id: %d, period_slot: %d, offset: %d, path_len: %d, rx_wcet_slot: %d, tx_wcet_slot: %d, rx_wcet: %d, tx_wcet: %d \n", cur_sched_i.flow_id, cur_sched_i.flag, cur_sched_i.src_sw_id, cur_sched_i.dst_sw_id, cur_sched_i.period_slot, cur_sched_i.offset, cur_sched_i.path_len, (u16)ceil(cur_rx_wcet_i / (double)cur_slot_cycle), (u16)ceil(cur_tx_wcet_i / (double)cur_slot_cycle), cur_rx_wcet_i, cur_tx_wcet_i);
                                printf("f_j -> flow_id: %d, flag: %d, src_sw_id: %d, dst_sw_id: %d, period_slot: %d, offset: %d, path_len: %d, rx_wcet_slot: %d, tx_wcet_slot: %d, rx_wcet: %d, tx_wcet: %d \n", cur_sched_j.flow_id, cur_sched_j.flag, cur_sched_j.src_sw_id, cur_sched_j.dst_sw_id, cur_sched_j.period_slot, cur_sched_j.offset, cur_sched_j.path_len, (u16)ceil(cur_rx_wcet_j / (double)cur_slot_cycle), (u16)ceil(cur_tx_wcet_j / (double)cur_slot_cycle), cur_rx_wcet_j, cur_tx_wcet_j);
                            }
                            break;
                        }
                    }
                    break;
                
                case 3:     // rx task before tx task
                case 4:     // tx task before rx task
                    case3_4_num += 1;
                    for(a = 0; a < cur_lcm_value; a++)
                    {
                        for(b = 0; b < cur_lcm_value; b++)
                        {
                            if ((a*cur_sched_i.period_slot + cur_sched_i.offset + cur_sched_i.path_len) == (b*cur_sched_j.period_slot + cur_sched_j.offset) \
                                || (a*cur_sched_i.period_slot + cur_sched_i.offset) == (b*cur_sched_j.period_slot + cur_sched_j.offset + cur_sched_j.path_len))
                            {
                                if (((cur_sched_i.dst_sw_id == cur_sched_j.src_sw_id) && (cur_rx_wcet_i + cur_tx_wcet_j + 2*DetChipISR > cur_slot_cycle)) \
                                    || ((cur_sched_i.src_sw_id == cur_sched_j.dst_sw_id) && (cur_tx_wcet_i + cur_rx_wcet_j + 2*DetChipISR > cur_slot_cycle)))
                                {
                                    case3_4_fail_num += 1;
                                    cur_case_flag = FAIL;
                                }
                                
                            }
                            else{
                                if (cur_sched_i.dst_sw_id == cur_sched_j.src_sw_id)
                                {// case 3
                                    if (((a*cur_sched_i.period_slot + cur_sched_i.offset + cur_sched_i.path_len + (u16)ceil((cur_rx_wcet_i + cur_tx_wcet_j + (u16)(DetChipISR)) / (double)cur_slot_cycle) <= b*cur_sched_j.period_slot + cur_sched_j.offset) \
                                        || (b*cur_sched_j.period_slot + cur_sched_j.offset + (u16)ceil((u16)(DetChipISR) / (double)cur_slot_cycle) <= a*cur_sched_i.period_slot + cur_sched_i.offset + cur_sched_i.path_len)) \
                                        == FALSE)
                                    {
                                        case3_4_fail_num += 1;
                                        cur_case_flag = FAIL;
                                    }
                                }
                                
                                if (cur_sched_i.src_sw_id == cur_sched_j.dst_sw_id)
                                {// case 4 (sometimes both case 3 and case 4)
                                    if (((b*cur_sched_j.period_slot + cur_sched_j.offset + cur_sched_j.path_len + (u16)ceil((cur_rx_wcet_j + cur_tx_wcet_i + (u16)(DetChipISR)) / (double)cur_slot_cycle) <= a*cur_sched_i.period_slot + cur_sched_i.offset) \
                                        || (a*cur_sched_i.period_slot + cur_sched_i.offset + (u16)ceil((u16)(DetChipISR) / (double)cur_slot_cycle) <= b*cur_sched_j.period_slot + cur_sched_j.offset + cur_sched_j.path_len)) \
                                        == FALSE)
                                    {
                                        if (cur_case_flag != FAIL)
                                        {
                                            case3_4_fail_num += 1;
                                        }
                                        cur_case_flag = FAIL;
                                    }
                                }
                            }

                            if (cur_case_flag == FAIL)
                            {
                                break;
                            }
                        }
                        if (cur_case_flag == FAIL)
                        {
                            if (NEW_CONSTRAIN_DEBUG)
                            {
                                printf("--> %s: case 3/4 ...\n", __func__);
                                printf("i: %d, j: %d, a: %d, b: %d\n", i, j, a, b);
                                printf("f_i -> flow_id: %d, flag: %d, src_sw_id: %d, dst_sw_id: %d, period_slot: %d, offset: %d, path_len: %d, rx_wcet_slot: %d, tx_wcet_slot: %d, rx_wcet: %d, tx_wcet: %d \n", cur_sched_i.flow_id, cur_sched_i.flag, cur_sched_i.src_sw_id, cur_sched_i.dst_sw_id, cur_sched_i.period_slot, cur_sched_i.offset, cur_sched_i.path_len, (u16)ceil(cur_rx_wcet_i / (double)cur_slot_cycle), (u16)ceil(cur_tx_wcet_i / (double)cur_slot_cycle), cur_rx_wcet_i, cur_tx_wcet_i);
                                printf("f_j -> flow_id: %d, flag: %d, src_sw_id: %d, dst_sw_id: %d, period_slot: %d, offset: %d, path_len: %d, rx_wcet_slot: %d, tx_wcet_slot: %d, rx_wcet: %d, tx_wcet: %d \n", cur_sched_j.flow_id, cur_sched_j.flag, cur_sched_j.src_sw_id, cur_sched_j.dst_sw_id, cur_sched_j.period_slot, cur_sched_j.offset, cur_sched_j.path_len, (u16)ceil(cur_rx_wcet_j / (double)cur_slot_cycle), (u16)ceil(cur_tx_wcet_j / (double)cur_slot_cycle), cur_rx_wcet_j, cur_tx_wcet_j);
                            }
                            break;
                        }
                    }
                    break;

                default:
                    break;
            }

            if (cur_case_flag == FAIL)
            {
                remove_flow_num += 1;
                break;
            }
        }
    }
    if (NEW_CONSTRAIN_DEBUG)
    {
        printf("--> %s: remove_flow_num: %d, lcl7_count: %d \n", __func__, remove_flow_num, lcl7_count);
        printf("--> %s: case1: %d, case2: %d, case3/4: %d\n", __func__, case1_num, case2_num, case3_4_num);
        printf("--> %s: case1_fail_num: %d, case2_fail_num: %d, case3_4_fail_num: %d\n", __func__, case1_fail_num, case2_fail_num, case3_4_fail_num);
        printf("--> %s: end...\n", __func__);
    }
    return remove_flow_num;
}
