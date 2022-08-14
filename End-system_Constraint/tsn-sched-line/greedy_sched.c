#include "greedy_sched.h"

extern struct sched_set tsn_sched_set;
extern struct global_resource g_resource;

static int user_defined_multi_stage_sort(struct sched_info sched1, struct sched_info sched2)
{
    if(sched1.pkt_num > sched2.pkt_num)
        return 1;
    else if(sched1.pkt_num < sched2.pkt_num)
        return 0;
    else
    {
        if(sched1.path_len > sched2.path_len)
            return 1;
        else if(sched1.path_len < sched2.path_len)
            return 0;
        else
        {
            if(sched1.deadline_slot > sched2.deadline_slot)
                return 1;
            else if(sched1.deadline_slot < sched2.deadline_slot)
                return 0;
            else
            {
                if(sched1.period_slot < sched2.period_slot)
                    return 1;
                else
                    return 0;
            }
        }
    }
}

int sort_flow_by_multi_stage_rule() //ascending
{
    int i = 0, j = 0;
    struct sched_info temp = {0};
    for(i = 0; i < tsn_sched_set.cur_flow_num - 1; i++)
    {
        for(j = 0; j < tsn_sched_set.cur_flow_num - i - 1; j++)
        {
            if(user_defined_multi_stage_sort(tsn_sched_set.sched[j], tsn_sched_set.sched[j + 1]))
            {
                temp = tsn_sched_set.sched[j];
                tsn_sched_set.sched[j] = tsn_sched_set.sched[j + 1];
                tsn_sched_set.sched[j + 1] = temp;
            }
        }
    }
}


int sort_flow_by_path_len() //ascending
{
    int i = 0, j = 0;
    struct sched_info temp = {0};
    for(i = 0; i < tsn_sched_set.cur_flow_num - 1; i++)
    {
        for(j = 0; j < tsn_sched_set.cur_flow_num - i - 1; j++)
        {
            if(tsn_sched_set.sched[j].path_len > tsn_sched_set.sched[j + 1].path_len)
            {
                temp = tsn_sched_set.sched[j];
                tsn_sched_set.sched[j] = tsn_sched_set.sched[j + 1];
                tsn_sched_set.sched[j + 1] = temp;
            }
        }
    }
}

int sort_flow_by_period() //descending
{
    int i = 0, j = 0;
    struct sched_info temp = {0};
    for(i = 0; i < tsn_sched_set.cur_flow_num - 1; i++)
    {
        for(j = 0; j < tsn_sched_set.cur_flow_num - i - 1; j++)
        {
            if(tsn_sched_set.sched[j].period_slot < tsn_sched_set.sched[j + 1].period_slot)
            {
                temp = tsn_sched_set.sched[j];
                tsn_sched_set.sched[j] = tsn_sched_set.sched[j + 1];
                tsn_sched_set.sched[j + 1] = temp;
            }
        }
    }
}

int sort_flow_by_deadline() //ascending
{
    int i = 0, j = 0;
    struct sched_info temp = {0};
    for(i = 0; i < tsn_sched_set.cur_flow_num - 1; i++)
    {
        for(j = 0; j < tsn_sched_set.cur_flow_num - i - 1; j++)
        {
            if(tsn_sched_set.sched[j].deadline_slot > tsn_sched_set.sched[j + 1].deadline_slot)
            {
                temp = tsn_sched_set.sched[j];
                tsn_sched_set.sched[j] = tsn_sched_set.sched[j + 1];
                tsn_sched_set.sched[j + 1] = temp;
            }
        }
    }
}


int sort_flow_by_pkt_num() //ascending
{
    int i = 0, j = 0;
    struct sched_info temp = {0};
    for(i = 0; i < tsn_sched_set.cur_flow_num - 1; i++)
    {
        for(j = 0; j < tsn_sched_set.cur_flow_num - i - 1; j++)
        {
            if(tsn_sched_set.sched[j].pkt_num > tsn_sched_set.sched[j + 1].pkt_num)
            {
                temp = tsn_sched_set.sched[j];
                tsn_sched_set.sched[j] = tsn_sched_set.sched[j + 1];
                tsn_sched_set.sched[j + 1] = temp;
            }
        }
    }
}

/*计算流密度：路径上最大最小值之差*/
static u32 compute_flow_density_path_diff(struct sched_info sched, u16 offset, struct global_resource g_resource)
{
    int i = 0, j = 0;
    u8 src_node = sched.src_sw_id;
    u16 node = 0;
    u16 port = 0;
    u16 slot = 0;
    u32 max_size = 0;
    u32 min_size = 0xFFFFFFFF;

    for(i = 0; i < sched.path_len; i++)
    {
        node = sched.path_info[i].sw_id;
        port = sched.path_info[i].port_id;
        for(j = 0; j < (g_resource.cur_sched_slot_num / sched.period_slot); j++)
        {
            slot = (offset + j * sched.period_slot + i + 1) % g_resource.cur_sched_slot_num;
            g_resource.cqf[node][port][slot].free_len -= sched.pkt_num;
            g_resource.cqf[node][port][slot].used_len += sched.pkt_num;
        }
    }

    for(i = 0; i < sched.path_len; i++)
    {
        node = sched.path_info[i].sw_id;
        port = sched.path_info[i].port_id;
        for(j = 0; j < g_resource.cur_sched_slot_num; j++)
        {
            if(g_resource.cqf[node][port][j].used_len > 0)
            {
                if(g_resource.cqf[node][port][j].used_len > max_size)
                    max_size = g_resource.cqf[node][port][j].used_len;
                if(g_resource.cqf[node][port][j].used_len < min_size)
                    min_size = g_resource.cqf[node][port][j].used_len;
            }
        }
    }

    return max_size - min_size;
}

/*计算流密度：路径上方差*/
static u32 compute_flow_density_path_variance(struct sched_info sched, u16 offset, struct global_resource g_resource)
{
    int i = 0, j = 0;
    u8 src_node = sched.src_sw_id;
    u16 node = 0;
    u16 port = 0;
    u16 slot = 0;
    u32 used_slot_num = 0;
    u64 total_pkt_num = 0;
    float average = 0;
    float density = 0;

    for(i = 0; i < sched.path_len; i++)
    {
        node = sched.path_info[i].sw_id;
        port = sched.path_info[i].port_id;
        for(j = 0; j < (g_resource.cur_sched_slot_num / sched.period_slot); j++)
        {
            slot = (offset + j * sched.period_slot + i + 1) % g_resource.cur_sched_slot_num;
            g_resource.cqf[node][port][slot].free_len -= sched.pkt_num;
            g_resource.cqf[node][port][slot].used_len += sched.pkt_num;
        }
    }

    for(i = 0; i < sched.path_len; i++)
    {
        node = sched.path_info[i].sw_id;
        port = sched.path_info[i].port_id;
        for(j = 0; j < g_resource.cur_sched_slot_num; j++)
        {
            total_pkt_num += g_resource.cqf[node][port][j].used_len;
            used_slot_num++;
        }
    }

    average = (float)total_pkt_num / used_slot_num;
    for(i = 0; i < sched.path_len; i++)
    {
        node = sched.path_info[i].sw_id;
        port = sched.path_info[i].port_id;
        for(j = 0; j < g_resource.cur_sched_slot_num; j++)
        {
            density += ((float)g_resource.cqf[node][port][j].used_len - average) * \
                        ((float)g_resource.cqf[node][port][j].used_len - average);
        }
    }
    density = density / used_slot_num;
//   density = sqrt(density);
//    printf("flow: %d, offset: %d, density: %f\n", sched.flow_id, offset, density);
    return (u32)density;
}


int sched_flow_with_adjust_offset_density(struct sched_info *sched)
{
    int i = 0, j = 0;
    u8 src_node = sched->src_sw_id;
    u16 node = 0;
    u16 port = 0;
    u16 slot = 0;
    int offset = 0;
    u16 latency = 0;
    u32 new_density = 0;

    sched->density = 0xFFFFFFFF;
    sched->flag = FAIL;
    for(offset = 0; offset < sched->period_slot; offset++)
    {
        latency = offset + sched->path_len + 1;
        if(latency <= sched->deadline_slot)
        {
            sched->flag = SUCCESS;
            for(i = 0; i < sched->path_len; i++)
            {
                node = sched->path_info[i].sw_id;
                port = sched->path_info[i].port_id;
                for(j = 0; j < (g_resource.cur_sched_slot_num / sched->period_slot); j++)
                {
                    slot = (offset + j * sched->period_slot + i + 1) % g_resource.cur_sched_slot_num;
                    if(g_resource.cqf[node][port][slot].free_len < sched->pkt_num)
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
                new_density = compute_flow_density_path_variance(*sched, offset, g_resource);
//              new_density = compute_flow_density_path_diff(sched, offset, g_resource);
                if(new_density <= sched->density)
                {
//                    printf("replace: flow: %d, old_density: %u, new_density: %u\n", sched.flow_id, sched.density, new_density);
                    sched->offset = offset;
                    sched->density = new_density;
                }
            }
        }
        else
        {
            break;
        }
    }

    if(sched->density != 0xFFFFFFFF)
    {
        sched->flag = SUCCESS;
        for(i = 0; i < sched->path_len; i++)
        {
            node = sched->path_info[i].sw_id;
            port = sched->path_info[i].port_id;
            for(j = 0; j < (g_resource.cur_sched_slot_num / sched->period_slot); j++)
            {
                slot = (sched->offset + j * sched->period_slot + i + 1) % g_resource.cur_sched_slot_num;
                g_resource.cqf[node][port][slot].free_len -= sched->pkt_num;
                g_resource.cqf[node][port][slot].used_len += sched->pkt_num;
            }
        }
//        printf("flow: %d, offset: %d, SUCCESS!\n", sched.flow_id, sched.offset);
/*      printf("FLOW:%d is scheduled successfully! OFFSET:%d, PATH INFO:", sched.flow_id, sched.offset);
        for(i = 0; i < sched.path_len - 1; i++)
        {
            printf("SW:[%d]->", (sched.src_sw_id + i) % NODE_NUM);
        }
        printf("SW:[%d]\n", sched.dst_sw_id);
*/      tsn_sched_set.cur_suc_num++;
    }
    else
    {
        sched->flag == FAIL;
//      printf("flow_id: %d, offset: %d, latency: %d, deadline: %d!\n", sched.flow_id, offset, latency, sched.deadline_slot);
    }

}


int sched_all_flow_with_adjust_offset_density()
{
    int i = 0;

/*    
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        tsn_sched_set.sched[i].flag = FAIL;
        tsn_sched_set.sched[i].offset = 0;
        tsn_sched_set.sched[i].density = 0;
    }
*/ 
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        if(tsn_sched_set.sched[i].flag == FAIL)
            sched_flow_with_adjust_offset_density(&tsn_sched_set.sched[i]);
    }
//    printf("%d flows with adjust offset density are sched successfully\n", tsn_sched_set.cur_suc_num);
}

int global_sched_all_flow_with_adjust_offset_density()
{
    int i = 0, j = 0, k = 0, s = 0, t = 0;
    struct sched_info min_sched = {0};
    u32 new_density = 0xFFFFFFFF;
    u8 src_node = 0;
    u16 node = 0;
    u16 port = 0;
    u16 slot = 0;
    int offset = 0;
    u16 latency = 0;
    struct sched_set temp_sched_set = {0};
    struct sched_info sched = {0};

/*
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        tsn_sched_set.sched[i].flag = FAIL;
        tsn_sched_set.sched[i].offset = 0;
        tsn_sched_set.sched[i].density = 0;
    }
*/ 
    
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        memset(&temp_sched_set, 0, sizeof(struct sched_set));
        for(j = 0; j < tsn_sched_set.cur_flow_num; j++)
        {
            sched = tsn_sched_set.sched[j];
            if(sched.flag == SUCCESS)
            {
                continue;
            }
            else
            {
                sched.density = 0xFFFFFFFF;
                sched.flag = FAIL;
                src_node = sched.src_sw_id;
                for(offset = 0; offset < sched.period_slot; offset++)
                {
                    latency = offset + sched.path_len + 1;
                    if(latency <= sched.deadline_slot)
                    {
                        sched.flag = SUCCESS;
                        for(s = 0; s < sched.path_len; s++)
                        {
                            node = sched.path_info[s].sw_id;
                            port = sched.path_info[s].port_id;
                            for(t = 0; t < (g_resource.cur_sched_slot_num / sched.period_slot); t++)
                            {
                                slot = (offset + t * sched.period_slot + s + 1) % g_resource.cur_sched_slot_num;
                                if(g_resource.cqf[node][port][slot].free_len < sched.pkt_num)
                                {
                                    sched.flag = FAIL;
                                    break;
                                }
                            }
                            if(sched.flag == FAIL)
                                break;
                        }
                        if(sched.flag == SUCCESS)
                        {
                            /*求流密度*/
                            new_density = compute_flow_density_path_variance(sched, offset, g_resource);
//                            new_density = compute_flow_density_path_diff(sched, offset, g_resource);
                            if(new_density <= sched.density)
                            {
                                sched.offset = offset;
                                sched.density = new_density;
                            }
                        }
                    }
                    else
                    {
                        break;
                    }
                }

                if(sched.density != 0xFFFFFFFF)
                {
                    sched.flag = SUCCESS;
                    temp_sched_set.sched[temp_sched_set.cur_flow_num] = sched;
                    temp_sched_set.cur_flow_num++;
                }
            }
        }
     
        if(temp_sched_set.cur_flow_num == 0)
            break;

        memset(&min_sched, 0, sizeof(struct sched_info));
        min_sched.density = 0xFFFFFFFF;
        for(k = 0; k < temp_sched_set.cur_flow_num; k++)
        {
            if(temp_sched_set.sched[k].density < min_sched.density)
            {
                min_sched = temp_sched_set.sched[k];
            }
        }
        tsn_sched_set.cur_suc_num++;
        
        for(k = 0; k < tsn_sched_set.cur_flow_num; k++)
        {
            if(min_sched.flow_id == tsn_sched_set.sched[k].flow_id)
            {
                tsn_sched_set.sched[k] = min_sched;
                break; 
            }
        }

        for(s = 0; s < min_sched.path_len; s++)
        {
            node = min_sched.path_info[s].sw_id;
            port = min_sched.path_info[s].port_id;
            for(t = 0; t < (g_resource.cur_sched_slot_num / min_sched.period_slot); t++)
            {
                slot = (min_sched.offset + t * min_sched.period_slot + s + 1) % g_resource.cur_sched_slot_num;
                g_resource.cqf[node][port][slot].free_len -= min_sched.pkt_num;
                g_resource.cqf[node][port][slot].used_len += min_sched.pkt_num;
            }
        }

//        printf("success: flow_id: %d, offset: %d, flag: %d\n", tsn_sched_set.sched[k].flow_id, \
               tsn_sched_set.sched[k].offset, tsn_sched_set.sched[k].flag);
    }

//    printf("%d flows with adjust offset density global are sched successfully\n", tsn_sched_set.cur_suc_num);
}

int sched_flow_with_adjust_offset_ascend(struct sched_info *sched)
{
    int i = 0, j = 0;
    u8 src_node = sched->src_sw_id;
    u16 node = 0;
    u16 port = 0;
    u16 slot = 0;
    int offset = 0;

    u16 latency = 0;
    
    for(offset = 0; offset < sched->period_slot; offset++)
    {
        latency = offset + sched->path_len + 1;
        if(latency <= sched->deadline_slot)
        {
            sched->flag = SUCCESS;
            for(i = 0; i < sched->path_len; i++)
            {
                node = sched->path_info[i].sw_id;
                port = sched->path_info[i].port_id;
                for(j = 0; j < (g_resource.cur_sched_slot_num / sched->period_slot); j++)
                {
                    slot = (offset + j * sched->period_slot + i + 1) % g_resource.cur_sched_slot_num;
                    if(g_resource.cqf[node][port][slot].free_len < sched->pkt_num)
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
                    for(j = 0; j < (g_resource.cur_sched_slot_num / sched->period_slot); j++)
                    {
                        slot = (offset + j * sched->period_slot + i + 1) % g_resource.cur_sched_slot_num;
                        g_resource.cqf[node][port][slot].free_len -= sched->pkt_num;
                        g_resource.cqf[node][port][slot].used_len += sched->pkt_num;
                    }
                }
 
/*                printf("FLOW:%d is scheduled successfully! OFFSET:%d, PATH INFO:", sched.flow_id, sched.offset);
                for(i = 0; i < sched.path_len - 1; i++)
                {
                    printf("SW:[%d]->", (sched.src_sw_id + i) % NODE_NUM);
                }
                printf("SW:[%d]\n", sched.dst_sw_id);
*/              tsn_sched_set.cur_suc_num++;
                break;
            }
        }
        else
        {
//            printf("flow_id: %d, offset: %d, latency: %d, deadline: %d!\n", sched.flow_id, offset, latency, sched.deadline_slot);
            sched->flag = FAIL;
            break;
        }
    }
}

int sched_all_flow_with_adjust_offset_ascend()
{
    int i = 0;

/*
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        tsn_sched_set.sched[i].flag = FAIL;
        tsn_sched_set.sched[i].offset = 0;
        tsn_sched_set.sched[i].density = 0;
    }
*/

    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        if(tsn_sched_set.sched[i].flag == FAIL)
            sched_flow_with_adjust_offset_ascend(&tsn_sched_set.sched[i]);
    }
//    printf("%d flows with adjust offset ascend are sched successfully\n", tsn_sched_set.cur_suc_num);
}


int sched_flow_with_adjust_offset_descend(struct sched_info *sched)
{
    int i = 0, j = 0;
    u8 src_node = sched->src_sw_id;
    u16 node = 0;
    u16 port = 0;
    u16 slot = 0;
    int offset = 0;
    u16 latency = 0;
    
    for(offset = sched->period_slot - 1; offset >= 0; offset--)
    {
        latency = offset + sched->path_len + 1;
        if(latency <= sched->deadline_slot)
        {
            sched->flag = SUCCESS;
            for(i = 0; i < sched->path_len; i++)
            {
                node = sched->path_info[i].sw_id;
                port = sched->path_info[i].port_id;
                for(j = 0; j < (g_resource.cur_sched_slot_num / sched->period_slot); j++)
                {
                    slot = (offset + j * sched->period_slot + i + 1) % g_resource.cur_sched_slot_num;
                    if(g_resource.cqf[node][port][slot].free_len < sched->pkt_num)
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
                    for(j = 0; j < (g_resource.cur_sched_slot_num / sched->period_slot); j++)
                    {
                        slot = (offset + j * sched->period_slot + i + 1) % g_resource.cur_sched_slot_num;
                        g_resource.cqf[node][port][slot].free_len -= sched->pkt_num;
                        g_resource.cqf[node][port][slot].used_len += sched->pkt_num;
                    }
                }
 
/*                printf("FLOW:%d is scheduled successfully! OFFSET:%d, PATH INFO:", sched.flow_id, sched.offset);
                for(i = 0; i < sched.path_len - 1; i++)
                {
                    printf("SW:[%d]->", (sched.src_sw_id + i) % NODE_NUM);
                }
                printf("SW:[%d]\n", sched.dst_sw_id);
*/              tsn_sched_set.cur_suc_num++;
                break;
            }
        }
    }
/*    if(sched.flag == FAIL)
    {
        printf("flow_id: %d, offset: %d, latency: %d, deadline: %d!\n", sched.flow_id, offset, latency, sched.deadline_slot);
    }
*/
}

int sched_all_flow_with_adjust_offset_descend()
{
    int i = 0;
/*    
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        tsn_sched_set.sched[i].flag = FAIL;
        tsn_sched_set.sched[i].offset = 0;
        tsn_sched_set.sched[i].density = 0;
    }
*/
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        if(tsn_sched_set.sched[i].flag == FAIL)
            sched_flow_with_adjust_offset_descend(&tsn_sched_set.sched[i]);
    }
//    printf("%d flows with adjust offset descend are sched successfully\n", tsn_sched_set.cur_suc_num);
}


int sched_flow_with_adjust_offset_random(struct sched_info *sched)
{
    int i = 0, j = 0;
    u8 src_node = sched->src_sw_id;
    u16 node = 0;
    u16 port = 0;
    u16 slot = 0;
    int offset = 0;
    u16 latency = 0;
    struct s_period_flag p_flag = {0};

    p_flag.total_slot_num = sched->period_slot;
    offset = random(sched->period_slot);
/*    
    while(1)
    {
        offset = random(sched->period_slot);

		if(p_flag.flag[offset] == 0)
        {
            p_flag.flag[offset] = 1;
            p_flag.cur_slot_num++;
        }
        else
        {
            if(p_flag.cur_slot_num == p_flag.total_slot_num)
                break;
            else
                continue;
        }
*/
        latency = offset + sched->path_len + 1;
        if(latency <= sched->deadline_slot)
        {
            sched->flag = SUCCESS;
            for(i = 0; i < sched->path_len; i++)
            {
                node = sched->path_info[i].sw_id;
                port = sched->path_info[i].port_id;
                for(j = 0; j < (g_resource.cur_sched_slot_num / sched->period_slot); j++)
                {
                    slot = (offset + j * sched->period_slot + i + 1) % g_resource.cur_sched_slot_num;
                    if(g_resource.cqf[node][port][slot].free_len < sched->pkt_num)
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
                    for(j = 0; j < (g_resource.cur_sched_slot_num / sched->period_slot); j++)
                    {
                        slot = (offset + j * sched->period_slot + i + 1) % g_resource.cur_sched_slot_num;
                        g_resource.cqf[node][port][slot].free_len -= sched->pkt_num;
                        g_resource.cqf[node][port][slot].used_len += sched->pkt_num;
                    }
                }
				tsn_sched_set.cur_suc_num++;
//				break;
            }
        }
//    }
}


int sched_all_flow_with_adjust_offset_random()
{
    int i = 0;

/*
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        tsn_sched_set.sched[i].flag = FAIL;
        tsn_sched_set.sched[i].offset = 0;
        tsn_sched_set.sched[i].density = 0;
    }
*/

    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        if(tsn_sched_set.sched[i].flag == FAIL)
            sched_flow_with_adjust_offset_random(&tsn_sched_set.sched[i]);
    }
//    printf("%d flows with adjust offset ascend are sched successfully\n", tsn_sched_set.cur_suc_num);
}


int sched_flow_without_adjust_offset(struct sched_info *sched)
{
    int i = 0, j = 0;
    u8 src_node = sched->src_sw_id;
    u16 node = 0;
    u16 port = 0;
    u16 slot = 0;
    u16 offset = 0;
    u16 latency = 0;
    
    latency = offset + sched->path_len + 1;
    if(latency <= sched->deadline_slot)
    {
        sched->flag = SUCCESS;
        for(i = 0; i < sched->path_len; i++)
        {
            node = sched->path_info[i].sw_id;
            port = sched->path_info[i].port_id;
            for(j = 0; j < (g_resource.cur_sched_slot_num / sched->period_slot); j++)
            {
                slot = (offset + j * sched->period_slot + i + 1) % g_resource.cur_sched_slot_num;
                if(g_resource.cqf[node][port][slot].free_len < sched->pkt_num)
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
                for(j = 0; j < (g_resource.cur_sched_slot_num / sched->period_slot); j++)
                {
                    slot = (offset + j * sched->period_slot + i + 1) % g_resource.cur_sched_slot_num;
                    g_resource.cqf[node][port][slot].free_len -= sched->pkt_num;
                    g_resource.cqf[node][port][slot].used_len += sched->pkt_num;
                }
            }
 
/*            printf("FLOW:%d is scheduled successfully! OFFSET:%d, PATH INFO:", sched.flow_id, sched.offset);
            for(i = 0; i < sched.path_len - 1; i++)
            {
                printf("SW:[%d]->", (sched.src_sw_id + i) % NODE_NUM);
            }
            printf("SW:[%d]\n", sched.dst_sw_id);
*/          tsn_sched_set.cur_suc_num++;
        }
    }
    else
    {
        sched->flag = FAIL;
    }

    if(sched->flag == FAIL)
    {
//        printf("flow_id: %d, offset: %d, latency: %d, deadline: %d!\n", sched.flow_id, offset, latency, sched.deadline_slot);
    }
}

int sched_all_flow_without_adjust_offset()
{
    int i = 0;

/*
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        tsn_sched_set.sched[i].flag = FAIL;
        tsn_sched_set.sched[i].offset = 0;
        tsn_sched_set.sched[i].density = 0;
    }
*/
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        if(tsn_sched_set.sched[i].flag == FAIL)
            sched_flow_without_adjust_offset(&tsn_sched_set.sched[i]);
    }
//    printf("%d flows without adjust offset are sched successfully\n", tsn_sched_set.cur_suc_num);
}
