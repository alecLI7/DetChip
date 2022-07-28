### Files Description

The Verilog files in this path contains the following Verilog modules:

| Module                   | Description                                                              |
| ------------------------ | ------------------------------------------------------------------------ |
| `DETCHIP_TOP`            | The PicoRV32 CPU                                                         |
| `picorv32`               | The CPU core reused from [PicoRV32](https://github.com/YosysHQ/picorv32) |
| `ACCESS`                 | Access Engine model                                                      |
| `TIMER_MG`               | Timer Engine                                                             |
| `REG_MG`                 | The control model for Signal Registers                                   |
| `scheduler_ts`           | Time-Sensitive Part of Scheduler Engine                                  |
| `scheduler`              | Best-Effort Part of Scheduler Engine                                     |
| `Ingress`                | Ingress Engine                                                           |
| `Egress`                 | Egress Engine                                                            |


### Tips

The `DETCHIP_TOP` model contains five memory models. We recommend using true dual-port RAM on FPGA to implement these memory models. Each model name includes depth and width. For example, `bram_DxW` denotes that the depth is `D` and the width is `W`.