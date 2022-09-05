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

### Interface Timing Diagram

<div align="center"><img src="Doc/DetChip_wavedrom.svg" alt="DetChip Interface Timing Diagram" width=370></div>

<!-- 
{signal: [
  {name: 'i_rv_clk',           wave: 'pP.....|..........|..'},
  {name: 'i_rv_rst_n',         wave: '10.1...|..........|..'},
  {name: 'i_dc_pkt_data',      wave: 'x...34.|5x...34.|5x..', data: ['head', 'body', 'tail', 'head', 'body', 'tail']},
  {name: 'i_dc_pkt_data_en',   wave: '0...1..|.0...1..|.0..'},
  {name: 'i_pkt_val',          wave: 'x...2..|.x...2..|.x..', data:['[15]:valid, [13:0]    :length', '[15]:valid, [13:0]    :length']},
  {name: 'i_pkt_val_en',       wave: '0...1..|.0...1..|.0..'},
  {name: 'o_pkt_data_usedw',   wave: '2......|.2..2...|....', data:['usedw+length<1024B', 'allmostfull', 'usedw+length     < 1024B          ']},
  {},
  {},
  {name: 'o_dc_pkt_data',      wave: 'x...34.|5x...34.|5x..', data: ['head', 'body', 'tail', 'head', 'body', 'tail']},
  {name: 'o_dc_pkt_data_en',   wave: '0...1..|.0...1..|.0..'},
  {name: 'o_dc_pkt_val',       wave: 'x...2..|.x...2..|.x..', data:['[15]:valid, [13:0]    :length', '[15]:valid, [13:0]    :length']},
  {name: 'o_dc_pkt_val_en',    wave: '0...1..|.0...1..|.0..'},
  {name: 'i_dc_pkt_data_alf',  wave: '0.....1|....0........'}
]
}
 -->

### Tips

The `DETCHIP_TOP` model contains five memory models. We recommend using true dual-port RAM on FPGA to implement these memory models. Each model name includes depth and width. For example, `bram_DxW` denotes that the depth is `D` and the width is `W`.