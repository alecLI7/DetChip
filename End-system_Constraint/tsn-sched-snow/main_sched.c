#include "static_sched.h"
#include "greedy_sched.h"
#include "tabu_sched.h"
#include "sa_sched.h"
#include "enum_sched.h"

extern u16 period_slot_set[4];
extern double NEW_CONSTRAIN_TASK_RATIO;

double rand_prob = 1;

int main(int argc, char *argv[])
{
    int i;
    int flow_num = MAX_FLOW_NUM;
    int candidate_flow_num_set[15] = {20, 40, 60, 80, 100, 200, 400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000};

    /*-- just for test. add by LCL7 --*/
    // if (argc != 2)
    // {
    //     printf("Command Uasge: ./tsn_sched flownumber \n");
    //     return 0;
    // }
    // flow_num = atoi(argv[1]);
    

	srand((unsigned int)time(0));
    // Add by LCL7
    if (ENDSYSTEM_CONSTRAIN_FLAG)
    {
        printf("#################################\n");
        printf("### End-system Constrain Mode ###\n");
        printf("### Version 3: Insert         ###\n");
        printf("#################################\n");
    }
    else{
        printf("#################################\n");
        printf("### Original Mode             ###\n");
        printf("#################################\n");
    }

    printf("+----------------------------------------------+\n");
    printf("+--- period_slot_set:");
    for (i = 0; i < sizeof(period_slot_set) / sizeof(period_slot_set[0]); i++)
    {
        printf(" %d", period_slot_set[i]);
    }
    printf("\n+--- NEW_CONSTRAIN_TASK_RATIO: %lf \n", NEW_CONSTRAIN_TASK_RATIO);
    printf("+----------------------------------------------+\n");

    // printf("naive,flow_num: %d\n", flow_num);
    // static_schedule_restart(sched_all_flow_without_adjust_offset, NULL, NULL, flow_num);
    // printf("naive, flow_num: %d\n", flow_num);
    
    // printf("greedy, flow_num: %d\n", flow_num);
    // static_schedule_restart(sched_all_flow_with_adjust_offset_density, NULL, sort_flow_by_multi_stage_rule, flow_num);
    // printf("greedy, flow_num: %d\n", flow_num);
    
    // Change by LCL7
    // while(flow_num <= MAX_FLOW_NUM)
    for (i = 0; i < sizeof(candidate_flow_num_set) / sizeof(candidate_flow_num_set[0]); i++)
    {
        flow_num = candidate_flow_num_set[i];

        rand_prob = 0.7;    // for tabu
        printf("***************************TABU RAND PROB: %f, restart: tabu_sched_out_tradeoff, flow_num: %d**************************\n", rand_prob, flow_num);
        static_schedule_restart(tabu_sched_out_tradeoff, NULL, NULL, flow_num);
        printf("***************************TABU RAND PROB: %f, restart: tabu_sched_out_tradeoff**************************\n", rand_prob);
        printf("\n");
        rand_prob = 0.1;    // for sa
        printf("***************************SA RAND PROB: %f, restart: sa_sched_out_tradeoff , flow_num: %d**************************\n", rand_prob, flow_num);
        static_schedule_restart(sa_sched_out_tradeoff, NULL, NULL, flow_num);
        printf("***************************SA RAND PROB: %f, restart: sa_sched_out_tradeoff**************************\n", rand_prob);
        printf("\n");   

        // just for test
        // break;
    }

    return 1;
}
