#include "enum_sched.h"

extern struct sched_set tsn_sched_set;
extern struct global_resource g_resource;

struct sched_set best_sched_set = {0};
struct global_resource best_g_resource = {0};


void recurse_search(int seq, struct sched_set re_sched_set, struct global_resource re_g_resource)
{
    int i = 0, j = 0;
    struct sched_info *sched = NULL;
    u8 src_node = 0;
    u16 node = 0;
    u16 port = 0;
    u16 slot = 0;
    int offset = 0;
    u16 latency = 0;
 
    struct sched_set temp_sched_set = {0};
    struct global_resource temp_g_resource = {0};
    temp_sched_set = re_sched_set;
    temp_g_resource = re_g_resource;

    for(offset = 0; offset < temp_sched_set.sched[seq].period_slot; offset++)
    {
        printf("seq: %d, offset: %d\n", seq, offset);
        re_sched_set = temp_sched_set;
        re_g_resource = temp_g_resource;
        sched = &re_sched_set.sched[seq];
        src_node = sched->src_sw_id;

        latency = offset + sched->path_len + 1;
        if(latency <= sched->deadline_slot)
        {
            sched->flag = SUCCESS;
            for(i = 0; i < sched->path_len; i++)
            {
                node = sched->path_info[i].sw_id;
                port = sched->path_info[i].port_id;
                for(j = 0; j < (re_g_resource.cur_sched_slot_num / sched->period_slot); j++)
                {
                    slot = (offset + j * sched->period_slot + i + 1) % re_g_resource.cur_sched_slot_num;
                    if(re_g_resource.cqf[node][port][slot].free_len < sched->pkt_num)
                    {
                        sched->flag = FAIL;
                        break;
                    }
                }
                if(sched->flag == FAIL)
                    break;
            }
            if(sched->flag == SUCCESS)
            {
                sched->offset = offset;
                for(i = 0; i < sched->path_len; i++)
                {
                    node = sched->path_info[i].sw_id;
                    port = sched->path_info[i].port_id;
                    for(j = 0; j < (re_g_resource.cur_sched_slot_num / sched->period_slot); j++)
                    {
                        slot = (offset + j * sched->period_slot + i + 1) % re_g_resource.cur_sched_slot_num;
                        re_g_resource.cqf[node][port][slot].free_len -= sched->pkt_num;
                        re_g_resource.cqf[node][port][slot].used_len += sched->pkt_num;
                    }
                }
 
                re_sched_set.cur_suc_num++;
            }
        }
        else
        {
//            printf("flow_id: %d, offset: %d, latency: %d, deadline: %d!\n", sched.flow_id, offset, latency, sched.deadline_slot);
            sched->flag = FAIL;
        }
        
        if(seq > 0)
        {
            recurse_search(seq - 1, re_sched_set, re_g_resource);
        }
        else
        {
            if(best_sched_set.cur_suc_num < re_sched_set.cur_suc_num)
            {
                best_sched_set = re_sched_set;
                best_g_resource = re_g_resource;
            }
        }
    }
}

int enum_sched()
{
    recurse_search(tsn_sched_set.cur_flow_num - 1, tsn_sched_set, g_resource);
    tsn_sched_set = best_sched_set;
    g_resource = best_g_resource;
}

