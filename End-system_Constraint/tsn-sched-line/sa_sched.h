#ifndef __SA_SCHED__
#define __SA_SCHED__

#include "tsn_sched.h"
#include "tabu_sched.h"

/*生成候选解从F_SUCCESS选的流数目*/
#define SA_STEP_SIZE 5
/*同一温度下产生的候选解数目*/
#define SA_CANDIDATE_NUM 10
/*最大重复次数*/
#define SA_MAX_REPEAT_NUM 200
/*最大温度*/
#define MAX_TEMP 5000
/*最小温度*/
// #define MIN_TEMP 1e-120
#define MIN_TEMP 1e-6  // just for test. by LCL7
/*将温系数``*/
#define ANNEAL_PARA 0.995


struct sa_sched_solution
{
    int cur_suc_num;
    int cur_fail_num;
    struct sched_info sched_suc[MAX_FLOW_NUM];
    struct sched_info sched_fail[MAX_FLOW_NUM];
    struct global_resource g_resource;
};

// Add by LCL7
int sa_new_constrain_insert_check(struct sched_info *p_check_sched, struct sched_info *p_cur_sched_head, int cur_flow_num);
extern int lcm(struct sched_set tsn_sched_set);
extern int new_constrain_result_check(int cur_slot_cycle);
extern int ENDSYSTEM_CONSTRAIN_INSERT_CHECK_FLAG;
extern int NEW_CONSTRAIN_INSERT_CHECK_CALL_COUNT;
extern int NEW_CONSTRAIN_INSERT_CHECK_FLOW_PAIR_COUNT;

int sa_sched_out_random();
int sa_sched_out_pro();
int sa_sched_out_tradeoff();
int sa_sched_offset_random();
int sa_sched_offset_pro();
int sa_sched_offset_tradeoff();

#endif
