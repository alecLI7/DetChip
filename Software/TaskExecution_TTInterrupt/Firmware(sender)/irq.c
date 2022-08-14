// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.

#include "firmware.h"


uint32_t *irq(uint32_t *regs, uint32_t irqs)
{
    
    // if ((irqs & (1<<3)) != 0) {         // check normal packet interrupt
    //     // disabled in DetChip version
        
    // }
    
    if ((irqs & (1<<4)) != 0) {         // check time-triggered interrupt 0x8
        task_schedule();
    }
    
    return regs;
}

