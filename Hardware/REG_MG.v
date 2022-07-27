/*========================================================================================================*\
          Filename : REG_MG.v
            Author : zc
       Description : 
	     Called by : 
  Revision History : 10/24/2021 Revision 1.0  zc
                     01/08/2022 Revision 2.0  zc,changed for DetChip
                     mm/dd/yy
           Company : NUDT
============================================================================================================
          Comments :
          a. 
\*========================================================================================================*/

module REG_MG
(
    
//============================================== clk & rst ===========================================//
//clock & resets
  input     wire                i_rv_clk                        //rsic clk
 ,input     wire                i_rv_rst_n                      //rst of i_rv_clk
//========================================= Input access port  =======================================//
//from ACCESS
,input      wire    [11:0]      i_reg_addr                      //
,input      wire    [31:0]      i_reg_din                       //
,output     reg     [31:0]      o_reg_dout                      //
,input      wire                i_reg_en                        //
,input      wire    [ 3:0]      i_reg_we                        //
//========================================== control signal ========================================//
,output     reg                 o_intr_stus                     //to ACCESS,high is valid,interrupt status
,output     reg                 o_intr_start                    //high is valid,picore32 is ready to interrupt
,output     reg                 o_soft_rst_en                   //to RVRST_CTRL,high is valid,reset enable
,input      wire                i_wait_rvrst                    //from RVRST_CTRL,high is valid,wait rst

,output     reg     [ 3:0]      o_start_cfg                     //the start reg
,input      wire    [ 3:0]      i_rx_wr_pt                      //the write pointer of RX_RAM
,output     reg     [ 3:0]      o_rx_cur_pt                     //the current pointer which is dealing of RX_RAM
,input      wire    [ 3:0]      i_rx_rd_pt                      //the read pointer of RX_RAM
,output     reg     [ 3:0]      o_tx_wr_pt                      //the write pointer of TX_RAM
,input      wire    [ 3:0]      i_tx_rd_pt                      //the read pointer of TX_RAM
,input      wire                i_rx_ram_ful                    //the full flag of RX_RAM
,input      wire                i_tx_ram_ful                    //the full flag of TX_RAM

,input      wire    [ 3:0]      i_ts_rx_wr_pt                   //the write pointer of RX_RAM
,output     reg     [ 3:0]      o_ts_rx_cur_pt                  //the current pointer which is dealing of RX_RAM
,input      wire    [ 3:0]      i_ts_rx_rd_pt                   //the read pointer of RX_RAM
,output     reg     [ 3:0]      o_ts_tx_wr_pt                   //the write pointer of TX_RAM
,input      wire    [ 3:0]      i_ts_tx_rd_pt                   //the read pointer of TX_RAM
,input      wire                i_ts_rx_ram_ful                 //the full flag of RX_RAM
,input      wire                i_ts_tx_ram_ful                 //the full flag of TX_RAM

,output     reg     [ 3:0]      o_ts_start_cfg                  //the start reg for ts
,output     reg                 o_ts_rx_wnd_ctrl                //the control flag of rx window
,input      wire                i_ts_rx_wnd_over                //the over flag of rx window
,output     reg     [47:0]      o_ts_rx_wnd_lw                  //the lower of rx window
,output     reg     [47:0]      o_ts_rx_wnd_up                  //the upper of rx window
,output     reg                 o_ts_tx_wnd_ctrl                //the control flag of tx window
,input      wire                i_ts_tx_wnd_over                //the over flag of rx window
,output     reg     [47:0]      o_ts_tx_wnd_lw                  //the lower of tx window
,output     reg     [47:0]      o_ts_tx_wnd_up                  //the upper of tx window

,input      wire    [47:0]      i_sys_time                      //
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


reg         [31:0]          r_software_ver          ;

reg         [31:0]          r_interrupt_mask        ;
reg         [31:0]          r_interrupt_status      ;
reg         [31:0]          r_time_status           ;
reg         [31:0]          r_fix_pps0_inv_l        ;
reg         [31:0]          r_fix_pps0_inv_h        ;
reg         [31:0]          r_fix_pps1_inv_l        ;
reg         [31:0]          r_fix_pps1_inv_h        ;
reg         [31:0]          r_pps2_target_time_l    ;
reg         [31:0]          r_pps2_target_time_h    ;
reg         [31:0]          r_pps3_target_time_l    ;
reg         [31:0]          r_pps3_target_time_h    ;

reg                         r_stus_ts_rx_wnd_over   ;
reg                         r_stus_ts_tx_wnd_over   ;


localparam	HW_VER_DATE             =   32'h20220108    ;

localparam	START_CFG_ADDR          =   12'h000     ;
localparam	SOFT_RST_EN_ADDR        =   12'h001     ;
localparam	SW_VER_ADDR             =   12'h002     ;
localparam	HW_VER_ADDR             =   12'h003     ;
localparam	INTR_MASK_ADDR          =   12'h010     ;
localparam	INTR_STUS_ADDR          =   12'h011     ;
localparam	TIME_STUS_ADDR          =   12'h012     ;
localparam	RX_WR_PT_ADDR           =   12'h020     ;
localparam	RX_CUR_PT_ADDR          =   12'h021     ;
localparam	RX_RD_PT_ADDR           =   12'h022     ;
localparam	TX_WR_PT_ADDR           =   12'h023     ;
localparam	TX_RD_PT_ADDR           =   12'h024     ;
localparam  RX_RAM_FULL_ADDR        =   12'h025     ;
localparam  TX_RAM_FULL_ADDR        =   12'h026     ;
localparam	SYS_TIME_L_ADDR         =   12'h030     ;
localparam	SYS_TIME_H_ADDR         =   12'h031     ;
localparam	PPS0_INV_L_ADDR         =   12'h032     ;
localparam	PPS0_INV_H_ADDR         =   12'h033     ;
localparam	PPS1_INV_L_ADDR         =   12'h034     ;
localparam	PPS1_INV_H_ADDR         =   12'h035     ;
localparam	PPS2_TARG_L_ADDR        =   12'h036     ;
localparam	PPS2_TARG_H_ADDR        =   12'h037     ;
localparam	PPS3_TARG_L_ADDR        =   12'h038     ;
localparam	PPS3_TARG_H_ADDR        =   12'h039     ;

localparam	TS_RX_WR_PT_ADDR        =   12'h027     ;
localparam	TS_RX_CUR_PT_ADDR       =   12'h028     ;
localparam	TS_RX_RD_PT_ADDR        =   12'h029     ;
localparam	TS_TX_WR_PT_ADDR        =   12'h02a     ;
localparam	TS_TX_RD_PT_ADDR        =   12'h02b     ;
localparam  TS_RX_RAM_FULL_ADDR     =   12'h02c     ;
localparam  TS_TX_RAM_FULL_ADDR     =   12'h02d     ;

localparam	TS_START_CFG_ADDR       =   12'h040     ;
localparam	TS_RX_WND_CTRL_ADDR     =   12'h041     ;
localparam	TS_RX_WND_OVER_ADDR     =   12'h042     ;
localparam	TS_RX_WND_LW_L_ADDR     =   12'h043     ;
localparam	TS_RX_WND_LW_H_ADDR     =   12'h044     ;
localparam	TS_RX_WND_UP_L_ADDR     =   12'h045     ;
localparam	TS_RX_WND_UP_H_ADDR     =   12'h046     ;
localparam	TS_TX_WND_CTRL_ADDR     =   12'h047     ;
localparam	TS_TX_WND_OVER_ADDR     =   12'h048     ;
localparam	TS_TX_WND_LW_L_ADDR     =   12'h049     ;
localparam	TS_TX_WND_LW_H_ADDR     =   12'h04a     ;
localparam	TS_TX_WND_UP_L_ADDR     =   12'h04b     ;
localparam	TS_TX_WND_UP_H_ADDR     =   12'h04c     ;

reg                         r_wait_rvrst            ;
reg                         r_pkt_recv              ;

reg                         r_ts_rx_wnd_over        ;
reg                         r_ts_tx_wnd_over        ;

reg         [15:0]          r_pps0_cnt_l        ;
reg         [15:0]          r_pps0_cnt_m        ;
reg         [15:0]          r_pps0_cnt_h        ;
reg                         r_pps0_pluse        ;

reg         [15:0]          r_pps1_cnt_l        ;
reg         [15:0]          r_pps1_cnt_m        ;
reg         [15:0]          r_pps1_cnt_h        ;
reg                         r_pps1_pluse        ;

reg         [31:0]          r0_intr_stus            ;
// reg         [31:0]          r1_intr_stus            ;

reg         [11:0]          r_reg_addr              ;
// reg         [31:0]          r_reg_din               ;
reg                         r_reg_en                ;
reg         [3:0]           r_reg_we                ;


wire        [31:0]          w_reg_we_bmask          ;

//=========================================== combination logic block ===========================================//

assign  w_reg_we_bmask[ 7: 0]   =   i_reg_we[0] ?   8'hFF   :   8'h0    ;
assign  w_reg_we_bmask[15: 8]   =   i_reg_we[1] ?   8'hFF   :   8'h0    ;
assign  w_reg_we_bmask[23:16]   =   i_reg_we[2] ?   8'hFF   :   8'h0    ;
assign  w_reg_we_bmask[31:24]   =   i_reg_we[3] ?   8'hFF   :   8'h0    ;

//=========================================== reg access function always block ==========================================//
always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_reg_addr                  <=   12'b0              ;
        // r_reg_din                   <=   32'b0              ;
        r_reg_en                    <=    1'b0              ;
        r_reg_we                    <=    4'b0              ;
    end
    else begin
        r_reg_addr                  <=  i_reg_addr          ;
        // r_reg_din                   <=  i_reg_din           ;
        r_reg_en                    <=  i_reg_en            ;
        r_reg_we                    <=  i_reg_we            ;
    end
end


always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        o_reg_dout                  <=  32'b0               ;
    end
    else begin
        if(r_reg_en && (~(|r_reg_we)))begin
            case(r_reg_addr[11:0])
                START_CFG_ADDR   :begin o_reg_dout <= {28'b0,   o_start_cfg }   ; end
                SW_VER_ADDR      :begin o_reg_dout <= r_software_ver            ; end
                HW_VER_ADDR      :begin o_reg_dout <= HW_VER_DATE               ; end
                INTR_MASK_ADDR   :begin o_reg_dout <= r_interrupt_mask          ; end
                INTR_STUS_ADDR   :begin o_reg_dout <= r_interrupt_status        ; end
                TIME_STUS_ADDR   :begin o_reg_dout <= r_time_status             ; end
                RX_WR_PT_ADDR    :begin o_reg_dout <= {28'b0,   i_rx_wr_pt  }   ; end
                RX_CUR_PT_ADDR   :begin o_reg_dout <= {28'b0,   o_rx_cur_pt }   ; end
                RX_RD_PT_ADDR    :begin o_reg_dout <= {28'b0,   i_rx_rd_pt  }   ; end
                TX_WR_PT_ADDR    :begin o_reg_dout <= {28'b0,   o_tx_wr_pt  }   ; end
                TX_RD_PT_ADDR    :begin o_reg_dout <= {28'b0,   i_tx_rd_pt  }   ; end
                RX_RAM_FULL_ADDR :begin o_reg_dout <= {31'b0,   i_rx_ram_ful}   ; end
                TX_RAM_FULL_ADDR :begin o_reg_dout <= {31'b0,   i_tx_ram_ful}   ; end
                SYS_TIME_L_ADDR  :begin o_reg_dout <= i_sys_time[31:0]          ; end
                SYS_TIME_H_ADDR  :begin o_reg_dout <= {16'b0,i_sys_time[47:32]} ; end
                PPS0_INV_L_ADDR  :begin o_reg_dout <= r_fix_pps0_inv_l          ; end
                PPS0_INV_H_ADDR  :begin o_reg_dout <= r_fix_pps0_inv_h          ; end
                PPS1_INV_L_ADDR  :begin o_reg_dout <= r_fix_pps1_inv_l          ; end
                PPS1_INV_H_ADDR  :begin o_reg_dout <= r_fix_pps1_inv_h          ; end
                PPS2_TARG_L_ADDR :begin o_reg_dout <= r_pps2_target_time_l      ; end
                PPS2_TARG_H_ADDR :begin o_reg_dout <= r_pps2_target_time_h      ; end
                PPS3_TARG_L_ADDR :begin o_reg_dout <= r_pps3_target_time_l      ; end
                PPS3_TARG_H_ADDR :begin o_reg_dout <= r_pps3_target_time_h      ; end

                TS_RX_WR_PT_ADDR    :begin o_reg_dout <= {28'b0, i_ts_rx_wr_pt  }   ; end
                TS_RX_CUR_PT_ADDR   :begin o_reg_dout <= {28'b0, o_ts_rx_cur_pt }   ; end
                TS_RX_RD_PT_ADDR    :begin o_reg_dout <= {28'b0, i_ts_rx_rd_pt  }   ; end
                TS_TX_WR_PT_ADDR    :begin o_reg_dout <= {28'b0, o_ts_tx_wr_pt  }   ; end
                TS_TX_RD_PT_ADDR    :begin o_reg_dout <= {28'b0, i_ts_tx_rd_pt  }   ; end
                TS_RX_RAM_FULL_ADDR :begin o_reg_dout <= {28'b0, i_ts_rx_ram_ful}   ; end
                TS_TX_RAM_FULL_ADDR :begin o_reg_dout <= {28'b0, i_ts_tx_ram_ful}   ; end

                TS_START_CFG_ADDR   :begin o_reg_dout <= {28'b0, o_ts_start_cfg     }   ; end
                TS_RX_WND_CTRL_ADDR :begin o_reg_dout <= {30'b0, o_ts_rx_wnd_ctrl   }   ; end
                TS_RX_WND_OVER_ADDR :begin o_reg_dout <= {30'b0, r_stus_ts_rx_wnd_over} ; end
                TS_RX_WND_LW_L_ADDR :begin o_reg_dout <= o_ts_rx_wnd_lw[31:0]           ; end
                TS_RX_WND_LW_H_ADDR :begin o_reg_dout <= {16'b0, o_ts_rx_wnd_lw[47:32]} ; end
                TS_RX_WND_UP_L_ADDR :begin o_reg_dout <= o_ts_rx_wnd_up[31:0]           ; end
                TS_RX_WND_UP_H_ADDR :begin o_reg_dout <= {16'b0, o_ts_rx_wnd_up[47:32]} ; end
                TS_TX_WND_CTRL_ADDR :begin o_reg_dout <= {30'b0, o_ts_tx_wnd_ctrl   }   ; end
                TS_TX_WND_OVER_ADDR :begin o_reg_dout <= {30'b0, r_stus_ts_tx_wnd_over} ; end
                TS_TX_WND_LW_L_ADDR :begin o_reg_dout <= o_ts_tx_wnd_lw[31:0]           ; end
                TS_TX_WND_LW_H_ADDR :begin o_reg_dout <= {16'b0, o_ts_tx_wnd_lw[47:32]} ; end
                TS_TX_WND_UP_L_ADDR :begin o_reg_dout <= o_ts_tx_wnd_up[31:0]           ; end
                TS_TX_WND_UP_H_ADDR :begin o_reg_dout <= {16'b0, o_ts_tx_wnd_up[47:32]} ; end
                default:          begin o_reg_dout <= o_reg_dout                ; end
            endcase
        end
        else begin
            o_reg_dout  <=  o_reg_dout  ;
        end
    end
end



always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        o_start_cfg                 <=   4'b0               ;
        r_interrupt_mask            <=  32'b0               ;
        // r_interrupt_status          <=  32'b0               ;
        o_rx_cur_pt                 <=   4'b0               ;
        o_tx_wr_pt                  <=   4'b0               ;
        // o_tx_ram_ful                <=   1'b0               ;
        r_fix_pps0_inv_l            <=  32'b0               ;
        r_fix_pps0_inv_h            <=  32'b0               ;
        r_fix_pps1_inv_l            <=  32'b0               ;
        r_fix_pps1_inv_h            <=  32'b0               ;
        r_pps2_target_time_l        <=  32'b0               ;
        r_pps2_target_time_h        <=  32'b0               ;
        r_pps3_target_time_l        <=  32'b0               ;
        r_pps3_target_time_h        <=  32'b0               ;

        o_ts_rx_cur_pt              <=   4'b0               ;
        o_ts_tx_wr_pt               <=   4'b0               ;
        o_ts_start_cfg              <=   4'b0               ;
        o_ts_rx_wnd_ctrl            <=   1'b0               ;
        o_ts_rx_wnd_lw              <=  48'b0               ;
        o_ts_rx_wnd_up              <=  48'b0               ;
        o_ts_tx_wnd_ctrl            <=   1'b0               ;
        o_ts_tx_wnd_lw              <=  48'b0               ;
        o_ts_tx_wnd_up              <=  48'b0               ;

    end
    else begin
        if(i_reg_en && (|i_reg_we))begin
            case(i_reg_addr[11:0])
                START_CFG_ADDR   : begin o_start_cfg          <= (i_reg_din[ 3:0] & w_reg_we_bmask[ 3:0]) | (o_start_cfg         [ 3:0] & (~w_reg_we_bmask[ 3:0])); end
                SW_VER_ADDR      : begin r_software_ver       <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_software_ver      [31:0] & (~w_reg_we_bmask[31:0])); end
                INTR_MASK_ADDR   : begin r_interrupt_mask     <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_interrupt_mask    [31:0] & (~w_reg_we_bmask[31:0])); end
                // INTR_STUS_ADDR   : begin r_interrupt_status   <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_interrupt_status  [31:0] & (~w_reg_we_bmask[31:0])); end
                RX_CUR_PT_ADDR   : begin o_rx_cur_pt          <= (i_reg_din[ 3:0] & w_reg_we_bmask[ 3:0]) | (o_rx_cur_pt         [ 3:0] & (~w_reg_we_bmask[ 3:0])); end
                TX_WR_PT_ADDR    : begin o_tx_wr_pt           <= (i_reg_din[ 3:0] & w_reg_we_bmask[ 3:0]) | (o_tx_wr_pt          [ 3:0] & (~w_reg_we_bmask[ 3:0])); end
                // TX_RAM_FULL_ADDR : begin o_tx_ram_ful         <= (i_reg_din[ 0:0] & w_reg_we_bmask[ 0:0]) | (o_tx_ram_ful        [ 0:0] & (~w_reg_we_bmask[ 0:0])); end
                
                PPS0_INV_L_ADDR  : begin r_fix_pps0_inv_l     <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_fix_pps0_inv_l    [31:0] & (~w_reg_we_bmask[31:0])); end
                PPS0_INV_H_ADDR  : begin r_fix_pps0_inv_h     <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_fix_pps0_inv_h    [31:0] & (~w_reg_we_bmask[31:0])); end
                PPS1_INV_L_ADDR  : begin r_fix_pps1_inv_l     <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_fix_pps1_inv_l    [31:0] & (~w_reg_we_bmask[31:0])); end
                PPS1_INV_H_ADDR  : begin r_fix_pps1_inv_h     <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_fix_pps1_inv_h    [31:0] & (~w_reg_we_bmask[31:0])); end
                PPS2_TARG_L_ADDR : begin r_pps2_target_time_l <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_pps2_target_time_l[31:0] & (~w_reg_we_bmask[31:0])); end
                PPS2_TARG_H_ADDR : begin r_pps2_target_time_h <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_pps2_target_time_h[31:0] & (~w_reg_we_bmask[31:0])); end
                PPS3_TARG_L_ADDR : begin r_pps3_target_time_l <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_pps3_target_time_l[31:0] & (~w_reg_we_bmask[31:0])); end
                PPS3_TARG_H_ADDR : begin r_pps3_target_time_h <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_pps3_target_time_h[31:0] & (~w_reg_we_bmask[31:0])); end
                
                TS_RX_CUR_PT_ADDR   : begin o_ts_rx_cur_pt          <= (i_reg_din[ 3:0] & w_reg_we_bmask[ 3:0]) | (o_ts_rx_cur_pt       [ 3:0]  & (~w_reg_we_bmask[ 3:0])); end
                TS_TX_WR_PT_ADDR    : begin o_ts_tx_wr_pt           <= (i_reg_din[ 3:0] & w_reg_we_bmask[ 3:0]) | (o_ts_tx_wr_pt        [ 3:0]  & (~w_reg_we_bmask[ 3:0])); end
                TS_START_CFG_ADDR   : begin o_ts_start_cfg          <= (i_reg_din[ 3:0] & w_reg_we_bmask[ 3:0]) | (o_ts_start_cfg       [ 3:0]  & (~w_reg_we_bmask[ 3:0])); end
                TS_RX_WND_CTRL_ADDR : begin o_ts_rx_wnd_ctrl        <= (i_reg_din[   0] & w_reg_we_bmask[   0]) | (o_ts_rx_wnd_ctrl             & (~w_reg_we_bmask[   0])); end
                TS_RX_WND_LW_L_ADDR : begin o_ts_rx_wnd_lw[31:0]    <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (o_ts_rx_wnd_lw       [31:0]  & (~w_reg_we_bmask[31:0])); end
                TS_RX_WND_LW_H_ADDR : begin o_ts_rx_wnd_lw[47:32]   <= (i_reg_din[15:0] & w_reg_we_bmask[15:0]) | (o_ts_rx_wnd_lw       [47:32] & (~w_reg_we_bmask[15:0])); end
                TS_RX_WND_UP_L_ADDR : begin o_ts_rx_wnd_up[31:0]    <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (o_ts_rx_wnd_up       [31:0]  & (~w_reg_we_bmask[31:0])); end
                TS_RX_WND_UP_H_ADDR : begin o_ts_rx_wnd_up[47:32]   <= (i_reg_din[15:0] & w_reg_we_bmask[15:0]) | (o_ts_rx_wnd_up       [47:32] & (~w_reg_we_bmask[15:0])); end
                TS_TX_WND_CTRL_ADDR : begin o_ts_tx_wnd_ctrl        <= (i_reg_din[   0] & w_reg_we_bmask[   0]) | (o_ts_tx_wnd_ctrl             & (~w_reg_we_bmask[   0])); end
                TS_TX_WND_LW_L_ADDR : begin o_ts_tx_wnd_lw[31:0]    <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (o_ts_tx_wnd_lw       [31:0]  & (~w_reg_we_bmask[31:0])); end
                TS_TX_WND_LW_H_ADDR : begin o_ts_tx_wnd_lw[47:32]   <= (i_reg_din[15:0] & w_reg_we_bmask[15:0]) | (o_ts_tx_wnd_lw       [47:32] & (~w_reg_we_bmask[15:0])); end
                TS_TX_WND_UP_L_ADDR : begin o_ts_tx_wnd_up[31:0]    <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (o_ts_tx_wnd_up       [31:0]  & (~w_reg_we_bmask[31:0])); end
                TS_TX_WND_UP_H_ADDR : begin o_ts_tx_wnd_up[47:32]   <= (i_reg_din[15:0] & w_reg_we_bmask[15:0]) | (o_ts_tx_wnd_up       [47:32] & (~w_reg_we_bmask[15:0])); end
                default:begin end
            endcase
        end
        else begin
            o_start_cfg                 <=  o_start_cfg                 ;
            r_interrupt_mask            <=  r_interrupt_mask            ;
            // r_interrupt_status          <=  r_interrupt_status          ;
            o_rx_cur_pt                 <=  o_rx_cur_pt                 ;
            o_tx_wr_pt                  <=  o_tx_wr_pt                  ;
            // o_tx_ram_ful                <=  o_tx_ram_ful                ;
            r_fix_pps0_inv_l            <=  r_fix_pps0_inv_l            ;
            r_fix_pps0_inv_h            <=  r_fix_pps0_inv_h            ;
            r_fix_pps1_inv_l            <=  r_fix_pps1_inv_l            ;
            r_fix_pps1_inv_h            <=  r_fix_pps1_inv_h            ;
            r_pps2_target_time_l        <=  r_pps2_target_time_l        ;
            r_pps2_target_time_h        <=  r_pps2_target_time_h        ;
            r_pps3_target_time_l        <=  r_pps3_target_time_l        ;
            r_pps3_target_time_h        <=  r_pps3_target_time_h        ;

            o_ts_rx_cur_pt              <=  o_ts_rx_cur_pt              ;
            o_ts_tx_wr_pt               <=  o_ts_tx_wr_pt               ;
            o_ts_start_cfg              <=  o_ts_start_cfg              ;
            o_ts_rx_wnd_ctrl            <=  o_ts_rx_wnd_ctrl            ;
            o_ts_rx_wnd_lw              <=  o_ts_rx_wnd_lw              ;
            o_ts_rx_wnd_up              <=  o_ts_rx_wnd_up              ;
            o_ts_tx_wnd_ctrl            <=  o_ts_tx_wnd_ctrl            ;
            o_ts_tx_wnd_lw              <=  o_ts_tx_wnd_lw              ;
            o_ts_tx_wnd_up              <=  o_ts_tx_wnd_up              ;
        end
    end
end

//======================================= soft rst function always block =======================================//

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        o_soft_rst_en                   <=   1'b0               ;
        r_wait_rvrst                    <=   1'b0               ;
    end
    else begin
        r_wait_rvrst                    <=  i_wait_rvrst        ;

        if(i_reg_en && (|i_reg_we) && (i_reg_addr[11:0] == SOFT_RST_EN_ADDR))begin
            o_soft_rst_en               <=  (i_reg_din[0] & w_reg_we_bmask[0]) | (o_soft_rst_en & (~w_reg_we_bmask[0]))   ;
        end
        else begin
            if(r_wait_rvrst && (~i_wait_rvrst))begin// rst accomplish
                o_soft_rst_en               <=  1'b0        ;
            end
            else begin
                o_soft_rst_en               <=  o_soft_rst_en    ;
            end
        end
    end
end


//======================================= ts windows over function always block =======================================//



always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_ts_rx_wnd_over                <=   1'b0               ;
        r_stus_ts_rx_wnd_over           <=   1'b0               ;
    end
    else begin
        r_ts_rx_wnd_over                <=  i_ts_rx_wnd_over    ;

        if(i_reg_en && (|i_reg_we) && (i_reg_addr[11:0] == TS_RX_WND_OVER_ADDR))begin
            r_stus_ts_rx_wnd_over           <=  (i_reg_din[0] & w_reg_we_bmask[0]) | (r_stus_ts_rx_wnd_over & (~w_reg_we_bmask[0]))   ;
        end
        else begin
            if(i_ts_rx_wnd_over && (~r_ts_rx_wnd_over))begin//posedge trigger
                r_stus_ts_rx_wnd_over       <=  1'b1                    ;
            end
            else begin
                r_stus_ts_rx_wnd_over       <=  r_stus_ts_rx_wnd_over   ;
            end
        end
    end
end

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_ts_tx_wnd_over                <=   1'b0               ;
        r_stus_ts_tx_wnd_over           <=   1'b0               ;
    end
    else begin
        r_ts_tx_wnd_over                <=  i_ts_tx_wnd_over    ;

        if(i_reg_en && (|i_reg_we) && (i_reg_addr[11:0] == TS_TX_WND_OVER_ADDR))begin
            r_stus_ts_tx_wnd_over           <=  (i_reg_din[0] & w_reg_we_bmask[0]) | (r_stus_ts_tx_wnd_over & (~w_reg_we_bmask[0]))   ;
        end
        else begin
            if(i_ts_tx_wnd_over && (~r_ts_tx_wnd_over))begin//posedge trigger
                r_stus_ts_tx_wnd_over       <=  1'b1                    ;
            end
            else begin
                r_stus_ts_tx_wnd_over       <=  r_stus_ts_tx_wnd_over   ;
            end
        end
    end
end

//======================================= interrupt start function always block =======================================//

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        o_intr_start                    <=   1'b0               ;
    end
    else begin
        if(i_wait_rvrst)begin
            o_intr_start                    <=   1'b0               ;
        end
        else if(i_reg_en && (|i_reg_we) && (i_reg_addr[11:0] == START_CFG_ADDR))begin//picore32 re-start accomplish
            o_intr_start                    <=   1'b1               ;
        end
        else begin
            o_intr_start                    <=   o_intr_start       ;
        end
    end
end

//======================================= pkt-recv event function always block =======================================//

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_pkt_recv                      <=   1'b0               ;
    end
    else begin
        if((i_rx_wr_pt != o_rx_cur_pt) || i_rx_ram_ful)begin
            r_pkt_recv                      <=   1'b1               ;
        end
        else begin
            r_pkt_recv                      <=   1'b0               ;
        end
    end
end

//======================================= time event function always block =======================================//

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_pps0_cnt_l                    <=  16'b0               ;
        r_pps0_cnt_m                    <=  16'b0               ;
        r_pps0_cnt_h                    <=  16'b0               ;
        r_pps0_pluse                    <=   1'b0               ;
    end
    else begin
        if(r_fix_pps0_inv_h[31])begin
            if((r_pps0_cnt_l == r_fix_pps0_inv_l[15:0]) && (r_pps0_cnt_m == r_fix_pps0_inv_l[31:16]) && (r_pps0_cnt_h == r_fix_pps0_inv_h[15:0]))begin
                r_pps0_cnt_l                    <=  16'b0               ;
                r_pps0_cnt_m                    <=  16'b0               ;
                r_pps0_cnt_h                    <=  16'b0               ;
                r_pps0_pluse                    <=   1'b1               ;
            end
            else begin
                r_pps0_cnt_l                    <=  r_pps0_cnt_l + 16'h1        ;
                r_pps0_pluse                    <=   1'b0               ;
                if((&r_pps0_cnt_l))begin
                    r_pps0_cnt_m                    <=  r_pps0_cnt_m + 16'h1        ;
                end
                else begin
                    r_pps0_cnt_m                    <=  r_pps0_cnt_m                ;
                end
                if((&r_pps0_cnt_m))begin
                    r_pps0_cnt_h                    <=  r_pps0_cnt_h + 16'h1        ;
                end
                else begin
                    r_pps0_cnt_h                    <=  r_pps0_cnt_h                ;
                end
            end
        end
        else begin
            r_pps0_cnt_l                    <=  16'b0               ;
            r_pps0_cnt_m                    <=  16'b0               ;
            r_pps0_cnt_h                    <=  16'b0               ;
            r_pps0_pluse                    <=   1'b0               ;
        end
    end
end

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_pps1_cnt_l                    <=  16'b0               ;
        r_pps1_cnt_m                    <=  16'b0               ;
        r_pps1_cnt_h                    <=  16'b0               ;
        r_pps1_pluse                    <=   1'b0               ;
    end
    else begin
        if(r_fix_pps1_inv_h[31])begin
            if((r_pps1_cnt_l == r_fix_pps1_inv_l[15:0]) && (r_pps1_cnt_m == r_fix_pps1_inv_l[31:16]) && (r_pps1_cnt_h == r_fix_pps1_inv_h[15:0]))begin
                r_pps1_cnt_l                    <=  16'b0               ;
                r_pps1_cnt_m                    <=  16'b0               ;
                r_pps1_cnt_h                    <=  16'b0               ;
                r_pps1_pluse                    <=   1'b1               ;
            end
            else begin
                r_pps1_cnt_l                    <=  r_pps1_cnt_l + 16'h1        ;
                r_pps1_pluse                    <=   1'b0               ;
                if((&r_pps1_cnt_l))begin
                    r_pps1_cnt_m                    <=  r_pps1_cnt_m + 16'h1        ;
                end
                else begin
                    r_pps1_cnt_m                    <=  r_pps1_cnt_m                ;
                end
                if((&r_pps1_cnt_m))begin
                    r_pps1_cnt_h                    <=  r_pps1_cnt_h + 16'h1        ;
                end
                else begin
                    r_pps1_cnt_h                    <=  r_pps1_cnt_h                ;
                end
            end
        end
        else begin
            r_pps1_cnt_l                    <=  16'b0               ;
            r_pps1_cnt_m                    <=  16'b0               ;
            r_pps1_cnt_h                    <=  16'b0               ;
            r_pps1_pluse                    <=   1'b0               ;
        end
    end
end

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_time_status                   <=  32'b0               ;
    end
    else begin
        if(r_pps0_pluse)begin
            r_time_status[0]                <=   1'b1               ;
        end
        else if(r_reg_en && (~(|r_reg_we)) && (r_reg_addr[11:0] == TIME_STUS_ADDR))begin//read time_status register,read clear/RC
            r_time_status[0]                <=   1'b0               ;
        end
        else begin
            r_time_status[0]                <=  r_time_status[0]    ;
        end

        if(r_pps1_pluse)begin
            r_time_status[1]                <=   1'b1               ;
        end
        else if(r_reg_en && (~(|r_reg_we)) && (r_reg_addr[11:0] == TIME_STUS_ADDR))begin//read time_status register,read clear/RC
            r_time_status[1]                <=   1'b0               ;
        end
        else begin
            r_time_status[1]                <=  r_time_status[1]    ;
        end

        r_time_status[31:2]             <=  30'b0               ;
    end
end

//======================================= interrupt status function always block =======================================//

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r0_intr_stus                    <=  32'b0               ;
        // r1_intr_stus                    <=  32'b0               ;
    end
    else begin
       r0_intr_stus[31:2]               <=   30'b0               ;
       r0_intr_stus[1]                  <=  (|r_time_status)     ;
       r0_intr_stus[0]                  <=  r_pkt_recv           ;
    //    r1_intr_stus                     <=  r0_intr_stus          ;
    end
end

genvar i;
generate for(i = 0; i<=31; i = i + 1) begin:INTR_STATUS_GROUP
always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_interrupt_status[i]           <=   1'b0               ;
    end
    else begin
        if(i_reg_en && (|i_reg_we) && (i_reg_addr[11:0] == INTR_STUS_ADDR))begin//write interrupt_status register
            r_interrupt_status[i]   <= (i_reg_din[i] & w_reg_we_bmask[i]) | (r_interrupt_status  [i] & (~w_reg_we_bmask[i]));
        end
        else begin
            r_interrupt_status[i]   <=  r0_intr_stus[i] & r_interrupt_mask[i]     ;
        end
    end
end
end
endgenerate

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        o_intr_stus                 <=   1'b0               ;
    end
    else begin
        o_intr_stus                 <=  |r_interrupt_status ;
    end
end

//======================================= debug function always block =======================================//



endmodule
