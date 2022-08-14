#include "sa_sched.h"

extern struct sched_set tsn_sched_set;
extern struct global_resource g_resource;
static int loop_num = 0;

static struct sa_sched_solution candidate_solution = {0};
static struct sa_sched_solution init_solution = {0};
static struct sa_sched_solution cur_solution = {0};

/*产生初始解：贪心算法解作为初始解*/
static int generate_init_solution_pro() 
{
    int i = 0;
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
    cur_solution = init_solution;
//    printf("init solution: %d\n", init_solution.cur_suc_num);
}


static void generate_candidate_solution_pro()
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


    for(i = 0; i < cur_solution.cur_suc_num; i++)
    {
        for(j = 0; j < cur_solution.cur_suc_num - i - 1; j++)
        {
            if(cur_solution.sched_suc[j].pkt_num > cur_solution.sched_suc[j + 1].pkt_num)
//            if(cur_solution.sched_suc[j].period_slot > cur_solution.sched_suc[j + 1].period_slot)
//            if(cur_solution.sched_suc[j].deadline_slot < cur_solution.sched_suc[j + 1].deadline_slot)
//            if(cur_solution.sched_suc[j].path_len > cur_solution.sched_suc[j + 1].path_len)
            {
                temp = cur_solution.sched_suc[j];
                cur_solution.sched_suc[j] = cur_solution.sched_suc[j + 1];
                cur_solution.sched_suc[j + 1] = temp;
            }
        }
    }

    candidate_solution = cur_solution;
    for(i = 0; i < SA_STEP_SIZE; i++)
    {
        start = cur_solution.cur_suc_num - SA_STEP_SIZE + i;
//            printf("candidate: %d, out: %d\n", num, candidate_set[num].entry.out[i]);
        candidate_solution.sched_suc[start].flag = FAIL;
        src_node = cur_solution.sched_suc[start].src_sw_id;
        for(j = 0; j < cur_solution.sched_suc[start].path_len; j++)
        {
            node = cur_solution.sched_suc[start].path_info[j].sw_id;
            port = cur_solution.sched_suc[start].path_info[j].port_id;
            for(k = 0; k < (cur_solution.g_resource.cur_sched_slot_num / cur_solution.sched_suc[start].period_slot); k++)
            {
                slot = (cur_solution.sched_suc[start].offset + k * cur_solution.sched_suc[start].period_slot + j + 1) \
                       % cur_solution.g_resource.cur_sched_slot_num;
                candidate_solution.g_resource.cqf[node][port][slot].free_len += cur_solution.sched_suc[start].pkt_num;
                candidate_solution.g_resource.cqf[node][port][slot].used_len -= cur_solution.sched_suc[start].pkt_num;
            }
        }

        adjust_flow_with_offset_density(&candidate_solution.sched_suc[start], &candidate_solution.g_resource);
//        adjust_flow_with_offset_descend(&candidate_solution.sched_suc[start], &candidate_solution.g_resource);
        if(candidate_solution.sched_suc[start].flag == FAIL)
        {
//                printf("sched fail\n");
            for(j = 0; j < cur_solution.sched_suc[start].path_len; j++)
            {
                node = cur_solution.sched_suc[start].path_info[j].sw_id;
                port = cur_solution.sched_suc[start].path_info[j].port_id;
                candidate_solution.sched_suc[start].flag = SUCCESS;
                for(k = 0; k < (candidate_solution.g_resource.cur_sched_slot_num / candidate_solution.sched_suc[start].period_slot); k++)
                {
                    slot = (candidate_solution.sched_suc[start].offset + k * candidate_solution.sched_suc[start].period_slot + j + 1) \
                           % candidate_solution.g_resource.cur_sched_slot_num;
                    candidate_solution.g_resource.cqf[node][port][slot].free_len -= candidate_solution.sched_suc[start].pkt_num;
                    candidate_solution.g_resource.cqf[node][port][slot].used_len += candidate_solution.sched_suc[start].pkt_num;
                }
            }
       }

        if(candidate_solution.sched_suc[start].offset == cur_solution.sched_suc[start].offset)
        {
//                printf("unchanged\n");
        }
 
    }
    
    for(i = 0; i < cur_solution.cur_fail_num; i++)
    {
        for(j = 0; j < cur_solution.cur_fail_num - i - 1; j++)
        {
            if(candidate_solution.sched_fail[j].pkt_num > candidate_solution.sched_fail[j + 1].pkt_num)
            {
                temp = candidate_solution.sched_fail[j];
                candidate_solution.sched_fail[j] = candidate_solution.sched_fail[j + 1];
                candidate_solution.sched_fail[j + 1] = temp;
            }
        }
    }

    for(i = 0; i < candidate_solution.cur_fail_num; i++)
    {
//        insert_flow_with_adjust_offset_descend(&candidate_solution.sched_fail[i], &candidate_solution.g_resource);
        insert_flow_with_adjust_offset_density(&candidate_solution.sched_fail[i], &candidate_solution.g_resource);
        if(candidate_solution.sched_fail[i].flag == SUCCESS)
        {
            candidate_solution.sched_suc[candidate_solution.cur_suc_num] = candidate_solution.sched_fail[i];
            candidate_solution.cur_suc_num++;
        }
    }
    
    j = 0;
    i = 0;

    temp_num = candidate_solution.cur_fail_num;
    while(i < candidate_solution.cur_fail_num)
    {
        if(candidate_solution.sched_fail[i].flag == SUCCESS)
        {
            i++;
            temp_num--;
        }
        else
        {
            if(j < i)
            {
                candidate_solution.sched_fail[j] = candidate_solution.sched_fail[i];
            }

            j++;
            i++;
        }
    }
    candidate_solution.cur_fail_num = temp_num;
}

int sa_sched_offset_pro()
{
    int i = 0, j = 0;
    int repeat_num = 0;
    int cur_temp = MAX_TEMP;
    int repeat_flag = 1;
    int df = 0;

    generate_init_solution_pro();
    while(cur_temp > MIN_TEMP)
    {
//        printf("cur_solution.g_resource.sched_slot_num: %d\n", cur_solution.g_resource.cur_sched_slot_num);
        if(cur_solution.cur_suc_num == tsn_sched_set.cur_flow_num)
            break;
        
        for(i = 0; i < SA_CANDIDATE_NUM; i++)
        {
            generate_candidate_solution_pro();
            if(candidate_solution.cur_suc_num == cur_solution.cur_suc_num)
            {
                repeat_num++;
                if(repeat_num >= SA_MAX_REPEAT_NUM)
                {
                    repeat_flag = 0;
                    break;
                }
            }
            else
                repeat_num = 0;
            
            if(candidate_solution.cur_suc_num >= cur_solution.cur_suc_num)
            {
                cur_solution = candidate_solution;
            }
            else
            {
                df = cur_solution.cur_suc_num - candidate_solution.cur_suc_num;
                if(exp(df/cur_temp) > ((double)rand())/RAND_MAX)
                {
                    cur_solution = candidate_solution;
                }
            }
        }

        if(repeat_flag == 0)
        {
            break;
        }
        cur_temp = cur_temp * ANNEAL_PARA;
    }

    g_resource = cur_solution.g_resource;
    for(i = 0; i < tsn_sched_set.cur_flow_num; i++)
    {
        tsn_sched_set.sched[i].flag = FAIL;
    }

    for(i = 0; i < cur_solution.cur_suc_num; i++)
    {
        for(j = 0; j < tsn_sched_set.cur_flow_num; j++)
        {
            if(cur_solution.sched_suc[i].flow_id == tsn_sched_set.sched[j].flow_id)
            {
                tsn_sched_set.sched[j] = cur_solution.sched_suc[i];
                break;
            }
        }
    }
    tsn_sched_set.cur_suc_num = cur_solution.cur_suc_num;
    
}

