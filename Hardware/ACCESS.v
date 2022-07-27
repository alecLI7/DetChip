/*========================================================================================================*\
          Filename : ACCESS.v
            Author : zc
       Description : 
	     Called by : 
  Revision History : 10/15/2021 Revision 1.0  zc
                     01/08/2022 Revision 2.0  zc,changed for DetChip
                     mm/dd/yy
           Company : NUDT
============================================================================================================
          Comments :
          a. 
\*========================================================================================================*/

module ACCESS
(
    
//============================================== clk & rst ===========================================//
//clock & resets
  input     wire                i_rv_clk                        //rsic clk
 ,input     wire                i_rv_rst_n                      //rst of i_rv_clk
//========================================= Input access port  =======================================//
//from picore32
,input      wire                i_rv_mem_valid                  //
,input      wire                i_rv_mem_instr                  //
,output     reg                 o_rv_mem_ready                  //
,input      wire    [31:0]      i_rv_mem_addr                   //
,input      wire    [31:0]      i_rv_mem_wdata                  //
,input      wire    [ 3:0]      i_rv_mem_wstrb                  //
,output     reg     [31:0]      o_rv_mem_rdata                  //
,(*mark_debug = "true" *)output     reg     [31:0]      o_rv_te_irq                     //
,(*mark_debug = "true" *)input      wire    [31:0]      i_rv_te_eoi                     //
//from SPI
,input      wire                i_dug_mem_valid                 //
,input      wire                i_dug_mem_instr                 //
,output     reg                 o_dug_mem_ready                 //
,input      wire    [31:0]      i_dug_mem_addr                  //
,input      wire    [31:0]      i_dug_mem_wdata                 //
,input      wire    [ 3:0]      i_dug_mem_wstrb                 //
,output     reg     [31:0]      o_dug_mem_rdata                 //
//========================================= Output access port  =======================================//
//to SYS_RAM
,output     reg     [15:0]      o_sys_mem_addr                  //
,output     reg     [31:0]      o_sys_mem_din                   //
,input      wire    [31:0]      i_sys_mem_dout                  //
,output     reg                 o_sys_mem_en                    //
,output     reg     [ 3:0]      o_sys_mem_we                    //
//to RX_RAM
,output     reg     [11:0]      o_rx_mem_addr                   //
,output     reg     [31:0]      o_rx_mem_din                    //
,input      wire    [31:0]      i_rx_mem_dout                   //
,output     reg                 o_rx_mem_en                     //
,output     reg     [ 3:0]      o_rx_mem_we                     //
//to TX_RAM
,output     reg     [10:0]      o_tx_mem_addr                   //
,output     reg     [31:0]      o_tx_mem_din                    //
,input      wire    [31:0]      i_tx_mem_dout                   //
,output     reg                 o_tx_mem_en                     //
,output     reg     [ 3:0]      o_tx_mem_we                     //

//to TS_RX_RAM
,output     reg     [11:0]      o_ts_rx_mem_addr                //
,output     reg     [31:0]      o_ts_rx_mem_din                 //
,input      wire    [31:0]      i_ts_rx_mem_dout                //
,output     reg                 o_ts_rx_mem_en                  //
,output     reg     [ 3:0]      o_ts_rx_mem_we                  //
//to TS_TX_RAM
,output     reg     [10:0]      o_ts_tx_mem_addr                //
,output     reg     [31:0]      o_ts_tx_mem_din                 //
,input      wire    [31:0]      i_ts_tx_mem_dout                //
,output     reg                 o_ts_tx_mem_en                  //
,output     reg     [ 3:0]      o_ts_tx_mem_we                  //

//to REG_MG
,output     reg     [11:0]      o_reg_addr                      //
,output     reg     [31:0]      o_reg_din                       //
,input      wire    [31:0]      i_reg_dout                      //
,output     reg                 o_reg_en                        //
,output     reg     [ 3:0]      o_reg_we                        //

//to TIMER_MG
,output     reg     [11:0]      o_tmr_addr                      //
,output     reg     [31:0]      o_tmr_din                       //
,input      wire    [31:0]      i_tmr_dout                      //
,output     reg                 o_tmr_en                        //
,output     reg     [ 3:0]      o_tmr_we                        //
//========================================== control signal ========================================//
,(*mark_debug = "true" *)input      wire                i_intr_stus                     //from RG_MG,high is valid,interrupt status
,(*mark_debug = "true" *)input      wire                i_intr_start                    //from RG_MG,high is valid,picore32 is ready to interrupt
,(*mark_debug = "true" *)input      wire                i_dug_en                        //from SPIS,high is valid,debug enable
,(*mark_debug = "true" *)input      wire                i_wait_rvrst                    //from RVRST_CTRL,high is valid,wait rst
,(*mark_debug = "true" *)input      wire                i_timer_intr_pul                //from TIMER)MG,high is valid,interrupt pulse
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

//====================================== internal reg/wire/param declarations ======================================//
reg                         r_dug_en                ;
reg         [7:0]           r_acc_addr              ;
reg         [7:0]           r_wait_eoi_timer        ;

localparam	EOI_TMIER               =	8'h80       ;

//FSM declarations
reg         [2:0]           r_access_cs             ;
reg         [1:0]           r_intrc_cs              ;

localparam	IDLE_ACCESS             =	3'b000      ,
            WAIT0_ACCESS            =	3'b001      ,
            WAIT1_ACCESS            =	3'b010      ,
            READB_ACCESS            =	3'b011      ,
            FSH_ACCESS              =	3'b100      ;

localparam	IDLE_INTRC              =	2'b00       ,
            EOIH_INTRC              =	2'b01       ,
            EOIL_INTRC              =	2'b10       ;

//=========================================== combination logic block ===========================================//

//=========================================== interrupt function always block ==========================================//

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        o_rv_te_irq[31:5]           <=   27'b0              ;
        o_rv_te_irq[2:0]            <=   3'b0               ;
    end
    else begin
        o_rv_te_irq[31:5]           <=   27'b0              ;
        o_rv_te_irq[2:0]            <=   3'b0               ;
    end
end

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        o_rv_te_irq[4]              <=   1'b0               ;
    end
    else begin
        o_rv_te_irq[4]              <=  i_timer_intr_pul    ;
    end
end

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_wait_eoi_timer            <=    8'b0              ;
        o_rv_te_irq[3]              <=    1'b0              ;
        r_intrc_cs                  <=  IDLE_INTRC          ;
    end
    else begin
        case(r_intrc_cs)
            IDLE_INTRC:begin
                r_wait_eoi_timer            <=    8'b0              ;
                if(i_intr_stus && i_intr_start && (~i_dug_en) && (~i_wait_rvrst))begin
                    o_rv_te_irq[3]              <=   1'b1               ;
                    r_intrc_cs                  <=  EOIH_INTRC          ;
                end
                else begin
                    o_rv_te_irq[3]              <=   1'b0               ;
                    r_intrc_cs                  <=  IDLE_INTRC          ;
                end
            end
            EOIH_INTRC:begin
                r_wait_eoi_timer            <=  r_wait_eoi_timer + 8'b1 ;
                o_rv_te_irq[3]              <=   1'b0               ;
                if(i_wait_rvrst)begin
                    r_intrc_cs                  <=  IDLE_INTRC          ;
                end
                else begin
                    if(i_rv_te_eoi[3] || (r_wait_eoi_timer == EOI_TMIER))begin
                        r_intrc_cs                  <=  EOIL_INTRC          ;
                    end
                    else begin
                        r_intrc_cs                  <=  EOIH_INTRC          ;
                    end
                end
            end
            EOIL_INTRC:begin
                r_wait_eoi_timer            <=    8'b0              ;
                o_rv_te_irq[3]              <=   1'b0               ;
                if(i_wait_rvrst)begin
                    r_intrc_cs                  <=  IDLE_INTRC          ;
                end
                else begin
                    if(i_rv_te_eoi[3])begin
                        r_intrc_cs                  <=  EOIL_INTRC          ;
                    end
                    else begin
                        r_intrc_cs                  <=  IDLE_INTRC          ;
                    end
                end
            end
            default:begin
                o_rv_te_irq[3]              <=   1'b0               ;
                r_intrc_cs                  <=  IDLE_INTRC          ;
            end
        endcase
    end
end

//=========================================== access function always block ==========================================//

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        o_rv_mem_ready              <=    1'b0              ;
        o_rv_mem_rdata              <=   32'b0              ;

        o_dug_mem_ready             <=    1'b0              ;
        o_dug_mem_rdata             <=   32'b0              ;
        
        o_sys_mem_addr              <=   16'b0              ;
        o_sys_mem_din               <=   32'b0              ;
        o_sys_mem_en                <=    1'b0              ;
        o_sys_mem_we                <=    4'b0              ;

        o_rx_mem_addr               <=   12'b0              ;
        o_rx_mem_din                <=   32'b0              ;
        o_rx_mem_en                 <=    1'b0              ;
        o_rx_mem_we                 <=    4'b0              ;

        o_tx_mem_addr               <=   11'b0              ;
        o_tx_mem_din                <=   32'b0              ;
        o_tx_mem_en                 <=    1'b0              ;
        o_tx_mem_we                 <=    4'b0              ;

        o_ts_rx_mem_addr            <=   12'b0              ;
        o_ts_rx_mem_din             <=   32'b0              ;
        o_ts_rx_mem_en              <=    1'b0              ;
        o_ts_rx_mem_we              <=    4'b0              ;

        o_ts_tx_mem_addr            <=   11'b0              ;
        o_ts_tx_mem_din             <=   32'b0              ;
        o_ts_tx_mem_en              <=    1'b0              ;
        o_ts_tx_mem_we              <=    4'b0              ;

        o_reg_addr                  <=   12'b0              ;
        o_reg_din                   <=   32'b0              ;
        o_reg_en                    <=    1'b0              ;
        o_reg_we                    <=    4'b0              ;

        o_tmr_addr                  <=   12'b0              ;
        o_tmr_din                   <=   32'b0              ;
        o_tmr_en                    <=    1'b0              ;
        o_tmr_we                    <=    4'b0              ;

        r_dug_en                    <=    1'b0              ;
        r_acc_addr                  <=    8'b0              ;

        r_access_cs                 <=  IDLE_ACCESS         ;
    end
    else begin
        case(r_access_cs)
            IDLE_ACCESS:begin
                r_dug_en                    <=    i_dug_en          ;//record the i_dug_en now

                if(i_dug_en)begin//debug mode
                    if(i_dug_mem_valid)begin
                        r_acc_addr                  <=  i_dug_mem_addr[31:24]   ;//record the address of operation

                        o_rv_mem_ready              <=    1'b0              ;
                        o_rv_mem_rdata              <=   32'b0              ;

                        o_dug_mem_ready             <=  (|i_dug_mem_wstrb)  ;//send the ack at next cycle when writing
                        o_dug_mem_rdata             <=   32'b0              ;

                        if(|i_dug_mem_wstrb)begin// write operation
                            r_access_cs                 <=  FSH_ACCESS          ;
                        end
                        else begin
                            r_access_cs                 <=  WAIT0_ACCESS        ;//wait the readata
                        end

                        if(|i_dug_mem_addr[31:29])begin//not for sys_mem
                            case(i_dug_mem_addr[31:24])
                                8'h20:begin//reg_addr
                                    o_reg_addr                  <=  i_dug_mem_addr[13:2]                ;//4B aligning
                                    o_reg_din                   <=  i_dug_mem_wdata                     ;
                                    o_reg_en                    <=  i_dug_mem_valid                     ;
                                    o_reg_we                    <=  i_dug_mem_wstrb                     ;
                                end
                                8'h21:begin//rx_mem_addr
                                    o_rx_mem_addr               <=  i_dug_mem_addr[13:2]                ;
                                    o_rx_mem_din                <=  i_dug_mem_wdata                     ;
                                    o_rx_mem_en                 <=  i_dug_mem_valid                     ;
                                    o_rx_mem_we                 <=  i_dug_mem_wstrb                     ;
                                end
                                8'h22:begin//tx_mem_addr
                                    o_tx_mem_addr               <=  i_dug_mem_addr[12:2]                ;
                                    o_tx_mem_din                <=  i_dug_mem_wdata                     ;
                                    o_tx_mem_en                 <=  i_dug_mem_valid                     ;
                                    o_tx_mem_we                 <=  i_dug_mem_wstrb                     ;
                                end
                                8'h23:begin//ts_rx_mem_addr
                                    o_ts_rx_mem_addr            <=  i_dug_mem_addr[13:2]                ;
                                    o_ts_rx_mem_din             <=  i_dug_mem_wdata                     ;
                                    o_ts_rx_mem_en              <=  i_dug_mem_valid                     ;
                                    o_ts_rx_mem_we              <=  i_dug_mem_wstrb                     ;
                                end
                                8'h24:begin//ts_tx_mem_addr
                                    o_ts_tx_mem_addr            <=  i_dug_mem_addr[12:2]                ;
                                    o_ts_tx_mem_din             <=  i_dug_mem_wdata                     ;
                                    o_ts_tx_mem_en              <=  i_dug_mem_valid                     ;
                                    o_ts_tx_mem_we              <=  i_dug_mem_wstrb                     ;
                                end
                                8'h25:begin//timer_addr
                                    o_tmr_addr                  <=  i_dug_mem_addr[13:2]                ;//4B aligning
                                    o_tmr_din                   <=  i_dug_mem_wdata                     ;
                                    o_tmr_en                    <=  i_dug_mem_valid                     ;
                                    o_tmr_we                    <=  i_dug_mem_wstrb                     ;
                                end
                                default:begin//rev_addr,error
                                    o_rx_mem_addr               <=   12'b0                              ;
                                    o_rx_mem_din                <=   32'b0                              ;
                                    o_rx_mem_en                 <=    1'b0                              ;
                                    o_rx_mem_we                 <=    4'b0                              ;

                                    o_tx_mem_addr               <=   11'b0                              ;
                                    o_tx_mem_din                <=   32'b0                              ;
                                    o_tx_mem_en                 <=    1'b0                              ;
                                    o_tx_mem_we                 <=    4'b0                              ;

                                    o_ts_rx_mem_addr            <=   12'b0                              ;
                                    o_ts_rx_mem_din             <=   32'b0                              ;
                                    o_ts_rx_mem_en              <=    1'b0                              ;
                                    o_ts_rx_mem_we              <=    4'b0                              ;

                                    o_ts_tx_mem_addr            <=   11'b0                              ;
                                    o_ts_tx_mem_din             <=   32'b0                              ;
                                    o_ts_tx_mem_en              <=    1'b0                              ;
                                    o_ts_tx_mem_we              <=    4'b0                              ;

                                    o_reg_addr                  <=   12'b0                              ;
                                    o_reg_din                   <=   32'b0                              ;
                                    o_reg_en                    <=    1'b0                              ;
                                    o_reg_we                    <=    4'b0                              ;

                                    o_tmr_addr                  <=   12'b0                              ;
                                    o_tmr_din                   <=   32'b0                              ;
                                    o_tmr_en                    <=    1'b0                              ;
                                    o_tmr_we                    <=    4'b0                              ;
                                end
                            endcase
                        end
                        else begin//sys_mem
                            // if(i_dug_mem_instr)begin//ins
                            //     o_sys_mem_addr              <=  i_dug_mem_addr[13:0]                ;//ins_mem, access unit is 4B
                            // end
                            // else begin//data
                            //     o_sys_mem_addr              <=  i_dug_mem_addr[15:2]                ;//4B aligning
                            // end
                            o_sys_mem_addr              <=  i_dug_mem_addr[17:2]                ;//4B aligning
                            o_sys_mem_din               <=  i_dug_mem_wdata                     ;
                            o_sys_mem_en                <=  i_dug_mem_valid                     ;
                            o_sys_mem_we                <=  i_dug_mem_wstrb                     ;
                        end
                    end
                    else begin
                        r_access_cs                 <=  IDLE_ACCESS         ;

                        r_acc_addr                  <=    8'b0              ;

                        o_rv_mem_ready              <=    1'b0              ;
                        o_rv_mem_rdata              <=   32'b0              ;

                        o_dug_mem_ready             <=    1'b0              ;
                        o_dug_mem_rdata             <=   32'b0              ;

                        o_sys_mem_addr              <=   16'b0              ;
                        o_sys_mem_din               <=   32'b0              ;
                        o_sys_mem_en                <=    1'b0              ;
                        o_sys_mem_we                <=    4'b0              ;

                        o_rx_mem_addr               <=   12'b0              ;
                        o_rx_mem_din                <=   32'b0              ;
                        o_rx_mem_en                 <=    1'b0              ;
                        o_rx_mem_we                 <=    4'b0              ;

                        o_tx_mem_addr               <=   11'b0              ;
                        o_tx_mem_din                <=   32'b0              ;
                        o_tx_mem_en                 <=    1'b0              ;
                        o_tx_mem_we                 <=    4'b0              ;

                        o_ts_rx_mem_addr            <=   12'b0              ;
                        o_ts_rx_mem_din             <=   32'b0              ;
                        o_ts_rx_mem_en              <=    1'b0              ;
                        o_ts_rx_mem_we              <=    4'b0              ;

                        o_ts_tx_mem_addr            <=   11'b0              ;
                        o_ts_tx_mem_din             <=   32'b0              ;
                        o_ts_tx_mem_en              <=    1'b0              ;
                        o_ts_tx_mem_we              <=    4'b0              ;

                        o_reg_addr                  <=   12'b0              ;
                        o_reg_din                   <=   32'b0              ;
                        o_reg_en                    <=    1'b0              ;
                        o_reg_we                    <=    4'b0              ;

                        o_tmr_addr                  <=   12'b0              ;
                        o_tmr_din                   <=   32'b0              ;
                        o_tmr_en                    <=    1'b0              ;
                        o_tmr_we                    <=    4'b0              ;
                    end
                end
                else begin//normal mode
                    if(i_rv_mem_valid && (~i_wait_rvrst))begin
                        r_acc_addr                  <=  i_rv_mem_addr[31:24]    ;

                        o_rv_mem_ready              <=  (|i_rv_mem_wstrb)   ;
                        o_rv_mem_rdata              <=   32'b0              ;

                        o_dug_mem_ready             <=    1'b0              ;
                        o_dug_mem_rdata             <=   32'b0              ;

                        if(|i_rv_mem_wstrb)begin// write operation
                            r_access_cs                 <=  FSH_ACCESS          ;
                        end
                        else begin
                            r_access_cs                 <=  WAIT0_ACCESS        ;//wait the readata
                        end

                        if(|i_rv_mem_addr[31:29])begin//not for sys_mem
                            case(i_rv_mem_addr[31:24])
                                8'h20:begin//reg_addr
                                    o_reg_addr                  <=  i_rv_mem_addr[13:2]                 ;
                                    o_reg_din                   <=  i_rv_mem_wdata                      ;
                                    o_reg_en                    <=  i_rv_mem_valid                      ;
                                    o_reg_we                    <=  i_rv_mem_wstrb                      ;
                                end
                                8'h21:begin//rx_mem_addr
                                    o_rx_mem_addr               <=  i_rv_mem_addr[13:2]                 ;
                                    o_rx_mem_din                <=  i_rv_mem_wdata                      ;
                                    o_rx_mem_en                 <=  i_rv_mem_valid                      ;
                                    o_rx_mem_we                 <=  i_rv_mem_wstrb                      ;
                                end
                                8'h22:begin//tx_mem_addr
                                    o_tx_mem_addr               <=  i_rv_mem_addr[12:2]                 ;
                                    o_tx_mem_din                <=  i_rv_mem_wdata                      ;
                                    o_tx_mem_en                 <=  i_rv_mem_valid                      ;
                                    o_tx_mem_we                 <=  i_rv_mem_wstrb                      ;
                                end
                                8'h23:begin//ts_rx_mem_addr
                                    o_ts_rx_mem_addr            <=  i_rv_mem_addr[13:2]                 ;
                                    o_ts_rx_mem_din             <=  i_rv_mem_wdata                      ;
                                    o_ts_rx_mem_en              <=  i_rv_mem_valid                      ;
                                    o_ts_rx_mem_we              <=  i_rv_mem_wstrb                      ;
                                end
                                8'h24:begin//ts_tx_mem_addr
                                    o_ts_tx_mem_addr            <=  i_rv_mem_addr[12:2]                 ;
                                    o_ts_tx_mem_din             <=  i_rv_mem_wdata                      ;
                                    o_ts_tx_mem_en              <=  i_rv_mem_valid                      ;
                                    o_ts_tx_mem_we              <=  i_rv_mem_wstrb                      ;
                                end
                                8'h25:begin//timer_addr
                                    o_tmr_addr                  <=  i_rv_mem_addr[13:2]                 ;
                                    o_tmr_din                   <=  i_rv_mem_wdata                      ;
                                    o_tmr_en                    <=  i_rv_mem_valid                      ;
                                    o_tmr_we                    <=  i_rv_mem_wstrb                      ;
                                end
                                default:begin//rev_addr,error
                                    o_rx_mem_addr               <=   12'b0                              ;
                                    o_rx_mem_din                <=   32'b0                              ;
                                    o_rx_mem_en                 <=    1'b0                              ;
                                    o_rx_mem_we                 <=    4'b0                              ;

                                    o_tx_mem_addr               <=   11'b0                              ;
                                    o_tx_mem_din                <=   32'b0                              ;
                                    o_tx_mem_en                 <=    1'b0                              ;
                                    o_tx_mem_we                 <=    4'b0                              ;

                                    o_ts_rx_mem_addr            <=   12'b0                              ;
                                    o_ts_rx_mem_din             <=   32'b0                              ;
                                    o_ts_rx_mem_en              <=    1'b0                              ;
                                    o_ts_rx_mem_we              <=    4'b0                              ;

                                    o_ts_tx_mem_addr            <=   11'b0                              ;
                                    o_ts_tx_mem_din             <=   32'b0                              ;
                                    o_ts_tx_mem_en              <=    1'b0                              ;
                                    o_ts_tx_mem_we              <=    4'b0                              ;

                                    o_reg_addr                  <=   12'b0                              ;
                                    o_reg_din                   <=   32'b0                              ;
                                    o_reg_en                    <=    1'b0                              ;
                                    o_reg_we                    <=    4'b0                              ;

                                    o_tmr_addr                  <=   12'b0                              ;
                                    o_tmr_din                   <=   32'b0                              ;
                                    o_tmr_en                    <=    1'b0                              ;
                                    o_tmr_we                    <=    4'b0                              ;
                                end
                            endcase
                        end
                        else begin//sys_mem
                            // if(i_rv_mem_instr)begin//ins
                            //     o_sys_mem_addr              <=  i_rv_mem_addr[13:0]                 ;
                            // end
                            // else begin//data
                            //     o_sys_mem_addr              <=  i_rv_mem_addr[15:2]                 ;
                            // end
                            o_sys_mem_addr              <=  i_rv_mem_addr[17:2]                 ;
                            o_sys_mem_din               <=  i_rv_mem_wdata                      ;
                            o_sys_mem_en                <=  i_rv_mem_valid                      ;
                            o_sys_mem_we                <=  i_rv_mem_wstrb                      ;
                        end
                    end
                    else begin
                        r_access_cs                 <=  IDLE_ACCESS         ;

                        r_acc_addr                  <=    8'b0              ;

                        o_rv_mem_ready              <=    1'b0              ;
                        o_rv_mem_rdata              <=   32'b0              ;

                        o_dug_mem_ready             <=    1'b0              ;
                        o_dug_mem_rdata             <=   32'b0              ;

                        o_sys_mem_addr              <=   16'b0              ;
                        o_sys_mem_din               <=   32'b0              ;
                        o_sys_mem_en                <=    1'b0              ;
                        o_sys_mem_we                <=    4'b0              ;

                        o_rx_mem_addr               <=   12'b0              ;
                        o_rx_mem_din                <=   32'b0              ;
                        o_rx_mem_en                 <=    1'b0              ;
                        o_rx_mem_we                 <=    4'b0              ;

                        o_tx_mem_addr               <=   11'b0              ;
                        o_tx_mem_din                <=   32'b0              ;
                        o_tx_mem_en                 <=    1'b0              ;
                        o_tx_mem_we                 <=    4'b0              ;

                        o_ts_rx_mem_addr            <=   12'b0              ;
                        o_ts_rx_mem_din             <=   32'b0              ;
                        o_ts_rx_mem_en              <=    1'b0              ;
                        o_ts_rx_mem_we              <=    4'b0              ;

                        o_ts_tx_mem_addr            <=   11'b0              ;
                        o_ts_tx_mem_din             <=   32'b0              ;
                        o_ts_tx_mem_en              <=    1'b0              ;
                        o_ts_tx_mem_we              <=    4'b0              ;

                        o_reg_addr                  <=   12'b0              ;
                        o_reg_din                   <=   32'b0              ;
                        o_reg_en                    <=    1'b0              ;
                        o_reg_we                    <=    4'b0              ;

                        o_tmr_addr                  <=   12'b0              ;
                        o_tmr_din                   <=   32'b0              ;
                        o_tmr_en                    <=    1'b0              ;
                        o_tmr_we                    <=    4'b0              ;
                    end
                end
            end
            WAIT0_ACCESS:begin
                r_dug_en                    <=  r_dug_en            ;
                r_acc_addr                  <=  r_acc_addr          ;

                o_rv_mem_ready              <=    1'b0              ;
                o_rv_mem_rdata              <=   32'b0              ;

                o_dug_mem_ready             <=    1'b0              ;
                o_dug_mem_rdata             <=   32'b0              ;

                o_sys_mem_addr              <=   16'b0              ;
                o_sys_mem_din               <=   32'b0              ;
                o_sys_mem_en                <=    1'b0              ;
                o_sys_mem_we                <=    4'b0              ;

                o_rx_mem_addr               <=   12'b0              ;
                o_rx_mem_din                <=   32'b0              ;
                o_rx_mem_en                 <=    1'b0              ;
                o_rx_mem_we                 <=    4'b0              ;

                o_tx_mem_addr               <=   11'b0              ;
                o_tx_mem_din                <=   32'b0              ;
                o_tx_mem_en                 <=    1'b0              ;
                o_tx_mem_we                 <=    4'b0              ;

                o_ts_rx_mem_addr            <=   12'b0              ;
                o_ts_rx_mem_din             <=   32'b0              ;
                o_ts_rx_mem_en              <=    1'b0              ;
                o_ts_rx_mem_we              <=    4'b0              ;

                o_ts_tx_mem_addr            <=   11'b0              ;
                o_ts_tx_mem_din             <=   32'b0              ;
                o_ts_tx_mem_en              <=    1'b0              ;
                o_ts_tx_mem_we              <=    4'b0              ;

                o_reg_addr                  <=   12'b0              ;
                o_reg_din                   <=   32'b0              ;
                o_reg_en                    <=    1'b0              ;
                o_reg_we                    <=    4'b0              ;

                o_tmr_addr                  <=   12'b0              ;
                o_tmr_din                   <=   32'b0              ;
                o_tmr_en                    <=    1'b0              ;
                o_tmr_we                    <=    4'b0              ;

                r_access_cs                 <=  WAIT1_ACCESS        ;
            end
            WAIT1_ACCESS:begin
                r_access_cs                 <=  READB_ACCESS        ;
            end
            READB_ACCESS:begin
                if(r_dug_en)begin
                    o_rv_mem_ready              <=    1'b0              ;
                    o_rv_mem_rdata              <=   32'b0              ;

                    o_dug_mem_ready             <=    1'b1              ;
                    if(|r_acc_addr[7:5])begin//not for sys_mem
                        case(r_acc_addr[7:0])
                            8'h20:begin//reg_addr
                                o_dug_mem_rdata             <=  i_reg_dout          ;
                            end
                            8'h21:begin//rx_mem_addr
                                o_dug_mem_rdata             <=  i_rx_mem_dout       ;
                            end
                            8'h22:begin//tx_mem_addr
                                o_dug_mem_rdata             <=  i_tx_mem_dout       ;
                            end
                            8'h23:begin//ts_rx_mem_addr
                                o_dug_mem_rdata             <=  i_ts_rx_mem_dout    ;
                            end
                            8'h24:begin//ts_tx_mem_addr
                                o_dug_mem_rdata             <=  i_ts_tx_mem_dout    ;
                            end
                            8'h25:begin//timer_addr
                                o_dug_mem_rdata             <=  i_tmr_dout          ;
                            end
                            default:begin//error
                                o_dug_mem_rdata             <=   32'b0              ;
                            end
                        endcase
                    end
                    else begin//sys_mem
                        o_dug_mem_rdata             <=   i_sys_mem_dout         ;
                    end
                end
                else begin
                    o_rv_mem_ready              <=    1'b1              ;

                    o_dug_mem_ready             <=    1'b0              ;
                    o_dug_mem_rdata             <=   32'b0              ;
                    if(|r_acc_addr[7:5])begin//not for sys_mem
                        case(r_acc_addr[7:0])
                            8'h20:begin//reg_addr
                                o_rv_mem_rdata              <=  i_reg_dout          ;
                            end
                            8'h21:begin//rx_mem_addr
                                o_rv_mem_rdata              <=  i_rx_mem_dout       ;
                            end
                            8'h22:begin//tx_mem_addr
                                o_rv_mem_rdata              <=  i_tx_mem_dout       ;
                            end
                            8'h23:begin//ts_rx_mem_addr
                                o_rv_mem_rdata              <=  i_ts_rx_mem_dout    ;
                            end
                            8'h24:begin//ts_tx_mem_addr
                                o_rv_mem_rdata              <=  i_ts_tx_mem_dout    ;
                            end
                            8'h25:begin//timer_addr
                                o_rv_mem_rdata              <=  i_tmr_dout          ;
                            end
                            default:begin//error
                                o_rv_mem_rdata              <=   32'b0              ;
                            end
                        endcase
                    end
                    else begin//sys_mem
                        o_rv_mem_rdata              <=   i_sys_mem_dout         ;
                    end
                end
                r_access_cs                 <=  FSH_ACCESS        ;
            end
            FSH_ACCESS:begin
                r_acc_addr                  <=    8'b0              ;

                o_rv_mem_ready              <=    1'b0              ;
                o_rv_mem_rdata              <=   32'b0              ;

                o_dug_mem_ready             <=    1'b0              ;
                o_dug_mem_rdata             <=   32'b0              ;

                o_sys_mem_addr              <=   16'b0              ;
                o_sys_mem_din               <=   32'b0              ;
                o_sys_mem_en                <=    1'b0              ;
                o_sys_mem_we                <=    4'b0              ;

                o_rx_mem_addr               <=   12'b0              ;
                o_rx_mem_din                <=   32'b0              ;
                o_rx_mem_en                 <=    1'b0              ;
                o_rx_mem_we                 <=    4'b0              ;

                o_tx_mem_addr               <=   11'b0              ;
                o_tx_mem_din                <=   32'b0              ;
                o_tx_mem_en                 <=    1'b0              ;
                o_tx_mem_we                 <=    4'b0              ;

                o_ts_rx_mem_addr            <=   12'b0              ;
                o_ts_rx_mem_din             <=   32'b0              ;
                o_ts_rx_mem_en              <=    1'b0              ;
                o_ts_rx_mem_we              <=    4'b0              ;

                o_ts_tx_mem_addr            <=   11'b0              ;
                o_ts_tx_mem_din             <=   32'b0              ;
                o_ts_tx_mem_en              <=    1'b0              ;
                o_ts_tx_mem_we              <=    4'b0              ;

                o_reg_addr                  <=   12'b0              ;
                o_reg_din                   <=   32'b0              ;
                o_reg_en                    <=    1'b0              ;
                o_reg_we                    <=    4'b0              ;

                o_tmr_addr                  <=   12'b0              ;
                o_tmr_din                   <=   32'b0              ;
                o_tmr_en                    <=    1'b0              ;
                o_tmr_we                    <=    4'b0              ;

                r_access_cs                 <=  IDLE_ACCESS         ;
            end
            default:begin
                r_access_cs                 <=  IDLE_ACCESS         ;
            end
        endcase
    end
end


//======================================= debug function always block =======================================//



endmodule
