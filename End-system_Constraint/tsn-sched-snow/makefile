tsn_sched:
	gcc -g -o tsn_sched main_sched.c static_sched.c \
		greedy_sched.c \
		tabu_sched_out_random.c tabu_sched_out_pro.c tabu_sched_out_tradeoff.c \
		tabu_sched_offset_random.c tabu_sched_offset_pro.c tabu_sched_offset_tradeoff.c \
		sa_sched_out_random.c sa_sched_out_pro.c sa_sched_out_tradeoff.c \
		sa_sched_offset_random.c sa_sched_offset_pro.c sa_sched_offset_tradeoff.c \
		enum_sched.c -lm
clean:
	rm -rf tsn_sched *.o
