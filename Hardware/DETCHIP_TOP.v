/*========================================================================================================*\
          Filename : DTECHIP_TOP.v
            Author : zc & lcl7
       Description : 
       Called by : 
  Revision History : 27/07/2022 Revision 1.0  lcl7
           Company : NUDT
============================================================================================================
          Comments :
          a. 
\*========================================================================================================*/

module DTECHIP_TOP
(
//============================================== clk & rst ===========================================//
//clock & resets
 input     wire                 i_rv_clk                    //rsic clk
,input     wire                 i_rv_rst_n                  //rst of i_rv_clk

//============================================== PKT ===========================================//
,input     wire  [35:0]         i_dc_pkt_data                  //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,input     wire                 i_dc_pkt_data_en               //data enable
,input     wire  [15:0]         i_dc_pkt_val                   //frame valid & length
,input     wire                 i_dc_pkt_val_en                //valid enable
,output     wire [9:0]          o_dc_pkt_data_usedw            //fifo allmostfull

,output     reg  [35:0]         o_dc_pkt_data                  //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,output     reg                 o_dc_pkt_data_en               //data enable
,output     reg  [15:0]         o_dc_pkt_val                   //frame valid & length
,output     reg                 o_dc_pkt_val_en                //valid enable
,input     wire                 i_dc_pkt_data_alf              //fifo allmostfull

);




//====================================== internal reg/wire/param declarations ======================================//

wire                            w_rv_mem_valid                  ;
wire                            w_rv_mem_instr                  ;
wire                            w_rv_mem_ready                  ;
wire        [31:0]              w_rv_mem_addr                   ;
wire        [31:0]              w_rv_mem_wdata                  ;
wire        [ 3:0]              w_rv_mem_wstrb                  ;
wire        [31:0]              w_rv_mem_rdata                  ;
wire        [31:0]              w_rv_te_irq                     ;
wire        [31:0]              w_rv_te_eoi                     ;

wire        [15:0]              w_a_sys_mem_addr                ;
wire        [31:0]              w_a_sys_mem_din                 ;
wire        [31:0]              w_a_sys_mem_dout                ;
wire                            w_a_sys_mem_en                  ;
wire        [ 3:0]              w_a_sys_mem_we                  ;

wire        [11:0]              w_a_rx_mem_addr                 ;
wire        [31:0]              w_a_rx_mem_din                  ;
wire        [31:0]              w_a_rx_mem_dout                 ;
wire                            w_a_rx_mem_en                   ;
wire        [ 3:0]              w_a_rx_mem_we                   ;

wire        [10:0]              w_a_tx_mem_addr                 ;
wire        [31:0]              w_a_tx_mem_din                  ;
wire        [31:0]              w_a_tx_mem_dout                 ;
wire                            w_a_tx_mem_en                   ;
wire        [ 3:0]              w_a_tx_mem_we                   ;

wire        [11:0]              w_b_sys_mem_addr                ;
wire        [31:0]              w_b_sys_mem_din                 ;
wire        [31:0]              w_b_sys_mem_dout                ;
wire                            w_b_sys_mem_en                  ;
wire        [ 3:0]              w_b_sys_mem_we                  ;

wire        [11:0]              w_b_rx_mem_addr                 ;
wire        [31:0]              w_b_rx_mem_din                  ;
wire        [31:0]              w_b_rx_mem_dout                 ;
wire                            w_b_rx_mem_en                   ;
wire        [ 3:0]              w_b_rx_mem_we                   ;

wire        [10:0]              w_b_tx_mem_addr                 ;
wire        [31:0]              w_b_tx_mem_din                  ;
wire        [31:0]              w_b_tx_mem_dout                 ;
wire                            w_b_tx_mem_en                   ;
wire        [ 3:0]              w_b_tx_mem_we                   ;

wire        [11:0]              w_ts_a_rx_mem_addr              ;
wire        [31:0]              w_ts_a_rx_mem_din               ;
wire        [31:0]              w_ts_a_rx_mem_dout              ;
wire                            w_ts_a_rx_mem_en                ;
wire        [ 3:0]              w_ts_a_rx_mem_we                ;

wire        [10:0]              w_ts_a_tx_mem_addr              ;
wire        [31:0]              w_ts_a_tx_mem_din               ;
wire        [31:0]              w_ts_a_tx_mem_dout              ;
wire                            w_ts_a_tx_mem_en                ;
wire        [ 3:0]              w_ts_a_tx_mem_we                ;

wire        [11:0]              w_ts_b_rx_mem_addr              ;
wire        [31:0]              w_ts_b_rx_mem_din               ;
wire        [31:0]              w_ts_b_rx_mem_dout              ;
wire                            w_ts_b_rx_mem_en                ;
wire        [ 3:0]              w_ts_b_rx_mem_we                ;

wire        [10:0]              w_ts_b_tx_mem_addr              ;
wire        [31:0]              w_ts_b_tx_mem_din               ;
wire        [31:0]              w_ts_b_tx_mem_dout              ;
wire                            w_ts_b_tx_mem_en                ;
wire        [ 3:0]              w_ts_b_tx_mem_we                ;

wire        [11:0]              w_reg_addr                      ;
wire        [31:0]              w_reg_din                       ;
wire        [31:0]              w_reg_dout                      ;
wire                            w_reg_en                        ;
wire        [ 3:0]              w_reg_we                        ;

wire        [11:0]              w_tmr_addr                      ;
wire        [31:0]              w_tmr_din                       ;
wire        [31:0]              w_tmr_dout                      ;
wire                            w_tmr_en                        ;
wire        [ 3:0]              w_tmr_we                        ;


wire                            w_intr_stus                     ;
wire                            w_intr_start                    ;
// wire                            w_dug_en                        ;
wire                            w_wait_rvrst                    ;
wire                            w_soft_rst_en                   ;
wire                            w_load_fsh                      ;
// wire                            w_spi_rst_en                    ;
wire                            w_picore_rstn                   ;

wire                            w_timer_intr_pul                ;

wire        [ 3:0]              w_start_cfg                     ;
wire        [ 3:0]              w_rx_wr_pt                      ;
wire        [ 3:0]              w_rx_cur_pt                     ;
wire        [ 3:0]              w_rx_rd_pt                      ;
wire        [ 3:0]              w_tx_wr_pt                      ;
wire        [ 3:0]              w_tx_rd_pt                      ;
wire                            w_rx_ram_ful                    ;
wire                            w_tx_ram_ful                    ;

wire        [ 3:0]              w_ts_start_cfg                  ;
wire        [ 3:0]              w_ts_rx_wr_pt                   ;
wire        [ 3:0]              w_ts_rx_cur_pt                  ;
wire        [ 3:0]              w_ts_rx_rd_pt                   ;
wire        [ 3:0]              w_ts_tx_wr_pt                   ;
wire        [ 3:0]              w_ts_tx_rd_pt                   ;
wire                            w_ts_rx_ram_ful                 ;
wire                            w_ts_tx_ram_ful                 ;

wire                            w_ts_rx_wnd_ctrl                ;
wire                            w_ts_rx_wnd_over                ;
wire        [47:0]              w_ts_rx_wnd_lw                  ;
wire        [47:0]              w_ts_rx_wnd_up                  ;
wire                            w_ts_tx_wnd_ctrl                ;
wire                            w_ts_tx_wnd_over                ;
wire        [47:0]              w_ts_tx_wnd_lw                  ;
wire        [47:0]              w_ts_tx_wnd_up                  ;

wire        [47:0]              w_cur_time                      ;


wire      [35:0]                w_ts_mri_data                   ;   //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
wire                            w_ts_mri_data_en                ;   //data enable
wire      [15:0]                w_ts_mri_val                    ;   //frame valid & length
wire                            w_ts_mri_val_en                 ;   //valid enable
wire      [9:0]                 w_ts_mri_data_usedw             ;   //fifo usedwords
wire      [35:0]                w_ts_mti_data                   ;   //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
wire                            w_ts_mti_data_en                ;   //data enable
wire      [15:0]                w_ts_mti_val                    ;   //frame valid & length
wire                            w_ts_mti_val_en                 ;   //valid enable
wire                            w_ts_mti_data_alf               ;   //fifo allmostfull

wire      [35:0]                w_be_mri_data                   ;   //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
wire                            w_be_mri_data_en                ;   //data enable
wire      [15:0]                w_be_mri_val                    ;   //frame valid & length
wire                            w_be_mri_val_en                 ;   //valid enable
wire      [9:0]                 w_be_mri_data_usedw             ;   //fifo usedwords
wire      [35:0]                w_be_mti_data                   ;   //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
wire                            w_be_mti_data_en                ;   //data enable
wire      [15:0]                w_be_mti_val                    ;   //frame valid & length
wire                            w_be_mti_val_en                 ;   //valid enable
wire                            w_be_mti_data_alf               ;   //fifo allmostfull


//============================================ combination logic block ============================================//



//=========================================== sub-module instance ==========================================//

parameter [ 0:0] ENABLE_COUNTERS = 1;
parameter [ 0:0] ENABLE_COUNTERS64 = 1;
parameter [ 0:0] ENABLE_REGS_16_31 = 1;
parameter [ 0:0] ENABLE_REGS_DUALPORT = 1;
parameter [ 0:0] LATCHED_MEM_RDATA = 0;
parameter [ 0:0] TWO_STAGE_SHIFT = 1;
parameter [ 0:0] BARREL_SHIFTER = 0;
parameter [ 0:0] TWO_CYCLE_COMPARE = 0;
parameter [ 0:0] TWO_CYCLE_ALU = 0;
parameter [ 0:0] COMPRESSED_ISA = 1;      // changed by zc
parameter [ 0:0] CATCH_MISALIGN = 1;
parameter [ 0:0] CATCH_ILLINSN = 1;
parameter [ 0:0] ENABLE_PCPI = 0;
parameter [ 0:0] ENABLE_MUL = 0;
parameter [ 0:0] ENABLE_FAST_MUL = 0;
parameter [ 0:0] ENABLE_DIV = 0;
parameter [ 0:0] ENABLE_IRQ = 1;          // enable IRQ
parameter [ 0:0] ENABLE_IRQ_QREGS = 1;
parameter [ 0:0] ENABLE_IRQ_TIMER = 1;
parameter [ 0:0] ENABLE_TRACE = 0;
parameter [ 0:0] REGS_INIT_ZERO = 0;
parameter [31:0] MASKED_IRQ = 32'h 0000_0000;
parameter [31:0] LATCHED_IRQ = 32'h ffff_ffff;
parameter [31:0] PROGADDR_RESET = 32'h 0000_0000;
parameter [31:0] PROGADDR_IRQ = 32'h 0000_0010;
parameter [31:0] STACKADDR = 32'h ffff_ffff;

picorv32 #(
 .ENABLE_COUNTERS               (ENABLE_COUNTERS                    )
,.ENABLE_COUNTERS64             (ENABLE_COUNTERS64                  )
,.ENABLE_REGS_16_31             (ENABLE_REGS_16_31                  )
,.ENABLE_REGS_DUALPORT          (ENABLE_REGS_DUALPORT               )
,.TWO_STAGE_SHIFT               (TWO_STAGE_SHIFT                    )
,.BARREL_SHIFTER                (BARREL_SHIFTER                     )
,.TWO_CYCLE_COMPARE             (TWO_CYCLE_COMPARE                  )
,.TWO_CYCLE_ALU                 (TWO_CYCLE_ALU                      )
,.COMPRESSED_ISA                (COMPRESSED_ISA                     )
,.CATCH_MISALIGN                (CATCH_MISALIGN                     )
,.CATCH_ILLINSN                 (CATCH_ILLINSN                      )
,.ENABLE_PCPI                   (ENABLE_PCPI                        )
,.ENABLE_MUL                    (ENABLE_MUL                         )
,.ENABLE_FAST_MUL               (ENABLE_FAST_MUL                    )
,.ENABLE_DIV                    (ENABLE_DIV                         )
,.ENABLE_IRQ                    (ENABLE_IRQ                         )
,.ENABLE_IRQ_QREGS              (ENABLE_IRQ_QREGS                   )
,.ENABLE_IRQ_TIMER              (ENABLE_IRQ_TIMER                   )
,.ENABLE_TRACE                  (ENABLE_TRACE                       )
,.REGS_INIT_ZERO                (REGS_INIT_ZERO                     )
,.MASKED_IRQ                    (MASKED_IRQ                         )
,.LATCHED_IRQ                   (LATCHED_IRQ                        )
,.PROGADDR_RESET                (PROGADDR_RESET                     )
,.PROGADDR_IRQ                  (PROGADDR_IRQ                       )
,.STACKADDR                     (STACKADDR                          )
) picorv32_core (
 .clk                           (i_rv_clk                           )
,.resetn                        (w_picore_rstn                      )

,.trap                          (                                   )

,.mem_valid                     (w_rv_mem_valid                     )
,.mem_addr                      (w_rv_mem_addr                      )
,.mem_wdata                     (w_rv_mem_wdata                     )
,.mem_wstrb                     (w_rv_mem_wstrb                     )
,.mem_instr                     (w_rv_mem_instr                     )
,.mem_ready                     (w_rv_mem_ready                     )
,.mem_rdata                     (w_rv_mem_rdata                     )

,.mem_la_read                   (                                   )
,.mem_la_write                  (                                   )
,.mem_la_addr                   (                                   )
,.mem_la_wdata                  (                                   )
,.mem_la_wstrb                  (                                   )

,.pcpi_valid                    (                                   )
,.pcpi_insn                     (                                   )
,.pcpi_rs1                      (                                   )
,.pcpi_rs2                      (                                   )
,.pcpi_wr                       (1'b0                               )
,.pcpi_rd                       (32'b0                              )
,.pcpi_wait                     (1'b0                               )
,.pcpi_ready                    (1'b0                               )

,.irq                           (w_rv_te_irq                        )
,.eoi                           (w_rv_te_eoi                        )
);


scheduler_ts scheduler_ts
(
    
//============================================== clk & rst ===========================================//
//clock & resets
 .i_rv_clk                      (i_rv_clk                               )//rsic clk
,.i_rv_rst_n                    (i_rv_rst_n                             )//rst of i_rv_clk
,.i_clk_rx                      (gmii_rxc                               )//GMII receive reference clock
,.i_rst_clk_rx_n                (rst_clk_rx_n                           )//active low reset synch to clk_rx_i

 //============================================== access port  ======================================//
 //to RX_RAM
,.o_rx_mem_addr                 (w_ts_b_rx_mem_addr                     )//
,.o_rx_mem_din                  (w_ts_b_rx_mem_din                      )//
,.i_rx_mem_dout                 (w_ts_b_rx_mem_dout                     )//
,.o_rx_mem_en                   (w_ts_b_rx_mem_en                       )//
,.o_rx_mem_we                   (w_ts_b_rx_mem_we                       )//
//to TX_RAM
,.o_tx_mem_addr                 (w_ts_b_tx_mem_addr                     )//
,.o_tx_mem_din                  (w_ts_b_tx_mem_din                      )//
,.i_tx_mem_dout                 (w_ts_b_tx_mem_dout                     )//
,.o_tx_mem_en                   (w_ts_b_tx_mem_en                       )//
,.o_tx_mem_we                   (w_ts_b_tx_mem_we                       )//
//================================================== PKT  ===========================================//

,.i_pkt_data                    (w_ts_mri_data                          )//[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,.i_pkt_data_en                 (w_ts_mri_data_en                       )//data enable
,.i_pkt_val                     (w_ts_mri_val                           )//frame valid & length
,.i_pkt_val_en                  (w_ts_mri_val_en                        )//valid enable
,.o_pkt_data_usedw              (w_ts_mri_data_usedw                    )//fifo allmostfull

,.o_pkt_data                    (w_ts_mti_data                          )//[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,.o_pkt_data_en                 (w_ts_mti_data_en                       )//data enable
,.o_pkt_val                     (w_ts_mti_val                           )//frame valid & length
,.o_pkt_val_en                  (w_ts_mti_val_en                        )//valid enable
,.i_pkt_data_alf                (w_ts_mti_data_alf                      )//fifo allmostfull

//========================================== control signal ========================================//

,.i_start_cfg                   (w_ts_start_cfg                         )//the start reg
,.o_rx_wr_pt                    (w_ts_rx_wr_pt                          )//the write pointer of RX_RAM
,.i_rx_cur_pt                   (w_ts_rx_cur_pt                         )//the current pointer which is dealing of RX_RAM
,.o_rx_rd_pt                    (w_ts_rx_rd_pt                          )//the read pointer of RX_RAM
,.i_tx_wr_pt                    (w_ts_tx_wr_pt                          )//the write pointer of TX_RAM
,.o_tx_rd_pt                    (w_ts_tx_rd_pt                          )//the read pointer of TX_RAM
,.o_rx_ram_ful                  (w_ts_rx_ram_ful                        )//the full flag of RX_RAM
,.o_tx_ram_ful                  (w_ts_tx_ram_ful                        )//the full flag of TX_RAM

,.i_ts_rx_wnd_ctrl              (w_ts_rx_wnd_ctrl                       )//the control flag of rx window
,.o_ts_rx_wnd_over              (w_ts_rx_wnd_over                       )//the over flag of rx window
,.i_ts_rx_wnd_lw                (w_ts_rx_wnd_lw                         )//the lower of rx window
,.i_ts_rx_wnd_up                (w_ts_rx_wnd_up                         )//the upper of rx window
,.i_ts_tx_wnd_ctrl              (w_ts_tx_wnd_ctrl                       )//the control flag of tx window
,.o_ts_tx_wnd_over              (w_ts_tx_wnd_over                       )//the over flag of rx window
,.i_ts_tx_wnd_lw                (w_ts_tx_wnd_lw                         )//the lower of tx window
,.i_ts_tx_wnd_up                (w_ts_tx_wnd_up                         )//the upper of tx window

,.i_cur_time                    (w_cur_time                             )//the current time
//=========================================== debug signal ===========================================//
,.e1a                           (                                       )//e1a
,.e2a                           (                                       )//e2a

`ifdef DEBUG_LEVEL0
`endif

`ifdef DEBUG_LEVEL1
`endif

`ifdef DEBUG_LEVEL2
`endif

`ifdef DEBUG_LEVEL3
`endif

);

scheduler scheduler
(
    
//============================================== clk & rst ===========================================//
//clock & resets
 .i_rv_clk                      (i_rv_clk                               )//rsic clk
,.i_rv_rst_n                    (i_rv_rst_n                             )//rst of i_rv_clk
,.i_clk_rx                      (gmii_rxc                               )//GMII receive reference clock
,.i_rst_clk_rx_n                (rst_clk_rx_n                           )//active low reset synch to clk_rx_i

 //============================================== access port  ======================================//
 //to RX_RAM
,.o_rx_mem_addr                 (w_b_rx_mem_addr                        )//
,.o_rx_mem_din                  (w_b_rx_mem_din                         )//
,.i_rx_mem_dout                 (w_b_rx_mem_dout                        )//
,.o_rx_mem_en                   (w_b_rx_mem_en                          )//
,.o_rx_mem_we                   (w_b_rx_mem_we                          )//
//to TX_RAM
,.o_tx_mem_addr                 (w_b_tx_mem_addr                        )//
,.o_tx_mem_din                  (w_b_tx_mem_din                         )//
,.i_tx_mem_dout                 (w_b_tx_mem_dout                        )//
,.o_tx_mem_en                   (w_b_tx_mem_en                          )//
,.o_tx_mem_we                   (w_b_tx_mem_we                          )//
//================================================== PKT  ===========================================//

,.i_pkt_data                    (w_be_mri_data                          )//[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,.i_pkt_data_en                 (w_be_mri_data_en                       )//data enable
,.i_pkt_val                     (w_be_mri_val                           )//frame valid & length
,.i_pkt_val_en                  (w_be_mri_val_en                        )//valid enable
,.o_pkt_data_usedw              (w_be_mri_data_usedw                    )//fifo allmostfull

,.o_pkt_data                    (w_be_mti_data                          )//[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,.o_pkt_data_en                 (w_be_mti_data_en                       )//data enable
,.o_pkt_val                     (w_be_mti_val                           )//frame valid & length
,.o_pkt_val_en                  (w_be_mti_val_en                        )//valid enable
,.i_pkt_data_alf                (w_be_mti_data_alf                      )//fifo allmostfull

//========================================== control signal ========================================//

,.i_start_cfg                   (w_start_cfg                            )//the start reg
,.o_rx_wr_pt                    (w_rx_wr_pt                             )//the write pointer of RX_RAM
,.i_rx_cur_pt                   (w_rx_cur_pt                            )//the current pointer which is dealing of RX_RAM
,.o_rx_rd_pt                    (w_rx_rd_pt                             )//the read pointer of RX_RAM
,.i_tx_wr_pt                    (w_tx_wr_pt                             )//the write pointer of TX_RAM
,.o_tx_rd_pt                    (w_tx_rd_pt                             )//the read pointer of TX_RAM
,.o_rx_ram_ful                  (w_rx_ram_ful                           )//the full flag of RX_RAM
,.o_tx_ram_ful                  (w_tx_ram_ful                           )//the full flag of TX_RAM

//=========================================== debug signal ===========================================//
,.e1a                           (                                       )//e1a
,.e2a                           (                                       )//e2a

`ifdef DEBUG_LEVEL0
`endif

`ifdef DEBUG_LEVEL1
`endif

`ifdef DEBUG_LEVEL2
`endif

`ifdef DEBUG_LEVEL3
`endif

);

Ingress Ingress
(
//============================================== clk & rst ===========================================//

//system clock & resets
 .i_sys_clk                     (gmii_rxc                               )//system clk
,.i_sys_rst_n                   (rst_clk_rx_n                           )//rst of sys_clk

//========================================== Input pkt data  =======================================//

,.i_pkt_data                    (i_dc_pkt_data                          )//[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,.i_pkt_data_en                 (i_dc_pkt_data_en                       )//data enable
,.i_pkt_val                     (i_dc_pkt_val                           )//frame valid & length
,.i_pkt_val_en                  (i_dc_pkt_val_en                        )//valid enable
,.o_pkt_data_usedw              (o_dc_pkt_data_usedw                    )//fifo allmostfull

,.o_be_pkt_data                 (w_be_mri_data                          )//[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,.o_be_pkt_data_en              (w_be_mri_data_en                       )//data enable
,.o_be_pkt_val                  (w_be_mri_val                           )//frame valid & length
,.o_be_pkt_val_en               (w_be_mri_val_en                        )//valid enable
,.i_be_pkt_data_usedw           (w_be_mri_data_usedw                    )//fifo allmostfull

,.o_ts_pkt_data                 (w_ts_mri_data                          )//[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,.o_ts_pkt_data_en              (w_ts_mri_data_en                       )//data enable
,.o_ts_pkt_val                  (w_ts_mri_val                           )//frame valid & length
,.o_ts_pkt_val_en               (w_ts_mri_val_en                        )//valid enable
,.i_ts_pkt_data_usedw           (w_ts_mri_data_usedw                    )//fifo allmostfull

,.e1a                           (                                       )//e1a
,.e2a                           (                                       )//e2a

);

Egress Egress
(
//============================================== clk & rst ===========================================//

//system clock & resets
 .i_sys_clk                     (i_rv_clk                               )//system clk
,.i_sys_rst_n                   (i_rv_rst_n                             )//rst of sys_clk

//========================================== Input pkt data  =======================================//

,.i_be_pkt_data                 (w_be_mti_data                          )//[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,.i_be_pkt_data_en              (w_be_mti_data_en                       )//data enable
,.i_be_pkt_val                  (w_be_mti_val                           )//frame valid & length
,.i_be_pkt_val_en               (w_be_mti_val_en                        )//valid enable
,.o_be_pkt_data_alf             (w_be_mti_data_alf                      )//fifo allmostfull

,.i_ts_pkt_data                 (w_ts_mti_data                          )//[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,.i_ts_pkt_data_en              (w_ts_mti_data_en                       )//data enable
,.i_ts_pkt_val                  (w_ts_mti_val                           )//frame valid & length
,.i_ts_pkt_val_en               (w_ts_mti_val_en                        )//valid enable
,.o_ts_pkt_data_alf             (w_ts_mti_data_alf                      )//fifo allmostfull

,.o_pkt_data                    (o_dc_pkt_data                          )//[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,.o_pkt_data_en                 (o_dc_pkt_data_en                       )//data enable
,.o_pkt_val                     (o_dc_pkt_val                           )//frame valid & length
,.o_pkt_val_en                  (o_dc_pkt_val_en                        )//valid enable
,.i_pkt_data_alf                (i_dc_pkt_data_alf                      )//fifo allmostfull

,.e1a                           (                                       )//e1a
,.e2a                           (                                       )//e2a

);

ACCESS ACCESS
(
//============================================== clk & rst ===========================================//
//clock & resets
  .i_rv_clk                     (i_rv_clk                           )  //rsic clk
 ,.i_rv_rst_n                   (i_rv_rst_n                         )  //rst of i_rv_clk
//========================================= Input access port  =======================================//
//from picore32
,.i_rv_mem_valid                (w_rv_mem_valid                     )   //
,.i_rv_mem_instr                (w_rv_mem_instr                     )   //
,.o_rv_mem_ready                (w_rv_mem_ready                     )   //
,.i_rv_mem_addr                 (w_rv_mem_addr                      )   //
,.i_rv_mem_wdata                (w_rv_mem_wdata                     )   //
,.i_rv_mem_wstrb                (w_rv_mem_wstrb                     )   //
,.o_rv_mem_rdata                (w_rv_mem_rdata                     )   //
,.o_rv_te_irq                   (w_rv_te_irq                        )   //
,.i_rv_te_eoi                   (w_rv_te_eoi                        )   //
//from SPI
,.i_dug_mem_valid               (                                   )   //
,.i_dug_mem_instr               (                                   )   //
,.o_dug_mem_ready               (                                   )   //
,.i_dug_mem_addr                (                                   )   //
,.i_dug_mem_wdata               (                                   )   //
,.i_dug_mem_wstrb               (                                   )   //
,.o_dug_mem_rdata               (                                   )   //
//========================================= Output access port  =======================================//
//to SYS_RAM
,.o_sys_mem_addr                (w_a_sys_mem_addr                   )   //
,.o_sys_mem_din                 (w_a_sys_mem_din                    )   //
,.i_sys_mem_dout                (w_a_sys_mem_dout                   )   //
,.o_sys_mem_en                  (w_a_sys_mem_en                     )   //
,.o_sys_mem_we                  (w_a_sys_mem_we                     )   //
//to RX_RAM
,.o_rx_mem_addr                 (w_a_rx_mem_addr                    )   //
,.o_rx_mem_din                  (w_a_rx_mem_din                     )   //
,.i_rx_mem_dout                 (w_a_rx_mem_dout                    )   //
,.o_rx_mem_en                   (w_a_rx_mem_en                      )   //
,.o_rx_mem_we                   (w_a_rx_mem_we                      )   //
//to TX_RAM
,.o_tx_mem_addr                 (w_a_tx_mem_addr                    )   //
,.o_tx_mem_din                  (w_a_tx_mem_din                     )   //
,.i_tx_mem_dout                 (w_a_tx_mem_dout                    )   //
,.o_tx_mem_en                   (w_a_tx_mem_en                      )   //
,.o_tx_mem_we                   (w_a_tx_mem_we                      )   //
//to REG_MG
,.o_reg_addr                    (w_reg_addr                         )   //
,.o_reg_din                     (w_reg_din                          )   //
,.i_reg_dout                    (w_reg_dout                         )   //
,.o_reg_en                      (w_reg_en                           )   //
,.o_reg_we                      (w_reg_we                           )   //

//to TS_RX_RAM
,.o_ts_rx_mem_addr              (w_ts_a_rx_mem_addr                 )   //
,.o_ts_rx_mem_din               (w_ts_a_rx_mem_din                  )   //
,.i_ts_rx_mem_dout              (w_ts_a_rx_mem_dout                 )   //
,.o_ts_rx_mem_en                (w_ts_a_rx_mem_en                   )   //
,.o_ts_rx_mem_we                (w_ts_a_rx_mem_we                   )   //
//to TS_TX_RAM
,.o_ts_tx_mem_addr              (w_ts_a_tx_mem_addr                 )   //
,.o_ts_tx_mem_din               (w_ts_a_tx_mem_din                  )   //
,.i_ts_tx_mem_dout              (w_ts_a_tx_mem_dout                 )   //
,.o_ts_tx_mem_en                (w_ts_a_tx_mem_en                   )   //
,.o_ts_tx_mem_we                (w_ts_a_tx_mem_we                   )   //
//to REG_MG
,.o_tmr_addr                    (w_tmr_addr                         )   //
,.o_tmr_din                     (w_tmr_din                          )   //
,.i_tmr_dout                    (w_tmr_dout                         )   //
,.o_tmr_en                      (w_tmr_en                           )   //
,.o_tmr_we                      (w_tmr_we                           )   //

//========================================== control signal ========================================//
,.i_intr_stus                   (w_intr_stus                        )   //from RG_MG,high is valid,interrupt status
,.i_intr_start                  (w_intr_start                       )   //from RG_MG,high is valid,picore32 is ready to interrupt
,.i_dug_en                      (1'b0                               )   //from SPIS,high is valid,debug enable
,.i_wait_rvrst                  (1'b0                               )   //from RVRST_CTRL,high is valid,wait rst
,.i_timer_intr_pul              (w_timer_intr_pul                   )   //from TIMER_MG,high is valid,interrupt pulse
//=========================================== debug signal ===========================================//
`ifdef DEBUG_LEVEL0
`endif

`ifdef DEBUG_LEVEL1
`endif

`ifdef DEBUG_LEVEL2
`endif

`ifdef DEBUG_LEVEL3
`endif

);

REG_MG REG_MG
(

//============================================== clk & rst ===========================================//
//clock & resets
  .i_rv_clk                     (i_rv_clk                           )   //rsic clk
 ,.i_rv_rst_n                   (i_rv_rst_n                         )   //rst of i_rv_clk
//========================================= Input access port  =======================================//
//from ACCESS
,.i_reg_addr                    (w_reg_addr                         )   //
,.i_reg_din                     (w_reg_din                          )   //
,.o_reg_dout                    (w_reg_dout                         )   //
,.i_reg_en                      (w_reg_en                           )   //
,.i_reg_we                      (w_reg_we                           )   //
//========================================== control signal ========================================//
,.o_intr_stus                   (w_intr_stus                        )   //to ACCESS,high is valid,interrupt status
,.o_intr_start                  (w_intr_start                       )   //from RG_MG,high is valid,picore32 is ready to interrupt
,.o_soft_rst_en                 (w_soft_rst_en                      )   //to RVRST_CTRL,high is valid,reset enable
,.i_wait_rvrst                  (1'b0                               )   //from RVRST_CTRL,high is valid,wait rst

,.o_start_cfg                   (w_start_cfg                        )   //the start reg
,.i_rx_wr_pt                    (w_rx_wr_pt                         )   //the write pointer of RX_RAM
,.o_rx_cur_pt                   (w_rx_cur_pt                        )   //the current pointer which is dealing of RX_RAM
,.i_rx_rd_pt                    (w_rx_rd_pt                         )   //the read pointer of RX_RAM
,.o_tx_wr_pt                    (w_tx_wr_pt                         )   //the write pointer of TX_RAM
,.i_tx_rd_pt                    (w_tx_rd_pt                         )   //the read pointer of TX_RAM
,.i_rx_ram_ful                  (w_rx_ram_ful                       )   //the full flag of RX_RAM
,.i_tx_ram_ful                  (w_tx_ram_ful                       )   //the full flag of TX_RAM

,.i_ts_rx_wr_pt                 (w_ts_rx_wr_pt                      )//the write pointer of RX_RAM
,.o_ts_rx_cur_pt                (w_ts_rx_cur_pt                     )//the current pointer which is dealing of RX_RAM
,.i_ts_rx_rd_pt                 (w_ts_rx_rd_pt                      )//the read pointer of RX_RAM
,.o_ts_tx_wr_pt                 (w_ts_tx_wr_pt                      )//the write pointer of TX_RAM
,.i_ts_tx_rd_pt                 (w_ts_tx_rd_pt                      )//the read pointer of TX_RAM
,.i_ts_rx_ram_ful               (w_ts_rx_ram_ful                    )//the full flag of RX_RAM
,.i_ts_tx_ram_ful               (w_ts_tx_ram_ful                    )//the full flag of TX_RAM

,.o_ts_start_cfg                (w_ts_start_cfg                     )//the start reg for ts
,.o_ts_rx_wnd_ctrl              (w_ts_rx_wnd_ctrl                   )//the control flag of rx window
,.i_ts_rx_wnd_over              (w_ts_rx_wnd_over                   )//the over flag of rx window
,.o_ts_rx_wnd_lw                (w_ts_rx_wnd_lw                     )//the lower of rx window
,.o_ts_rx_wnd_up                (w_ts_rx_wnd_up                     )//the upper of rx window
,.o_ts_tx_wnd_ctrl              (w_ts_tx_wnd_ctrl                   )//the control flag of tx window
,.i_ts_tx_wnd_over              (w_ts_tx_wnd_over                   )//the over flag of rx window
,.o_ts_tx_wnd_lw                (w_ts_tx_wnd_lw                     )//the lower of tx window
,.o_ts_tx_wnd_up                (w_ts_tx_wnd_up                     )//the upper of tx window

,.i_sys_time                    (                                   )//should not be used. by LCL7
//=========================================== debug signal ===========================================//
`ifdef DEBUG_LEVEL0
`endif

`ifdef DEBUG_LEVEL1
`endif

`ifdef DEBUG_LEVEL2
`endif

`ifdef DEBUG_LEVEL3
`endif

);

TIMER_MG TIMER_MG
(
    
//============================================== clk & rst ===========================================//
//clock & resets
  .i_rv_clk                     (i_rv_clk                           )// rsic clk
 ,.i_rv_rst_n                   (i_rv_rst_n                         )// rst of i_rv_clk
//========================================= Input access port  =======================================//
//from ACCESS
,.i_reg_addr                    (w_tmr_addr                         )//
,.i_reg_din                     (w_tmr_din                          )//
,.o_reg_dout                    (w_tmr_dout                         )//
,.i_reg_en                      (w_tmr_en                           )//
,.i_reg_we                      (w_tmr_we                           )//
//========================================== control signal ========================================//
,.o_intr_pulse                  (w_timer_intr_pul                   )// to ACCESS, high is time-triggered interrupt
,.i_intr_start                  (w_intr_start                       )// high is valid, picore32 is ready to be interrupted
,.i_wait_rvrst                  (1'b0                               )// from RVRST_CTRL,high is valid,wait rst

,.o_cur_time                    (w_cur_time                         )// to TS scheduler
//=========================================== debug signal ===========================================//
`ifdef DEBUG_LEVEL0
`endif

`ifdef DEBUG_LEVEL1
`endif

`ifdef DEBUG_LEVEL2
`endif

`ifdef DEBUG_LEVEL3
`endif

);



sys_ins_ram SYS_RAM(
 .clka                      (i_rv_clk                               )
,.ena                       (w_a_sys_mem_en                         )
,.regcea                    (1'b1                                   )
,.wea                       (w_a_sys_mem_we                         )
,.addra                     (w_a_sys_mem_addr[14:0]                 )
,.dina                      (w_a_sys_mem_din                        )
,.douta                     (w_a_sys_mem_dout                       )
,.clkb                      (i_rv_clk                               )
,.enb                       (1'b0                                 )
,.regceb                    (1'b1                                 )
,.web                       (4'b0                                )
,.addrb                     (15'h7FFF                               )
,.dinb                      (32'hFFFF_FFFF                          )
,.doutb                     (                                       )
);

                    
adpsram4096x32rq RX_RAM(
 .clka                      (i_rv_clk                               )
,.rsta                      (~i_rv_rst_n                            )
,.ena                       (w_a_rx_mem_en                          )
,.wea                       (w_a_rx_mem_we                          )
,.addra                     (w_a_rx_mem_addr                        )
,.dina                      (w_a_rx_mem_din                         )
,.douta                     (w_a_rx_mem_dout                        )
,.clkb                      (i_rv_clk                               )
,.rstb                      (~i_rv_rst_n                            )
,.enb                       (w_b_rx_mem_en                          )
,.web                       (w_b_rx_mem_we                          )
,.addrb                     (w_b_rx_mem_addr                        )
,.dinb                      (w_b_rx_mem_din                         )
,.doutb                     (w_b_rx_mem_dout                        )
);


adpsram2048x32rq TX_RAM(
 .clka                      (i_rv_clk                               )
,.rsta                      (~i_rv_rst_n                            )
,.ena                       (w_a_tx_mem_en                          )
,.wea                       (w_a_tx_mem_we                          )
,.addra                     (w_a_tx_mem_addr                        )
,.dina                      (w_a_tx_mem_din                         )
,.douta                     (w_a_tx_mem_dout                        )
,.clkb                      (i_rv_clk                               )
,.rstb                      (~i_rv_rst_n                            )
,.enb                       (w_b_tx_mem_en                          )
,.web                       (w_b_tx_mem_we                          )
,.addrb                     (w_b_tx_mem_addr                        )
,.dinb                      (w_b_tx_mem_din                         )
,.doutb                     (w_b_tx_mem_dout                        )
);

adpsram4096x32rq TS_RX_RAM(
 .clka                      (i_rv_clk                               )
,.rsta                      (~i_rv_rst_n                            )
,.ena                       (w_ts_a_rx_mem_en                       )
,.wea                       (w_ts_a_rx_mem_we                       )
,.addra                     (w_ts_a_rx_mem_addr                     )
,.dina                      (w_ts_a_rx_mem_din                      )
,.douta                     (w_ts_a_rx_mem_dout                     )
,.clkb                      (i_rv_clk                               )
,.rstb                      (~i_rv_rst_n                            )
,.enb                       (w_ts_b_rx_mem_en                       )
,.web                       (w_ts_b_rx_mem_we                       )
,.addrb                     (w_ts_b_rx_mem_addr                     )
,.dinb                      (w_ts_b_rx_mem_din                      )
,.doutb                     (w_ts_b_rx_mem_dout                     )
);


adpsram2048x32rq TS_TX_RAM(
 .clka                      (i_rv_clk                               )
,.rsta                      (~i_rv_rst_n                            )
,.ena                       (w_ts_a_tx_mem_en                       )
,.wea                       (w_ts_a_tx_mem_we                       )
,.addra                     (w_ts_a_tx_mem_addr                     )
,.dina                      (w_ts_a_tx_mem_din                      )
,.douta                     (w_ts_a_tx_mem_dout                     )
,.clkb                      (i_rv_clk                               )
,.rstb                      (~i_rv_rst_n                            )
,.enb                       (w_ts_b_tx_mem_en                       )
,.web                       (w_ts_b_tx_mem_we                       )
,.addrb                     (w_ts_b_tx_mem_addr                     )
,.dinb                      (w_ts_b_tx_mem_din                      )
,.doutb                     (w_ts_b_tx_mem_dout                     )
);

endmodule
