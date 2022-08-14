#include "tabu_sched.h"

extern struct sched_set tsn_sched_set;
extern struct global_resource g_resource;
static int loop_num = 0;

static struct tabu_table tabu_tbl = {0};
static struct tabu_sched_solution candidate_set[CANDIDATE_NUM] = {0};
static struct tabu_sched_solution init_solution = {0};
static struct tabu_sched_solution best_so_far = {0};
static struct tabu_sched_solution cur_solution = {0};

int compare_tabu_entry(struct tabu_entry entry1, struct tabu_entry entry2)
{
    int i = 0, j = 0;
    int flag = UNEQUAL;

    for(i = 0; i < STEP_SIZE; i++)
    {
        flag = UNEQUAL;
        for(j = 0; j < STEP_SIZE; j++)
        {
            if(entry1.out[i] == entry2.out[j])
            {
                flag = EQUAL;
                break;
            }
        }
        if(flag == UNEQUAL)
        {
            return UNEQUAL;
        }
    }

    return EQUAL;
}

int insert_flow_with_adjust_offset_ascend(struct sched_info *sched, struct global_resource *resource)
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
                for(j = 0; j < (resource->cur_sched_slot_num / sched->period_slot); j++)
                {
                    slot = (offset + j * sched->period_slot + i + 1) % resource->cur_sched_slot_num;
                    if(resource->cqf[node][port][slot].free_len < sched->pkt_num)
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
                    for(j = 0; j < (resource->cur_sched_slot_num / sched->period_slot); j++)
                    {
                        slot = (offset + j * sched->period_slot + i + 1) % resource->cur_sched_slot_num;
                        resource->cqf[node][port][slot].free_len -= sched->pkt_num;
                        resource->cqf[node][port][slot].used_len += sched->pkt_num;
                    }
                }
 
/*                printf("FLOW:%d is scheduled successfully! OFFSET:%d, PATH INFO:", sched.flow_id, sched.offset);
                for(i = 0; i < sched.path_len - 1; i++)
             Increment [4]th: slot_cycle: 125, sched_cycle: 960, suc_num: 507, back_num: 0
   {
                    printf("SW:[%d]->", (sched.src_sw_id + i) % NODE_NUM);
                }
                printf("SW:[%d]\n", sched.dst_sw_id);
*/             
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

static int generate_init_solution_random()
{
    int i = 0, j = 0, s = 0, t = 0;
    int offset = 0;
    u8 node = 0;
    u8 port = 0;
    u16 slot = 0;
    u8 src_node = 0;
    int flag = 1;

    for(j = 0; j < tsn_sched_set.cur_flow_num; j++)
    {
        if(tsn_sched_set.sched[j].flag == SUCCESS)
            continue;
REPEAT:            
        if(random(2) == 1)
            offset = random(tsn_sched_set.sched[j].period_slot);
        else
            continue;
            
        flag = 0;
        src_node = tsn_sched_set.sched[j].src_sw_id;
        for(s = 0; s < tsn_sched_set.sched[j].path_len; s++)
        {
            node = tsn_sched_set.sched[j].path_info[s].sw_id;
            port = tsn_sched_set.sched[j].path_info[s].port_id;
            for(t = 0; t < (g_resource.cur_sched_slot_num / tsn_sched_set.sched[j].period_slot); t++)
            {
                slot = (offset + t * tsn_sched_set.sched[j].period_slot + s + 1) % g_resource.cur_sched_slot_num;
                g_resource.cqf[node][port][slot].free_len -= tsn_sched_set.sched[j].pkt_num;
                g_resource.cqf[node][port][slot].used_len += tsn_sched_set.sched[j].pkt_num;
                if(g_resource.cqf[node][port][slot].used_len > CQF_QUEUE_LEN)
                {
                    flag = 1;
                }
            }
        }
        
        if(flag == 1)
        {
            for(s = 0; s < tsn_sched_set.sched[j].path_len; s++)
            {
                node = tsn_sched_set.sched[j].path_info[s].sw_id;
                port = tsn_sched_set.sched[j].path_info[s].port_id;
                for(t = 0; t < (g_resource.cur_sched_slot_num / tsn_sched_set.sched[j].period_slot); t++)
                {
                    slot = (offset + t * tsn_sched_set.sched[j].period_slot + s + 1) % g_resource.cur_sched_slot_num;
                    g_resource.cqf[node][port][slot].free_len += tsn_sched_set.sched[j].pkt_num;
                    g_resource.cqf[node][port][slot].used_len -= tsn_sched_set.sched[j].pkt_num;
                }
            }
            goto REPEAT;
        }
        else
        {
            tsn_sched_set.sched[j].flag = SUCCESS;
            tsn_sched_set.sched[j].offset = offset;
            tsn_sched_set.cur_suc_num++;
        }

    }

    memset(&init_solution, 0, sizeof(struct tabu_sched_solution));
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        if(tsn_sched_set.sched[i].flag == SUCCESS)
        {
            init_solution.sched_suc[init_solution.cur_suc_num] = tsn_sched_set.sched[i];
            init_solution.cur_suc_num++;
        }
        else
        {
            init_solution.sched_fail[init_solution.cur_fail_num] = tsn_sched_set.sched[i];
            init_solution.cur_fail_num++;
        }
    }
    init_solution.g_resource = g_resource;
    best_so_far = init_solution;
    cur_solution = init_solution;

//    printf("init solution: %d\n", init_solution.cur_suc_num);
}


/*产生候选解：随机产生候选解*/
static void generate_candidate_set_random()
{
    int i = 0, j = 0, k = 0, s = 0;
    int num = 0;
    int start = 0;
    struct sched_info temp = {0};
    u8 src_node  = 0;
    u16 node = 0;
    u16 port = 0;
    u16 slot = 0;
    u32 temp_num = 0;
    u32 exchange = 0;

    for(i = 0; i < CANDIDATE_NUM * STEP_SIZE; i++)
    { 
        exchange = random(cur_solution.cur_suc_num);
        temp = cur_solution.sched_suc[cur_solution.cur_suc_num - 1 - i];
        cur_solution.sched_suc[cur_solution.cur_suc_num - 1 - i] = cur_solution.sched_suc[exchange];
        cur_solution.sched_suc[exchange] = temp;
        if(cur_solution.cur_suc_num - 1 - i == 0)
            break;
//        printf("i: %d, flow_id: %d\n", i, cur_solution.sched_suc[i].flow_id);
        
    }

    for(num = 0; num < CANDIDATE_NUM; num++)
    {
        candidate_set[num] = cur_solution;
        memset(&candidate_set[num].entry, 0, sizeof(struct tabu_entry));
        for(i = 0; i < STEP_SIZE; i++)
        {
            start = cur_solution.cur_suc_num - (num + 1) * STEP_SIZE + i;
            if(start < 0)
                start += cur_solution.cur_suc_num;
            candidate_set[num].entry.out[i] = cur_solution.sched_suc[start].flow_id;
//            printf("candidate: %d, out: %d\n", num, candidate_set[num].entry.out[i]);
            candidate_set[num].sched_suc[start].flag = FAIL;
            candidate_set[num].sched_fail[cur_solution.cur_fail_num + i] = cur_solution.sched_suc[start];
            src_node = cur_solution.sched_suc[start].src_sw_id;
            for(j = 0; j < cur_solution.sched_suc[start].path_len; j++)
            {
                node = cur_solution.sched_suc[start].path_info[j].sw_id;
                port = cur_solution.sched_suc[start].path_info[j].port_id;
                for(k = 0; k < (cur_solution.g_resource.cur_sched_slot_num / cur_solution.sched_suc[start].period_slot); k++)
                {
                    slot = (cur_solution.sched_suc[start].offset + k * cur_solution.sched_suc[start].period_slot + j + 1) \
                           % cur_solution.g_resource.cur_sched_slot_num;
                    candidate_set[num].g_resource.cqf[node][port][slot].free_len += cur_solution.sched_suc[start].pkt_num;
                    candidate_set[num].g_resource.cqf[node][port][slot].used_len -= cur_solution.sched_suc[start].pkt_num;
                }
            }
        }
        
        for(i = start + 1; i < cur_solution.cur_suc_num; i++)
        {
            candidate_set[num].sched_suc[i - STEP_SIZE] = candidate_set[num].sched_suc[i];
        }
        candidate_set[num].cur_suc_num -= STEP_SIZE;
        
        candidate_set[num].cur_fail_num += STEP_SIZE;

        for(i = 0; i < candidate_set[num].cur_fail_num / 2; i++)
        { 
            exchange = random(candidate_set[num].cur_fail_num);
            temp = candidate_set[num].sched_fail[candidate_set[num].cur_fail_num - 1 - exchange];
            candidate_set[num].sched_fail[candidate_set[num].cur_fail_num - 1 - exchange] = candidate_set[num].sched_fail[exchange];
            candidate_set[num].sched_fail[exchange] = temp;
    //        printf("i: %d, flow_id: %d\n", i, cur_solution.sched_suc[i].flow_id);
            
        }

        for(i = 0; i < candidate_set[num].cur_fail_num; i++)
        {
            insert_flow_with_adjust_offset_ascend(&candidate_set[num].sched_fail[i], &candidate_set[num].g_resource);
            if(candidate_set[num].sched_fail[i].flag == SUCCESS)
            {
                candidate_set[num].sched_suc[candidate_set[num].cur_suc_num] = candidate_set[num].sched_fail[i];
                candidate_set[num].cur_suc_num++;
//                printf("inn: %d, flow_id: %d\n", candidate_set[num].entry.in_num, candidate_set[num].sched_fail[i].flow_id);
                candidate_set[num].entry.inn[candidate_set[num].entry.in_num] = candidate_set[num].sched_fail[i].flow_id;
                candidate_set[num].entry.in_num++;
            }
        }
        
        j = 0;
        i = 0;

        temp_num = candidate_set[num].cur_fail_num;
        while(i < candidate_set[num].cur_fail_num)
        {
            if(candidate_set[num].sched_fail[i].flag == SUCCESS)
            {
                i++;
                temp_num--;
            }
            else
            {
                if(j < i)
                {
                    candidate_set[num].sched_fail[j] = candidate_set[num].sched_fail[i];
                }

                j++;
                i++;
            }
        }
        candidate_set[num].cur_fail_num = temp_num;
    }

}

int tabu_sched_out_random()
{
    int i = 0, j = 0;
    int compare_flag = UNEQUAL;
    struct tabu_sched_solution cur_best_solution = {0};
    int repeat_num = 0;
    int hit_num = 0;
    int temp_tabu_tbl_num = 0;

    generate_init_solution_random();
    while(loop_num < MAX_LOOP_NUM)
    {
//        printf("cur_solution.g_resource.sched_slot_num: %d\n", cur_solution.g_resource.cur_sched_slot_num);
        if(best_so_far.cur_suc_num == tsn_sched_set.cur_flow_num)
            break;
        
        generate_candidate_set_random();
        memset(&cur_best_solution, 0, sizeof(struct tabu_sched_solution));
        for(i = 0; i < CANDIDATE_NUM; i++)
        {
            if(candidate_set[i].cur_suc_num >= cur_best_solution.cur_suc_num)
            {
                cur_best_solution = candidate_set[i];
            }
        }

        if(cur_best_solution.cur_suc_num >= best_so_far.cur_suc_num)
        {
            if(cur_best_solution.cur_suc_num == best_so_far.cur_suc_num)
            {
                repeat_num++;
                if(repeat_num >= MAX_REPEAT_NUM)
                    break;
            }
            else
                repeat_num = 0;

//            printf("start compare, tabu: %d\n", tabu_tbl.cur_num);
            for(i = 0; i < tabu_tbl.cur_num; i++)
            {
                if(compare_tabu_entry(cur_best_solution.entry, tabu_tbl.entry[i]) == EQUAL)
                {
                    hit_num++;
//                    printf("hit tabu list: %d\n", i);
                }
            }
 
//            printf("cur_best_solution >= best so far, cur: %d, best: %d\n", cur_best_solution.cur_suc_num, best_so_far.cur_suc_num);

            best_so_far = cur_best_solution;
            cur_solution = cur_best_solution;
            tabu_tbl.entry[0] = cur_best_solution.entry;
            if(tabu_tbl.cur_num == 0)
                tabu_tbl.cur_num++;
            
            temp_tabu_tbl_num = tabu_tbl.cur_num;
            for(i = 1; i < tabu_tbl.cur_num; i++)
            {
                if(compare_tabu_entry(cur_solution.entry, tabu_tbl.entry[i]) == EQUAL)
                {
                    i++;
                    temp_tabu_tbl_num--;
                }
                else
                {
                    if(j < i)
                        tabu_tbl.entry[j] = tabu_tbl.entry[i];
                    i++;
                    j++;
                }
            }
            tabu_tbl.cur_num = temp_tabu_tbl_num;
        }
        else
        {
            repeat_num = 0;
            memset(&cur_best_solution, 0, sizeof(struct tabu_sched_solution));
//            printf("start compare, tabu: %d\n", tabu_tbl.cur_num);
            for(i = 0; i < CANDIDATE_NUM; i++)
            {
                compare_flag = UNEQUAL;
                for(j = 0; j < tabu_tbl.cur_num; j++)
                {
                    if(compare_tabu_entry(candidate_set[i].entry, tabu_tbl.entry[j]) == EQUAL)
                    {
                        compare_flag = EQUAL;
                        break;
                    }
                }

                if(compare_flag == EQUAL)
                {
                    hit_num++;
//                    printf("hit tabu list: %d\n", j);
                    continue;
                }
                else
                {
                    if(candidate_set[i].cur_suc_num >= cur_best_solution.cur_suc_num)
                    {
                        cur_best_solution = candidate_set[i];
                    }
                }
            }

            if(cur_best_solution.cur_suc_num > 0)
                cur_solution = cur_best_solution;

//            printf("cur_best_solution < best so far, cur: %d, best: %d\n", cur_best_solution.cur_suc_num, best_so_far.cur_suc_num);
            
            if(tabu_tbl.cur_num >= TABU_TBL_SIZE)
            {
                for(i = 0; i < tabu_tbl.cur_num - 1; i++)
                {
                    tabu_tbl.entry[i] = tabu_tbl.entry[i + 1];
                }
                tabu_tbl.entry[i] = cur_best_solution.entry; 
            }
            else
            {
                tabu_tbl.entry[tabu_tbl.cur_num] = cur_best_solution.entry;
                tabu_tbl.cur_num++;
            }
        }

        loop_num++;
    }
//    printf("%d flows with tabu are sched successfully, hit_num: %d!\n", best_so_far.cur_suc_num, hit_num);
    g_resource = best_so_far.g_resource;
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        tsn_sched_set.sched[i].flag = FAIL;
    }

    for(i = 0; i < best_so_far.cur_suc_num; i++)
    {
        for(j = 0; j < tsn_sched_set.cur_flow_num; j++)
        {
            if(best_so_far.sched_suc[i].flow_id == tsn_sched_set.sched[j].flow_id)
            {
                tsn_sched_set.sched[j] = best_so_far.sched_suc[i];
                break;
            }
        }
    }
    tsn_sched_set.cur_suc_num = best_so_far.cur_suc_num;
}
