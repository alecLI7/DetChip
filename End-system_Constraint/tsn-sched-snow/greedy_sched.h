#ifndef __GREEDY_SCHED__
#define __GREEDY_SCHED__

#include "static_sched.h"

struct s_period_flag
{
    u16 flag[200];
    u16 total_slot_num;
    u16 cur_slot_num;
};

int sort_flow_by_multi_stage_rule();
int sort_flow_by_path_len();
int sort_flow_by_period();
int sort_flow_by_deadline();
int sort_flow_by_pkt_num();
/*根据流密度调度*/
int sched_all_flow_with_adjust_offset_density();
int sched_all_flow_with_adjust_offset_ascend();
int sched_all_flow_with_adjust_offset_descend();
int sched_all_flow_with_adjust_offset_random();
int sched_all_flow_without_adjust_offset();

int global_sched_all_flow_with_adjust_offset_density();
#endif
