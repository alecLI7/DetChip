/*========================================================================================================*\
          Filename : TIMER_MG.v
            Author : lcl7
       Description : 
         Called by : 
  Revision History : 01/07/2022 Revision 1.0  lcl7
                     mm/dd/yy
           Company : NUDT
============================================================================================================
          Comments :
          a. 
\*========================================================================================================*/

module TIMER_MG
(
    
//============================================== clk & rst ===========================================//
//clock & resets
  input     wire                i_rv_clk                        // rsic clk
 ,input     wire                i_rv_rst_n                      // rst of i_rv_clk
//========================================= Input access port  =======================================//
//from ACCESS
,input      wire    [11:0]      i_reg_addr                      //
,input      wire    [31:0]      i_reg_din                       //
,output     reg     [31:0]      o_reg_dout                      //
,input      wire                i_reg_en                        //
,input      wire    [ 3:0]      i_reg_we                        //
//========================================== control signal ========================================//
,(*mark_debug = "true" *)output     wire                o_intr_pulse                    // to ACCESS, high is time-triggered interrupt
,(*mark_debug = "true" *)input      wire                i_intr_start                    // high is valid, picore32 is ready to be interrupted
,(*mark_debug = "true" *)input      wire                i_wait_rvrst                    // from RVRST_CTRL,high is valid,wait rst

,output     wire     [47:0]     o_cur_time                      // to TS scheduler
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


reg         [47:0]          r_local_time            ;
wire        [31:0]          r_interrupt_index       ;
reg                         r_offset_en             ;
reg         [47:0]          r_offset                ;
reg         [47:0]          r_offset_cur            ;
reg                         r_offset_flag           ;
reg                         r_config_en             ;
reg         [47:0]          r_config_value          ;
reg         [31:0]          r_config_index          ;

localparam    LOCAL_TIME_L_ADDR         =   12'h000     ;
localparam    LOCAL_TIME_H_ADDR         =   12'h001     ;
localparam    INTERRUPT_INDEX_ADDR      =   12'h002     ;
localparam    OFFSET_EN_ADDR            =   12'h003     ;
localparam    OFFSET_L_ADDR             =   12'h004     ;
localparam    OFFSET_H_ADDR             =   12'h005     ;
localparam    CONFIG_EN_ADDR            =   12'h006     ;
localparam    CONFIG_VALUE_L_ADDR       =   12'h007     ;
localparam    CONFIG_VALUE_H_ADDR       =   12'h008     ;
localparam    CONFIG_INDEX_ADDR         =   12'h009     ;
localparam    CUR_TIME_L_ADDR           =   12'h00a     ;
localparam    CUR_TIME_H_ADDR           =   12'h00b     ;
// Add by LCL7. 22.06.08
localparam    OFFSET_CUR_L_ADDR         =   12'h00c     ;
localparam    OFFSET_CUR_H_ADDR         =   12'h00d     ;
localparam    TIMER_INTR_EN_ADDR        =   12'h00e     ;

localparam    TIME_TRIGGERED_TABLE_INDEX_WD  =  8        ;    // width
localparam    TIME_TRIGGERED_TABLE_DEPTH     =  256      ;    //

reg                         r_timer_intr_en         ;

reg         [31: 0]         r_intr_pulse            ;

reg         [11: 0]         r_reg_addr              ;
// reg         [31: 0]         r_reg_din               ;
reg                         r_reg_en                ;
reg         [ 3: 0]         r_reg_we                ;

wire        [31: 0]         w_reg_we_bmask          ;

reg         [47: 0]         r_cur_time              ;

reg         [47: 0]                                 r_time_interrupt_table[1:TIME_TRIGGERED_TABLE_DEPTH]    ;
reg         [TIME_TRIGGERED_TABLE_INDEX_WD-1:0]     r_time_interrupt_table_cur_index                        ;
wire        [47: 0]                                 r_time_interrupt_table_cur_value                        ;

reg         [47: 0]         r_temp_local_time       ;
reg         [47: 0]         r_temp_cur_time         ;
reg         [47: 0]         r_period                ;

//=========================================== combination logic block ===========================================//

assign  w_reg_we_bmask[ 7: 0]   =   i_reg_we[0] ?   8'hFF   :   8'h0    ;
assign  w_reg_we_bmask[15: 8]   =   i_reg_we[1] ?   8'hFF   :   8'h0    ;
assign  w_reg_we_bmask[23:16]   =   i_reg_we[2] ?   8'hFF   :   8'h0    ;
assign  w_reg_we_bmask[31:24]   =   i_reg_we[3] ?   8'hFF   :   8'h0    ;

assign  o_cur_time              =   r_cur_time                          ;
assign  o_intr_pulse            =   r_intr_pulse                        ;

assign r_time_interrupt_table_cur_value = r_time_interrupt_table[r_time_interrupt_table_cur_index]  ;
assign r_interrupt_index        = r_time_interrupt_table_cur_index - 1;
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
        r_temp_local_time           <=  48'b0               ;
        r_temp_cur_time             <=  48'b0               ;
    end
    else begin
        if(r_reg_en && (~(|r_reg_we)))begin     // read operation
            case(r_reg_addr[11:0])
                LOCAL_TIME_L_ADDR    : begin 
                                             o_reg_dout <= r_local_time[31:0]                   ; 
                                             r_temp_local_time <= r_local_time                  ; end
                LOCAL_TIME_H_ADDR    : begin o_reg_dout <= {16'b0,  r_temp_local_time[47:32]}   ; end
                INTERRUPT_INDEX_ADDR : begin o_reg_dout <= r_interrupt_index                    ; end
                CUR_TIME_L_ADDR      : begin 
                                             o_reg_dout <= r_cur_time[31:0]                   ; 
                                             r_temp_cur_time <= r_cur_time                    ; end
                CUR_TIME_H_ADDR      : begin o_reg_dout <= {16'b0,  r_temp_cur_time[47:32]}   ; end
            endcase
        end
        else begin
            o_reg_dout  <=  o_reg_dout  ;
        end
    end
end

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_offset_flag    <=  1'b0   ;
        r_offset         <= 48'b0   ;
        r_offset_cur     <= 48'b0   ;
        r_config_value   <= 48'b0   ;
        r_config_index   <= 32'b0   ;
        r_timer_intr_en  <=  1'b0   ;
    end
    else begin
        if(i_reg_en && (|i_reg_we))begin        // write operation
            case(i_reg_addr[11:0])
                OFFSET_L_ADDR             : begin r_offset          [31: 0]         <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_offset[31: 0]          & (~w_reg_we_bmask[31:0])); end
                OFFSET_H_ADDR             : begin
                                                  r_offset          [47:32]         <= (i_reg_din[15:0] & w_reg_we_bmask[15:0]) | (r_offset[47:32]          & (~w_reg_we_bmask[15:0]));
                                                  r_offset_flag                     <= (i_reg_din[16]   & w_reg_we_bmask[16])   | (r_offset_flag            & (~w_reg_we_bmask[16])  ); 
                                            end
                OFFSET_CUR_L_ADDR         : begin r_offset_cur      [31: 0]         <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_offset_cur[31: 0]      & (~w_reg_we_bmask[31:0])); end
                OFFSET_CUR_H_ADDR         : begin
                                                  r_offset_cur      [47:32]         <= (i_reg_din[15:0] & w_reg_we_bmask[15:0]) | (r_offset_cur[47:32]      & (~w_reg_we_bmask[15:0]));
                                            end
                CONFIG_VALUE_L_ADDR       : begin r_config_value    [31: 0]         <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_config_value[31: 0]    & (~w_reg_we_bmask[31:0])); end
                CONFIG_VALUE_H_ADDR       : begin r_config_value    [47:32]         <= (i_reg_din[15:0] & w_reg_we_bmask[15:0]) | (r_config_value[47:32]    & (~w_reg_we_bmask[15:0])); end
                CONFIG_INDEX_ADDR         : begin r_config_index    [31: 0]         <= (i_reg_din[31:0] & w_reg_we_bmask[31:0]) | (r_config_index[31: 0]    & (~w_reg_we_bmask[31:0])); end

                TIMER_INTR_EN_ADDR        : begin r_timer_intr_en                   <= (i_reg_din[0] & w_reg_we_bmask[0])       | (r_timer_intr_en          & (~w_reg_we_bmask[0])   ); end

                default:begin end
            endcase
        end
        else begin
            r_offset_flag    <= r_offset_flag   ;
            r_offset         <= r_offset        ;
            r_offset_cur     <= r_offset_cur    ;
            r_config_value   <= r_config_value  ;
            r_config_index   <= r_config_index  ;
            r_timer_intr_en  <= r_timer_intr_en ;
        end
    end
end

//======================================= time-triggered interrupt table config function always block =================//

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_config_en      <= 1'b0            ;
        r_period         <= {47'b1, 7'b0}   ;
        r_time_interrupt_table[1]           <=   48'b0              ;
    end
    else begin
        if (i_reg_en && (|i_reg_we) && (i_reg_addr[11:0] == CONFIG_EN_ADDR)) begin  // config value (low and high) and index has been set
            r_config_en                                                         <= 1'b1             ;
            if (&r_config_index)  begin r_period                                <= r_config_value   ; end   // config index is 32'hFFFF_FFFF, value is period
            else                  begin r_time_interrupt_table[r_config_index]  <= r_config_value   ; end
        end
        else begin
            r_config_en                             <= 1'b0             ;           // hardware automatically disable (only when i_reg_addr has been changed, attention!!)
        end
    end
end

//======================================= local time run / correction with offset function always block =================//

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_offset_en      <=      1'b0       ;
    end
    else begin
        if (i_reg_en && (|i_reg_we) && (i_reg_addr[11:0] == OFFSET_EN_ADDR)) begin  
        // offset value (low and high) has been set
            r_offset_en  <=     (i_reg_din[0] & w_reg_we_bmask[0]) | (r_offset_en          & (~w_reg_we_bmask[0]));
        end
        else begin
        // hardware automatically disable (only when i_reg_addr has been changed)
            r_offset_en  <= 1'b0            ;
        end
    end
end

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_local_time     <=     48'b0       ;
        r_cur_time       <=     48'b0       ;
    end
    else begin
        if ((~r_offset_en) && i_reg_en && (|i_reg_we) && (i_reg_addr[11:0] == OFFSET_EN_ADDR)) begin
        // offset value (low and high) has been set, posedge trigger
        // 22.06.08 -> follow OpenTSN V2.0 global_time_sync.v
            
            if (r_offset_flag == 1'b1) begin    // offset flag is 1, negative (-)
                if (r_local_time[ 6: 0] >= r_offset[ 6: 0]) begin
                    if ((r_local_time[ 6: 0] - r_offset[ 6: 0]) == 7'd124) begin
                        r_local_time[47: 7]            <= r_local_time[47: 7] - r_offset[47: 7] + 41'b1;
                        r_local_time[ 6: 0]            <= 7'b0;
                    end
                    else begin
                        r_local_time[47: 7]            <= r_local_time[47: 7] - r_offset[47: 7];
                        r_local_time[ 6: 0]            <= r_local_time[ 6: 0] - r_offset[ 6: 0] + 7'b1;
                    end
                end
                else begin
                    if (({1'b0, r_local_time[ 6: 0]} + 8'd125 - {1'b0, r_offset[ 6: 0]}) == 8'd124) begin
                        r_local_time[47: 7]            <= r_local_time[47: 7] - r_offset[47: 7];
                        r_local_time[ 6: 0]            <= 7'b0;
                    end
                    else begin
                        r_local_time[47: 7]            <= r_local_time[47: 7] - r_offset[47: 7] - 41'b1;
                        r_local_time[ 6: 0]            <= r_local_time[ 6: 0] + 7'd125 - r_offset[ 6: 0] + 7'b1;
                    end
                end
                
            end
            else begin                  // offset flag is 0, positive (+)
                if (({1'b0, r_local_time[ 6: 0]} + {1'b0, r_offset[ 6: 0]}) >= 8'd124) begin
                    r_local_time[47: 7]            <= r_local_time[47: 7] + r_offset[47: 7] + 41'b1;
                    r_local_time[ 6: 0]            <= r_local_time[ 6: 0] + r_offset[ 6: 0] - 7'd124;
                end
                else begin
                    r_local_time[47: 7]            <= r_local_time[47: 7] + r_offset[47: 7];
                    r_local_time[ 6: 0]            <= r_local_time[ 6: 0] + r_offset[ 6: 0] + 7'b1;
                end
            end

            if (({1'b0, r_cur_time[ 6: 0]} + {1'b0, r_offset_cur[ 6: 0]}) >= 8'd124) begin
                if ((r_cur_time[47: 7] + r_offset_cur[47: 7] + 41'b1) >= r_period[47: 7]) begin
                    r_cur_time[47: 7]              <= r_cur_time[47: 7] + r_offset_cur[47: 7] + 41'b1 - r_period[47: 7];
                    r_cur_time[ 6: 0]              <= r_cur_time[ 6: 0] + r_offset_cur[ 6: 0] - 7'd124;
                end
                else begin
                    r_cur_time[47: 7]              <= r_cur_time[47: 7] + r_offset_cur[47: 7] + 41'b1;
                    r_cur_time[ 6: 0]              <= r_cur_time[ 6: 0] + r_offset_cur[ 6: 0] - 7'd124;
                end
            end
            else begin
                if ((r_cur_time[47: 7] + r_offset_cur[47: 7]) >= r_period[47: 7]) begin
                    r_cur_time[47: 7]              <= r_cur_time[47: 7] + r_offset_cur[47: 7] - r_period[47: 7];
                    r_cur_time[ 6: 0]              <= r_cur_time[ 6: 0] + r_offset_cur[ 6: 0] + 7'b1;
                end
                else begin
                    r_cur_time[47: 7]              <= r_cur_time[47: 7] + r_offset_cur[47: 7];
                    r_cur_time[ 6: 0]              <= r_cur_time[ 6: 0] + r_offset_cur[ 6: 0] + 7'b1;
                end
            end

        end
        else begin
        // normally run

            if (i_intr_start) begin
                if (r_local_time[ 6: 0] == 7'd124) begin     // 125 cycles, each cycles should be 8ns (attention!!)
                    r_local_time[ 6: 0]         <= 7'b0                           ;
                    r_local_time[47: 7]         <= r_local_time[47: 7] + 41'b1    ;
                end
                else begin
                    r_local_time[ 6: 0]         <= r_local_time[ 6: 0] + 7'b1     ;
                end

                if (r_cur_time[ 6: 0] == 7'd124) begin
                    // assume minimum unit of period is microseconds (us)
                    if ((r_cur_time[47: 7] == r_period[47: 7] - 41'b1) && (r_cur_time[6:0] == 7'd124))
                        begin r_cur_time              <= 48'b0 ;                                                      end
                    else
                        begin r_cur_time[ 6: 0]       <= 7'b0  ;  r_cur_time[47: 7]  <= r_cur_time[47: 7] + 41'b1 ;   end
                end
                else begin
                    r_cur_time[ 6: 0]           <= r_cur_time[ 6: 0]   + 7'b1     ;
                end
            end
        end
    end
end

//======================================= interrupt trigger function always block =======================================//

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_intr_pulse                        <=   1'b0               ;
        r_time_interrupt_table_cur_index    <=   1                  ;
    end
    else begin
        if (i_wait_rvrst | ~i_intr_start | ~r_timer_intr_en) begin
            r_intr_pulse                        <=   1'b0                                   ;
        end
        else if (~(|r_cur_time)) begin                                                                                // one period finish
            r_time_interrupt_table_cur_index    <=   1                                      ;
        end
        // assume minimum unit of time-triggered table value is microseconds (us)
        else if ((r_cur_time[47: 7] == r_time_interrupt_table_cur_value[47: 7] - 41'b1) && (r_cur_time[6:0] == 7'd124) && (|r_time_interrupt_table_cur_value)) begin       // 48'b0 is invalid value
            r_intr_pulse                        <=   1'b1                                   ;
            r_time_interrupt_table_cur_index    <=   r_time_interrupt_table_cur_index + 1   ;                         // attention!! goto next triggered time to interrupt
        end
        else begin
            r_intr_pulse                        <=   1'b0                                   ;
            r_time_interrupt_table_cur_index    <=   r_time_interrupt_table_cur_index       ;
        end
    end
end

//======================================= debug function always block =======================================//



endmodule
