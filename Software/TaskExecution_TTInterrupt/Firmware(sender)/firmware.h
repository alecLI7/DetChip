// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#ifndef FIRMWARE_H
#define FIRMWARE_H

#include <stdint.h>
#include <stdbool.h>

// task.c
void timer_interrupt_table_init(void);
int task_schedule(void);

// irq.c
uint32_t *irq(uint32_t *regs, uint32_t irqs);

// tuman_program.c
int master_hardware_initial(void);
void tuman_program(void);

#endif
