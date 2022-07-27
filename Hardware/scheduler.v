/*========================================================================================================*\
          Filename : scheduler.v
            Author : zc
       Description : 
	     Called by : 
  Revision History : 01/14/2022 Revision 1.0  zc
                     mm/dd/yy
           Company : NUDT
============================================================================================================
          Comments :
          a. 
\*========================================================================================================*/

module scheduler
(
    
//============================================== clk & rst ===========================================//
//clock & resets
 input     wire                 i_rv_clk                        //rsic clk
,input     wire                 i_rv_rst_n                      //rst of i_rv_clk

,input	    wire			    i_clk_rx					    //GMII receive reference clock
,input	    wire			    i_rst_clk_rx_n				    //active low reset synch to clk_rx_i

//============================================== access port  ======================================//
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
//================================================== PKT  ===========================================//

,input	    wire	[35:0]	    i_pkt_data					    //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,input	    wire			    i_pkt_data_en				    //data enable
,input	    wire	[15:0]	    i_pkt_val					    //frame valid & length
,input	    wire			    i_pkt_val_en				    //valid enable
,output	    wire    [9:0]       o_pkt_data_usedw			    //fifo allmostfull

,output	    reg	    [35:0]	    o_pkt_data					    //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,output	    reg			        o_pkt_data_en				    //data enable
,output	    reg	    [15:0]	    o_pkt_val					    //frame valid & length
,output	    reg			        o_pkt_val_en				    //valid enable
,input	    wire	    	    i_pkt_data_alf			        //fifo allmostfull

//========================================== control signal ========================================//

,input	    wire    [ 3:0]      i_start_cfg                     //the start reg
,output     reg     [ 3:0]      o_rx_wr_pt                      //the write pointer of RX_RAM
,input	    wire    [ 3:0]      i_rx_cur_pt                     //the current pointer which is dealing of RX_RAM
,output     reg     [ 3:0]      o_rx_rd_pt                      //the read pointer of RX_RAM
,input	    wire    [ 3:0]      i_tx_wr_pt                      //the write pointer of TX_RAM
,output     reg     [ 3:0]      o_tx_rd_pt                      //the read pointer of TX_RAM
,output     wire                o_rx_ram_ful                    //the full flag of RX_RAM
,output	    wire	    	    o_tx_ram_ful			        //the full flag of TX_RAM

//=========================================== debug signal ===========================================//
,output     reg     [ 1:0]      e1a                             //e1a
,output     reg     [ 1:0]      e2a                             //e2a

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

reg	        [35:0]	        r_rx_data				    ;   //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
reg			                r_rx_data_en			    ;   //data enable
reg	        [15:0]	        r_rx_val				    ;   //frame valid & length
reg			                r_rx_val_en			        ;   //valid enable

reg						    r_pkt_data_rd               ;   //rden
wire		[9:0]			w_pkt_data_usedw            ;   //usedwords
wire		[35:0]			w_pkt_data_q                ;   //read data out
wire						w_pkt_data_empty            ;   //empty

reg						    r_pkt_info_rd               ;   //rden
wire		[9:0]			w_pkt_info_usedw            ;   //usedwords
wire		[15:0]			w_pkt_info_q                ;   //read data out
wire						w_pkt_info_empty            ;   //empty

reg			                r_rx_ram_trans              ;   //transmit the pkt from rx_ram
reg			                r_rx_ram_wr_rd_poll         ;   //1:the next operation should be write ram;0:read

reg                         r_rx_ram_wr_rdy             ;   //1:all is ready to write rx_ram
reg                         r_rx_ram_rd_rdy             ;   //1:all is ready to read rx_ram

reg			                r_rx_ram_wr_pul             ;   //write a pkt to rx_ram
reg			                r_rx_ram_rd_pul             ;   //read a pkt from rx_ram
reg	        [3:0]	        r_rx_ram_block_ocp          ;   //rx_ram block is occupyed

reg	        [11:0]	        r_rx_ram_pkt_len            ;   //the length of pkt which in the rx_ram
reg	            	        r_rx_ram_pkt_sop            ;   //the sop of pkt which in the rx_ram

reg	        [35:0]	        r_tx_data				    ;   //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
reg			                r_tx_data_en			    ;   //data enable
reg	        [15:0]	        r_tx_val				    ;   //frame valid & length
reg			                r_tx_val_en			        ;   //valid enable

reg			                r_tx_ram_trans              ;   //transmit the pkt from tx_ram

reg                         r_tx_ram_rd_rdy             ;   //1:all is ready to read tx_ram

reg	        [3:0]	        r_tx_wr_pt                  ;   //buffer of tx_ram block point
reg			                r_tx_ram_wr_pul             ;   //write a pkt to tx_ram
reg			                r_tx_ram_rd_pul             ;   //read a pkt from tx_ram
reg	        [3:0]	        r_tx_ram_block_ocp          ;   //tx_ram block is occupyed

reg	        [11:0]	        r_tx_ram_pkt_len            ;   //the length of pkt which in the tx_ram
reg	            	        r_tx_ram_pkt_sop            ;   //the sop of pkt which in the tx_ram

reg	        [35:0]	        r_pkt_data_buf              ;   //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
reg	        [1:0]	        r_pkt_data_offset           ;   //the offset of frist 4B

//FSM declarations
reg         [8:0]           r_rx_sch_cs                 ;   //


localparam	IDLE_RX_SCH             =	9'h001    ,
            RDES_WT0_RX_SCH         =	9'h002    ,
            RDES_WT1_RX_SCH         =	9'h004    ,
            RDES_JUG_RX_SCH         =	9'h008    ,
            RDA_WT0_RX_SCH          =	9'h010    ,
            RDA_WT1_RX_SCH          =	9'h020    ,
            RD_RX_SCH               =	9'h040    ,
            WR_RX_SCH               =	9'h080    ,
            DISC_RX_SCH             =	9'h100    ;

reg         [6:0]           r_tx_sch_cs                 ;   //

localparam	IDLE_TX_SCH             =	7'h01    ,
            RDES_WT0_TX_SCH         =	7'h02    ,
            RDES_WT1_TX_SCH         =	7'h04    ,
            RDES_JUG_TX_SCH         =	7'h08    ,
            RDA_WT0_TX_SCH          =	7'h10    ,
            RDA_WT1_TX_SCH          =	7'h20    ,
            RD_TX_SCH               =	7'h40    ;

reg         [3:0]           r_mux_sch_cs                 ;
localparam	IDLE_MUX_SCH            =	4'h1    ,
            TRX_MUX_SCH             =	4'h2    ,
            TTX_MUX_SCH             =	4'h4    ,
            EOP_MUX_SCH             =	4'h8    ;

//=========================================== combination logic block ===========================================//

assign  o_pkt_data_usedw        =   w_pkt_data_usedw                    ;
assign  o_rx_ram_ful            =   r_rx_ram_block_ocp[3]               ;

always @* begin
	if( (~o_rx_ram_ful) && (~w_pkt_info_empty) && (i_start_cfg[0]) && (w_pkt_info_q[15]))begin //
		r_rx_ram_wr_rdy =   1'b1        ;
	end
	else begin
		r_rx_ram_wr_rdy =   1'b0        ;
	end
end

always @* begin
	if( (r_tx_ram_trans) || (i_pkt_data_alf) || (~i_start_cfg[1]) || (&(o_rx_rd_pt ^~ i_rx_cur_pt)) )begin //
		r_rx_ram_rd_rdy =   1'b0        ;
	end
	else begin
		r_rx_ram_rd_rdy =   1'b1        ;
	end
end

assign  o_tx_ram_ful            =   r_tx_ram_block_ocp[2]               ;

always @* begin
	if( (r_rx_ram_trans) || (i_pkt_data_alf) || (~i_start_cfg[1]) || (&(o_tx_rd_pt ^~ i_tx_wr_pt)) )begin //
		r_tx_ram_rd_rdy =   1'b0        ;
	end
	else begin
		r_tx_ram_rd_rdy =   1'b1        ;
	end
end

//=========================================== rx_ram pkt counter function always block ==========================================//
always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_rx_ram_block_ocp          <=    4'b0              ;
    end
    else begin
        r_rx_ram_block_ocp          <=  r_rx_ram_block_ocp + r_rx_ram_wr_pul - r_rx_ram_rd_pul  ;
    end
end

//=========================================== tx_ram pkt counter function always block ==========================================//

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_tx_ram_wr_pul             <=    1'b0              ;
        r_tx_wr_pt                  <=    4'b0              ;
    end
    else begin
        r_tx_wr_pt                  <=  i_tx_wr_pt          ;
        if(r_tx_wr_pt != i_tx_wr_pt)begin
            r_tx_ram_wr_pul             <=    1'b1              ;
        end
        else begin
            r_tx_ram_wr_pul             <=    1'b0              ;
        end
    end
end

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        r_tx_ram_block_ocp          <=    4'b0              ;
    end
    else begin
        r_tx_ram_block_ocp          <=  r_tx_ram_block_ocp + r_tx_ram_wr_pul - r_tx_ram_rd_pul  ;
    end
end

//=========================================== rx_ram ctrl function always block ==========================================//
always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        o_rx_mem_addr               <=   12'b0              ;
        o_rx_mem_din                <=   32'b0              ;
        o_rx_mem_en                 <=    1'b0              ;
        o_rx_mem_we                 <=    4'b0              ;

        r_rx_data                   <=   36'b0              ;
        r_rx_data_en                <=    1'b0              ;
        r_rx_val                    <=   16'b0              ;
        r_rx_val_en                 <=    1'b0              ;

        o_rx_wr_pt                  <=    4'b0              ;
        o_rx_rd_pt                  <=    4'b0              ;

        r_pkt_data_rd               <=    1'b0              ;
        r_pkt_info_rd               <=    1'b0              ;

        r_rx_ram_trans              <=    1'b0              ;
        r_rx_ram_wr_pul             <=    1'b0              ;
        r_rx_ram_rd_pul             <=    1'b0              ;
        r_rx_ram_wr_rd_poll         <=    1'b0              ;

        r_rx_ram_pkt_len            <=   12'b0              ;
        r_rx_ram_pkt_sop            <=    1'b0              ;

        r_rx_sch_cs                 <=  IDLE_RX_SCH         ;
    end
    else begin 
        case(r_rx_sch_cs)
            IDLE_RX_SCH:begin
                r_rx_data                   <=   36'b0              ;
                r_rx_data_en                <=    1'b0              ;
                r_rx_val                    <=   16'b0              ;
                r_rx_val_en                 <=    1'b0              ;

                o_rx_wr_pt                  <=  o_rx_wr_pt          ;
                o_rx_rd_pt                  <=  o_rx_rd_pt          ;

                r_rx_ram_pkt_len            <=   12'b0              ;
                r_rx_ram_pkt_sop            <=    1'b0              ;

                case({r_rx_ram_wr_rdy,r_rx_ram_rd_rdy})
                    2'b00:begin
                        if((~w_pkt_info_empty) && (~w_pkt_info_q[15]))begin
                            o_rx_mem_addr               <=   12'b0                  ;
                            o_rx_mem_din                <=   32'b0                  ;
                            o_rx_mem_en                 <=    1'b0                  ;
                            o_rx_mem_we                 <=    4'b0                  ;

                            r_pkt_data_rd               <=    1'b1                  ;
                            r_pkt_info_rd               <=    1'b1                  ;

                            r_rx_ram_trans              <=    1'b0                  ;
                            r_rx_ram_wr_pul             <=    1'b0                  ;
                            r_rx_ram_rd_pul             <=    1'b0                  ;
                            r_rx_ram_wr_rd_poll         <=    1'b0                  ;
                            r_rx_sch_cs                 <=  DISC_RX_SCH             ;
                        end
                        else begin
                            o_rx_mem_addr               <=   12'b0                  ;
                            o_rx_mem_din                <=   32'b0                  ;
                            o_rx_mem_en                 <=    1'b0                  ;
                            o_rx_mem_we                 <=    4'b0                  ;

                            r_pkt_data_rd               <=    1'b0                  ;
                            r_pkt_info_rd               <=    1'b0                  ;

                            r_rx_ram_trans              <=    1'b0                  ;
                            r_rx_ram_wr_pul             <=    1'b0                  ;
                            r_rx_ram_rd_pul             <=    1'b0                  ;
                            r_rx_ram_wr_rd_poll         <=  r_rx_ram_wr_rd_poll     ;
                            r_rx_sch_cs                 <=  IDLE_RX_SCH             ;
                        end
                    end
                    2'b01:begin
                        o_rx_mem_addr[11:0]         <=  {o_rx_rd_pt[2:0],9'h0}  ;
                        o_rx_mem_din                <=   32'b0                  ;
                        o_rx_mem_en                 <=    1'b1                  ;
                        o_rx_mem_we                 <=    4'b0                  ;

                        r_pkt_data_rd               <=    1'b0                  ;
                        r_pkt_info_rd               <=    1'b0                  ;

                        r_rx_ram_trans              <=    1'b1                  ;
                        r_rx_ram_wr_pul             <=    1'b0                  ;
                        r_rx_ram_rd_pul             <=    1'b1                  ;
                        r_rx_ram_wr_rd_poll         <=    1'b1                  ;
                        r_rx_sch_cs                 <=  RDES_WT0_RX_SCH         ;
                    end
                    2'b10:begin
                        o_rx_mem_addr[11:0]         <=  {o_rx_wr_pt[2:0],9'h0}                          ;
                        o_rx_mem_din                <=  {4'b0,4'b0,w_pkt_info_q[11:0],10'h20,2'b0}      ;
                        o_rx_mem_en                 <=    1'b1              ;
                        o_rx_mem_we                 <=    4'hf              ;

                        r_pkt_data_rd               <=    1'b1              ;
                        r_pkt_info_rd               <=    1'b1              ;

                        r_rx_ram_trans              <=    1'b0              ;
                        r_rx_ram_wr_pul             <=    1'b1              ;
                        r_rx_ram_rd_pul             <=    1'b0              ;
                        r_rx_ram_wr_rd_poll         <=    1'b0              ;
                        r_rx_sch_cs                 <=  WR_RX_SCH           ;
                    end
                    default:begin
                        if(r_rx_ram_wr_rd_poll)begin
                            o_rx_mem_addr[11:0]         <=  {o_rx_wr_pt[2:0],9'h0}                          ;
                            o_rx_mem_din                <=  {4'b0,4'b0,w_pkt_info_q[11:0],10'h20,2'b0}      ;
                            o_rx_mem_en                 <=    1'b1              ;
                            o_rx_mem_we                 <=    4'hf              ;

                            r_pkt_data_rd               <=    1'b1              ;
                            r_pkt_info_rd               <=    1'b1              ;

                            r_rx_ram_trans              <=    1'b0              ;
                            r_rx_ram_wr_pul             <=    1'b1              ;
                            r_rx_ram_rd_pul             <=    1'b0              ;
                            r_rx_ram_wr_rd_poll         <=    1'b0              ;
                            r_rx_sch_cs                 <=  WR_RX_SCH           ;
                        end
                        else begin
                            o_rx_mem_addr[11:0]         <=  {o_rx_rd_pt[2:0],9'h0}  ;
                            o_rx_mem_din                <=   32'b0                  ;
                            o_rx_mem_en                 <=    1'b1                  ;
                            o_rx_mem_we                 <=    4'b0                  ;

                            r_pkt_data_rd               <=    1'b0                  ;
                            r_pkt_info_rd               <=    1'b0                  ;

                            r_rx_ram_trans              <=    1'b1                  ;
                            r_rx_ram_wr_pul             <=    1'b0                  ;
                            r_rx_ram_rd_pul             <=    1'b1                  ;
                            r_rx_ram_wr_rd_poll         <=    1'b1                  ;
                            r_rx_sch_cs                 <=  RDES_WT0_RX_SCH         ;
                        end
                    end
                endcase
            end
            RDES_WT0_RX_SCH:begin
                r_rx_ram_rd_pul             <=    1'b0                  ;
                o_rx_mem_en                 <=    1'b0                  ;
                r_rx_sch_cs                 <=  RDES_WT1_RX_SCH         ;
            end
            RDES_WT1_RX_SCH:begin
                r_rx_sch_cs                 <=  RDES_JUG_RX_SCH         ;
            end
            RDES_JUG_RX_SCH:begin
                if(i_rx_mem_dout[27:24] == 4'h1)begin
                    r_rx_data                   <=   36'b0                  ;
                    r_rx_data_en                <=    1'b0                  ;
                    r_rx_val                    <=   16'b0                  ;
                    r_rx_val_en                 <=    1'b0                  ;

                    o_rx_mem_addr               <=   12'b0                  ;
                    o_rx_mem_din                <=   32'b0                  ;
                    o_rx_mem_en                 <=    1'b0                  ;
                    o_rx_mem_we                 <=    4'b0                  ;
                    
                    o_rx_rd_pt                  <=  o_rx_rd_pt + 4'h1       ;
                    r_rx_ram_trans              <=    1'b0                  ;

                    r_rx_ram_pkt_len            <=   12'b0                  ;
                    r_rx_ram_pkt_sop            <=    1'b0                  ;

                    r_rx_sch_cs                 <=  IDLE_RX_SCH             ;
                end
                else begin
                    r_rx_data                   <=   36'b0                  ;
                    r_rx_data_en                <=    1'b0                  ;
                    r_rx_val                    <=  {2'b10,i_rx_mem_dout[1:0],i_rx_mem_dout[23:12]} ;
                    r_rx_val_en                 <=    1'b0                  ;

                    o_rx_mem_addr               <=   {o_rx_rd_pt[2:0],9'h0} + i_rx_mem_dout[11:2]   ;
                    o_rx_mem_din                <=   32'b0                  ;
                    o_rx_mem_en                 <=    1'b1                  ;
                    o_rx_mem_we                 <=    4'b0                  ;

                    o_rx_rd_pt                  <=  o_rx_rd_pt              ;
                    r_rx_ram_trans              <=    1'b1                  ;

                    r_rx_ram_pkt_len            <=  i_rx_mem_dout[23:12] + i_rx_mem_dout[1:0]       ;
                    r_rx_ram_pkt_sop            <=    1'b1                  ;

                    r_rx_sch_cs                 <=  RDA_WT0_RX_SCH          ;
                end
            end
            RDA_WT0_RX_SCH:begin
                o_rx_mem_addr               <=   o_rx_mem_addr + 12'h1  ;
                o_rx_mem_din                <=   32'b0                  ;
                o_rx_mem_en                 <=    1'b1                  ;
                o_rx_mem_we                 <=    4'b0                  ;

                r_rx_sch_cs                 <=  RDA_WT1_RX_SCH          ;
            end
            RDA_WT1_RX_SCH:begin
                o_rx_mem_addr               <=   o_rx_mem_addr + 12'h1  ;
                o_rx_mem_din                <=   32'b0                  ;
                o_rx_mem_en                 <=    1'b1                  ;
                o_rx_mem_we                 <=    4'b0                  ;

                r_rx_sch_cs                 <=  RD_RX_SCH               ;
            end
            RD_RX_SCH:begin
                o_rx_mem_addr               <=   o_rx_mem_addr + 12'h1  ;
                o_rx_mem_din                <=   32'b0                  ;
                o_rx_mem_en                 <=    1'b1                  ;
                o_rx_mem_we                 <=    4'b0                  ;

                r_rx_ram_pkt_sop            <=    1'b0                  ;
                r_rx_ram_pkt_len            <=  r_rx_ram_pkt_len - 12'h4    ;

                r_rx_data[35]               <=  r_rx_ram_pkt_sop        ;

                if(r_rx_ram_pkt_len <= 12'h4)begin
                    r_rx_data[34]               <=    1'b1                      ;
                    r_rx_data[33:32]            <=  r_rx_ram_pkt_len[1:0] - 2'b1;//???????????????????????????
                    o_rx_rd_pt                  <=  o_rx_rd_pt + 4'h1       ;
                    r_rx_sch_cs                 <=  IDLE_RX_SCH             ;
                end
                else begin
                    r_rx_data[34]               <=    1'b0                  ;
                    if(r_rx_ram_pkt_sop)begin
                        r_rx_data[33:32]            <=  2'h3 - r_rx_val[13:12]  ;
                    end
                    else begin
                        r_rx_data[33:32]            <= 2'b11                    ;
                    end
                    o_rx_rd_pt                  <=  o_rx_rd_pt              ;
                    r_rx_sch_cs                 <=  RD_RX_SCH               ;
                end
                if(i_start_cfg[2])begin//big_endian
                    r_rx_data[31:0]             <=   i_rx_mem_dout[31:0]                ;
                end
                else begin
                    r_rx_data[31:0]             <=	{i_rx_mem_dout[7:0],i_rx_mem_dout[15:8],i_rx_mem_dout[23:16],i_rx_mem_dout[31:24]};
                end
                r_rx_data_en                <=    1'b1                  ;
                r_rx_val                    <=  r_rx_val                ;
                r_rx_val_en                 <=  r_rx_ram_pkt_sop        ;
            end
            WR_RX_SCH:begin
                r_pkt_info_rd               <=    1'b0                  ;
                r_rx_ram_wr_pul             <=    1'b0                  ;
                if(w_pkt_data_q[35])begin
                    o_rx_mem_addr[11:0]         <=  {o_rx_wr_pt[2:0],9'h20}                          ;
                end
                else begin
                    o_rx_mem_addr[11:0]         <=  o_rx_mem_addr[11:0] + 12'h1                     ;
                end
                if(i_start_cfg[2])begin//big_endian
                    o_rx_mem_din                <=  w_pkt_data_q[31:0]                              ;
                end
                else begin
                    o_rx_mem_din                <=	{w_pkt_data_q[7:0],w_pkt_data_q[15:8],w_pkt_data_q[23:16],w_pkt_data_q[31:24]};
                end
                o_rx_mem_en                 <=    1'b1              ;
                o_rx_mem_we                 <=    4'hf              ;

                if(w_pkt_data_q[34])begin
                    r_pkt_data_rd               <=    1'b0                  ;
                    o_rx_wr_pt                  <=  o_rx_wr_pt + 4'b1       ;
                    r_rx_sch_cs                 <=  IDLE_RX_SCH             ;
                end
                else begin
                    r_pkt_data_rd               <=    1'b1                  ;
                    o_rx_wr_pt                  <=  o_rx_wr_pt              ;
                    r_rx_sch_cs                 <=  WR_RX_SCH               ;
                end
            end
            DISC_RX_SCH:begin
                r_pkt_info_rd               <=    1'b0              ;
                if(w_pkt_data_q[34])begin
                    r_pkt_data_rd               <=    1'b0              ;
                    r_rx_sch_cs                 <=  IDLE_RX_SCH         ;
                end
                else begin
                    r_pkt_data_rd               <=    1'b1              ;
                    r_rx_sch_cs                 <=  DISC_RX_SCH         ;
                end
            end
            default:begin
                r_rx_sch_cs                 <=  IDLE_RX_SCH         ;
            end
        endcase
    end
end


//=========================================== tx_ram ctrl function always block ==========================================//
always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        o_tx_mem_addr               <=   11'b0              ;
        o_tx_mem_din                <=   32'b0              ;
        o_tx_mem_en                 <=    1'b0              ;
        o_tx_mem_we                 <=    4'b0              ;

        r_tx_data                   <=   36'b0              ;
        r_tx_data_en                <=    1'b0              ;
        r_tx_val                    <=   16'b0              ;
        r_tx_val_en                 <=    1'b0              ;

        r_tx_ram_trans              <=    1'b0              ;
        r_tx_ram_rd_pul             <=    1'b0              ;
        o_tx_rd_pt                  <=    4'b0              ;

        r_tx_ram_pkt_len            <=   12'b0              ;
        r_tx_ram_pkt_sop            <=    1'b0              ;

        r_tx_sch_cs                 <=  IDLE_TX_SCH         ;
    end
    else begin
        case(r_tx_sch_cs)
            IDLE_TX_SCH:begin
                r_tx_data                   <=   36'b0              ;
                r_tx_data_en                <=    1'b0              ;
                r_tx_val                    <=   16'b0              ;
                r_tx_val_en                 <=    1'b0              ;

                r_tx_ram_rd_pul             <=    1'b0              ;
                o_tx_rd_pt                  <=  o_tx_rd_pt          ;

                r_tx_ram_pkt_len            <=   12'b0              ;
                r_tx_ram_pkt_sop            <=    1'b0              ;
                
                if(r_tx_ram_rd_rdy)begin
                    o_tx_mem_addr               <=   {o_tx_rd_pt[1:0],9'b0}     ;
                    o_tx_mem_din                <=   32'b0              ;
                    o_tx_mem_en                 <=    1'b1              ;
                    o_tx_mem_we                 <=    4'b0              ;

                    r_tx_ram_trans              <=    1'b1              ;
                    r_tx_sch_cs                 <=  RDES_WT0_TX_SCH     ;
                end
                else begin
                    o_tx_mem_addr               <=   11'b0              ;
                    o_tx_mem_din                <=   32'b0              ;
                    o_tx_mem_en                 <=    1'b0              ;
                    o_tx_mem_we                 <=    4'b0              ;

                    r_tx_ram_trans              <=    1'b0              ;
                    r_tx_sch_cs                 <=  IDLE_TX_SCH         ;
                end
            end
            RDES_WT0_TX_SCH:begin
                o_tx_mem_addr               <=   11'b0              ;
                o_tx_mem_din                <=   32'b0              ;
                o_tx_mem_en                 <=    1'b0              ;
                o_tx_mem_we                 <=    4'b0              ;

                if(r_rx_ram_trans)begin
                    r_tx_ram_rd_pul             <=    1'b0              ;
                    r_tx_ram_trans              <=    1'b0              ;
                    r_tx_sch_cs                 <=  IDLE_TX_SCH         ;
                end
                else begin
                    r_tx_ram_rd_pul             <=    1'b1              ;
                    r_tx_ram_trans              <=    1'b1              ;
                    r_tx_sch_cs                 <=  RDES_WT1_TX_SCH     ;
                end
            end
            RDES_WT1_TX_SCH:begin
                r_tx_ram_rd_pul             <=    1'b0              ;
                r_tx_sch_cs                 <=  RDES_JUG_TX_SCH     ;
            end
            RDES_JUG_TX_SCH:begin
                if(i_tx_mem_dout[27:24] == 4'h1)begin
                    r_tx_data                   <=   36'b0                  ;
                    r_tx_data_en                <=    1'b0                  ;
                    r_tx_val                    <=   16'b0                  ;
                    r_tx_val_en                 <=    1'b0                  ;

                    o_tx_mem_addr               <=   11'b0                  ;
                    o_tx_mem_din                <=   32'b0                  ;
                    o_tx_mem_en                 <=    1'b0                  ;
                    o_tx_mem_we                 <=    4'b0                  ;

                    o_tx_rd_pt                  <=  o_tx_rd_pt + 4'h1       ;
                    r_tx_ram_trans              <=    1'b0                  ;

                    r_tx_ram_pkt_len            <=   12'b0                  ;
                    r_tx_ram_pkt_sop            <=    1'b0                  ;

                    r_tx_sch_cs                 <=  IDLE_TX_SCH             ;
                end
                else begin
                    r_tx_data                   <=   36'b0                  ;
                    r_tx_data_en                <=    1'b0                  ;
                    r_tx_val                    <=  {2'b10,i_tx_mem_dout[1:0],i_tx_mem_dout[23:12]} ;
                    r_tx_val_en                 <=    1'b0                  ;

                    o_tx_mem_addr               <=   {o_tx_rd_pt[1:0],9'h0} + i_tx_mem_dout[11:2]   ;
                    o_tx_mem_din                <=   32'b0                  ;
                    o_tx_mem_en                 <=    1'b1                  ;
                    o_tx_mem_we                 <=    4'b0                  ;

                    o_tx_rd_pt                  <=  o_tx_rd_pt              ;
                    r_tx_ram_trans              <=    1'b1                  ;

                    r_tx_ram_pkt_len            <=  i_tx_mem_dout[23:12] + i_tx_mem_dout[1:0]       ;
                    r_tx_ram_pkt_sop            <=    1'b1                  ;

                    r_tx_sch_cs                 <=  RDA_WT0_TX_SCH          ;
                end
            end
            RDA_WT0_TX_SCH:begin
                o_tx_mem_addr               <=   o_tx_mem_addr + 12'h1  ;
                o_tx_mem_din                <=   32'b0                  ;
                o_tx_mem_en                 <=    1'b1                  ;
                o_tx_mem_we                 <=    4'b0                  ;

                r_tx_sch_cs                 <=  RDA_WT1_TX_SCH          ;
            end
            RDA_WT1_TX_SCH:begin
                o_tx_mem_addr               <=   o_tx_mem_addr + 12'h1  ;
                o_tx_mem_din                <=   32'b0                  ;
                o_tx_mem_en                 <=    1'b1                  ;
                o_tx_mem_we                 <=    4'b0                  ;

                r_tx_sch_cs                 <=  RD_TX_SCH               ;
            end
            RD_TX_SCH:begin
                o_tx_mem_addr               <=   o_tx_mem_addr + 12'h1  ;
                o_tx_mem_din                <=   32'b0                  ;
                o_tx_mem_en                 <=    1'b1                  ;
                o_tx_mem_we                 <=    4'b0                  ;

                r_tx_ram_pkt_sop            <=    1'b0                  ;
                r_tx_ram_pkt_len            <=  r_tx_ram_pkt_len - 12'h4    ;

                r_tx_data[35]               <=  r_tx_ram_pkt_sop        ;

                if(r_tx_ram_pkt_len <= 12'h4)begin
                    r_tx_data[34]               <=    1'b1                      ;
                    r_tx_data[33:32]            <=  r_tx_ram_pkt_len[1:0] - 2'b1;//???????????????????????????
                    o_tx_rd_pt                  <=  o_tx_rd_pt + 4'h1       ;
                    r_tx_sch_cs                 <=  IDLE_TX_SCH             ;
                end
                else begin
                    r_tx_data[34]               <=    1'b0                  ;
                    if(r_tx_ram_pkt_sop)begin
                        r_tx_data[33:32]            <=  2'h3 - r_tx_val[13:12]  ;
                    end
                    else begin
                        r_tx_data[33:32]            <= 2'b11                    ;
                    end
                    o_tx_rd_pt                  <=  o_tx_rd_pt              ;
                    r_tx_sch_cs                 <=  RD_TX_SCH               ;
                end
                if(i_start_cfg[2])begin//big_endian
                    r_tx_data[31:0]             <=   i_tx_mem_dout[31:0]                ;
                end
                else begin
                    r_tx_data[31:0]             <=	{i_tx_mem_dout[7:0],i_tx_mem_dout[15:8],i_tx_mem_dout[23:16],i_tx_mem_dout[31:24]};
                end
                r_tx_data_en                <=    1'b1                  ;
                r_tx_val                    <=  r_tx_val                ;
                r_tx_val_en                 <=  r_tx_ram_pkt_sop        ;
            end
            default:begin
                r_tx_sch_cs                 <=  IDLE_TX_SCH             ;
            end
        endcase
    end
end

//=========================================== pkt mux function always block ==========================================//
always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        o_pkt_data		            <=   36'b0              ;
        o_pkt_data_en	            <=    1'b0              ;
        o_pkt_val		            <=   16'b0              ;
        o_pkt_val_en	            <=    1'b0              ;

        r_pkt_data_buf              <=   36'b0              ;
        r_pkt_data_offset           <=    2'b0              ;

        r_mux_sch_cs                 <=  IDLE_MUX_SCH       ;
    end
    else begin
        case(r_mux_sch_cs)
            IDLE_MUX_SCH:begin
                o_pkt_data		            <=   36'b0              ;
                o_pkt_data_en	            <=    1'b0              ;
                o_pkt_val_en	            <=    1'b0              ;

                case({r_tx_val_en,r_rx_val_en})
                    2'b00:begin
                        o_pkt_val		            <=   16'b0              ;
                        r_pkt_data_buf              <=   36'b0              ;
                        r_pkt_data_offset           <=    2'b0              ;

                        r_mux_sch_cs                 <=  IDLE_MUX_SCH       ;
                    end
                    2'b01:begin
                        o_pkt_val		            <=  {r_rx_val[15:14],2'b0,r_rx_val[11:0]}   ;
                        r_pkt_data_buf              <=  r_rx_data           ;
                        r_pkt_data_offset           <=  r_rx_val[13:12]     ;

                        r_mux_sch_cs                 <=  TRX_MUX_SCH        ;
                    end
                    2'b10:begin
                        o_pkt_val		            <=  {r_tx_val[15:14],2'b0,r_tx_val[11:0]}   ;
                        r_pkt_data_buf              <=  r_tx_data           ;
                        r_pkt_data_offset           <=  r_tx_val[13:12]     ;

                        r_mux_sch_cs                 <=  TTX_MUX_SCH        ;
                    end
                    default:begin
                        o_pkt_val		            <=   16'b0              ;
                        r_pkt_data_buf              <=   36'b0              ;
                        r_pkt_data_offset           <=    2'b0              ;

                        r_mux_sch_cs                 <=  IDLE_MUX_SCH       ;
                    end
                endcase
            end
            TRX_MUX_SCH:begin
                r_pkt_data_buf              <=  r_rx_data           ;
                case(r_pkt_data_offset)
                    2'b00:begin
                        o_pkt_data		            <=   r_pkt_data_buf     ;
                        o_pkt_data_en	            <=    1'b1              ;
                        o_pkt_val_en	            <=    1'b0              ;
                        if(r_rx_data[34])begin
                            r_mux_sch_cs                 <=  EOP_MUX_SCH        ;
                        end
                        else begin
                            r_mux_sch_cs                 <=  TRX_MUX_SCH        ;
                        end
                    end
                    2'b01:begin
                        o_pkt_data[35]              <=   r_pkt_data_buf[35] ;
                        o_pkt_data[31:0]            <=   {r_pkt_data_buf[23:0],r_rx_data[31:24]}    ;
                        o_pkt_data_en	            <=    1'b1              ;
                        if(r_rx_data[34])begin
                            if(r_rx_data[33:32] == 2'h0)begin
                                o_pkt_data[34]              <=    1'b1              ;
                                o_pkt_data[33:32]           <=    2'b11             ;
                                o_pkt_val_en	            <=    1'b1              ;
                                r_mux_sch_cs                <=  IDLE_MUX_SCH        ;
                            end
                            else begin
                                o_pkt_data[34]              <=    r_pkt_data_buf[34]    ;
                                o_pkt_data[33:32]           <=    2'b11                 ;
                                o_pkt_val_en	            <=    1'b0                  ;
                                r_mux_sch_cs                <=  EOP_MUX_SCH             ;
                            end
                        end
                        else begin
                            o_pkt_data[34]              <=    r_pkt_data_buf[34]    ;
                            o_pkt_data[33:32]           <=    2'b11                 ;
                            o_pkt_val_en	            <=    1'b0                  ;
                            r_mux_sch_cs                <=  TRX_MUX_SCH             ;
                        end
                    end
                    2'b10:begin
                        o_pkt_data[35]              <=   r_pkt_data_buf[35] ;
                        o_pkt_data[31:0]            <=   {r_pkt_data_buf[15:0],r_rx_data[31:16]}    ;
                        o_pkt_data_en	            <=    1'b1              ;
                        if(r_rx_data[34])begin
                            if(r_rx_data[33] == 1'b0)begin
                                o_pkt_data[34]              <=    1'b1              ;
                                o_pkt_data[33:32]           <=  {1'b1,r_rx_data[32]}    ;
                                o_pkt_val_en	            <=    1'b1              ;
                                r_mux_sch_cs                <=  IDLE_MUX_SCH        ;
                            end
                            else begin
                                o_pkt_data[34]              <=    r_pkt_data_buf[34]    ;
                                o_pkt_data[33:32]           <=    2'b11                 ;
                                o_pkt_val_en	            <=    1'b0                  ;
                                r_mux_sch_cs                <=  EOP_MUX_SCH             ;
                            end
                        end
                        else begin
                            o_pkt_data[34]              <=    r_pkt_data_buf[34]    ;
                            o_pkt_data[33:32]           <=    2'b11                 ;
                            o_pkt_val_en	            <=    1'b0                  ;
                            r_mux_sch_cs                <=  TRX_MUX_SCH             ;
                        end
                    end
                    default:begin
                        o_pkt_data[35]              <=   r_pkt_data_buf[35] ;
                        o_pkt_data[31:0]            <=   {r_pkt_data_buf[7:0],r_rx_data[31:8]}    ;
                        o_pkt_data_en	            <=    1'b1              ;
                        if(r_rx_data[34])begin
                            if(r_rx_data[33:32] == 2'b11)begin
                                o_pkt_data[34]              <=    r_pkt_data_buf[34]    ;
                                o_pkt_data[33:32]           <=    2'b11                 ;
                                o_pkt_val_en	            <=    1'b0                  ;
                                r_mux_sch_cs                <=  EOP_MUX_SCH             ;
                            end
                            else begin
                                o_pkt_data[34]              <=    1'b1              ;
                                o_pkt_data[33:32]           <=  r_rx_data[33:32] + 2'b1 ;
                                o_pkt_val_en	            <=    1'b1              ;
                                r_mux_sch_cs                <=  IDLE_MUX_SCH        ;
                            end
                        end
                        else begin
                            o_pkt_data[34]              <=    r_pkt_data_buf[34]    ;
                            o_pkt_data[33:32]           <=    2'b11                 ;
                            o_pkt_val_en	            <=    1'b0                  ;
                            r_mux_sch_cs                <=  TRX_MUX_SCH             ;
                        end
                    end
                endcase
            end
            TTX_MUX_SCH:begin
                r_pkt_data_buf              <=  r_tx_data           ;
                case(r_pkt_data_offset)
                    2'b00:begin
                        o_pkt_data		            <=   r_pkt_data_buf     ;
                        o_pkt_data_en	            <=    1'b1              ;
                        o_pkt_val_en	            <=    1'b0              ;
                        if(r_tx_data[34])begin
                            r_mux_sch_cs                 <=  EOP_MUX_SCH        ;
                        end
                        else begin
                            r_mux_sch_cs                 <=  TTX_MUX_SCH        ;
                        end
                    end
                    2'b01:begin
                        o_pkt_data[35]              <=   r_pkt_data_buf[35] ;
                        o_pkt_data[31:0]            <=   {r_pkt_data_buf[23:0],r_tx_data[31:24]}    ;
                        o_pkt_data_en	            <=    1'b1              ;
                        if(r_tx_data[34])begin
                            if(r_tx_data[33:32] == 2'h0)begin
                                o_pkt_data[34]              <=    1'b1              ;
                                o_pkt_data[33:32]           <=    2'b11             ;
                                o_pkt_val_en	            <=    1'b1              ;
                                r_mux_sch_cs                <=  IDLE_MUX_SCH        ;
                            end
                            else begin
                                o_pkt_data[34]              <=    r_pkt_data_buf[34]    ;
                                o_pkt_data[33:32]           <=    2'b11                 ;
                                o_pkt_val_en	            <=    1'b0                  ;
                                r_mux_sch_cs                <=  EOP_MUX_SCH             ;
                            end
                        end
                        else begin
                            o_pkt_data[34]              <=    r_pkt_data_buf[34]    ;
                            o_pkt_data[33:32]           <=    2'b11                 ;
                            o_pkt_val_en	            <=    1'b0                  ;
                            r_mux_sch_cs                <=  TTX_MUX_SCH             ;
                        end
                    end
                    2'b10:begin
                        o_pkt_data[35]              <=   r_pkt_data_buf[35] ;
                        o_pkt_data[31:0]            <=   {r_pkt_data_buf[15:0],r_tx_data[31:16]}    ;
                        o_pkt_data_en	            <=    1'b1              ;
                        if(r_tx_data[34])begin
                            if(r_tx_data[33] == 1'b0)begin
                                o_pkt_data[34]              <=    1'b1              ;
                                o_pkt_data[33:32]           <=  {1'b1,r_tx_data[32]}    ;
                                o_pkt_val_en	            <=    1'b1              ;
                                r_mux_sch_cs                <=  IDLE_MUX_SCH        ;
                            end
                            else begin
                                o_pkt_data[34]              <=    r_pkt_data_buf[34]    ;
                                o_pkt_data[33:32]           <=    2'b11                 ;
                                o_pkt_val_en	            <=    1'b0                  ;
                                r_mux_sch_cs                <=  EOP_MUX_SCH             ;
                            end
                        end
                        else begin
                            o_pkt_data[34]              <=    r_pkt_data_buf[34]    ;
                            o_pkt_data[33:32]           <=    2'b11                 ;
                            o_pkt_val_en	            <=    1'b0                  ;
                            r_mux_sch_cs                <=  TTX_MUX_SCH             ;
                        end
                    end
                    default:begin
                        o_pkt_data[35]              <=   r_pkt_data_buf[35] ;
                        o_pkt_data[31:0]            <=   {r_pkt_data_buf[7:0],r_tx_data[31:8]}    ;
                        o_pkt_data_en	            <=    1'b1              ;
                        if(r_tx_data[34])begin
                            if(r_tx_data[33:32] == 2'b11)begin
                                o_pkt_data[34]              <=    r_pkt_data_buf[34]    ;
                                o_pkt_data[33:32]           <=    2'b11                 ;
                                o_pkt_val_en	            <=    1'b0                  ;
                                r_mux_sch_cs                <=  EOP_MUX_SCH             ;
                            end
                            else begin
                                o_pkt_data[34]              <=    1'b1              ;
                                o_pkt_data[33:32]           <=  r_tx_data[33:32] + 2'b1 ;
                                o_pkt_val_en	            <=    1'b1              ;
                                r_mux_sch_cs                <=  IDLE_MUX_SCH        ;
                            end
                        end
                        else begin
                            o_pkt_data[34]              <=    r_pkt_data_buf[34]    ;
                            o_pkt_data[33:32]           <=    2'b11                 ;
                            o_pkt_val_en	            <=    1'b0                  ;
                            r_mux_sch_cs                <=  TTX_MUX_SCH             ;
                        end
                    end
                endcase
            end
            EOP_MUX_SCH:begin
                o_pkt_data_en	            <=    1'b1              ;
                o_pkt_val_en	            <=    1'b1              ;
                r_mux_sch_cs                <=  IDLE_MUX_SCH        ;
                case(r_pkt_data_offset)
                    2'b00:begin
                        o_pkt_data[35]              <=   r_pkt_data_buf[35]     ;
                        o_pkt_data[34]              <=   r_pkt_data_buf[34]     ;
                        o_pkt_data[33:32]           <=   r_pkt_data_buf[33:32]  ;
                        o_pkt_data[31:0]            <=   r_pkt_data_buf[31:0]   ;
                    end
                    2'b01:begin
                        o_pkt_data[35]              <=   r_pkt_data_buf[35]     ;
                        o_pkt_data[34]              <=   r_pkt_data_buf[34]     ;
                        o_pkt_data[33:32]           <=   r_pkt_data_buf[33:32] - 2'b01  ;
                        o_pkt_data[31:0]            <=   {r_pkt_data_buf[23:0],8'b0}    ;
                    end
                    2'b10:begin
                        o_pkt_data[35]              <=   r_pkt_data_buf[35]     ;
                        o_pkt_data[34]              <=   r_pkt_data_buf[34]     ;
                        o_pkt_data[33:32]           <=   r_pkt_data_buf[33:32] - 2'b10  ;
                        o_pkt_data[31:0]            <=   {r_pkt_data_buf[15:0],16'b0}   ;
                    end
                    default:begin
                        o_pkt_data[35]              <=   r_pkt_data_buf[35]     ;
                        o_pkt_data[34]              <=   r_pkt_data_buf[34]     ;
                        o_pkt_data[33:32]           <=   r_pkt_data_buf[33:32] - 2'b11  ;
                        o_pkt_data[31:0]            <=   {r_pkt_data_buf[7:0],24'b0}    ;
                    end
                endcase
            end
            default:begin
                r_mux_sch_cs                <=  IDLE_MUX_SCH        ;
            end
        endcase
    end
end

//======================================= debug function always block =======================================//



//=========================================== fifo instantiations ==========================================//

wire		    		w_data_e1a      			;           //active-high,one bit or two bit error is detected(ECC)
wire		    		w_data_e2a      			;           //active-high,two or more bit error is detected(ECC)

wire		    		w_info_e1a      			;           //active-high,one bit or two bit error is detected(ECC)
wire		    		w_info_e2a      			;           //active-high,two or more bit error is detected(ECC)

always @(posedge i_rv_clk)begin
    if(!i_rv_rst_n) begin
        e1a    <=  2'b0            ;
        e2a    <=  2'b0            ;
    end
    else begin
        e1a[0]    <=  w_data_e1a   ?   1'b1    :   e1a[0];
        e1a[1]    <=  w_info_e1a   ?   1'b1    :   e1a[1];

        e2a[0]    <=  w_data_e2a   ?   1'b1    :   e2a[0];
        e2a[1]    <=  w_info_e2a   ?   1'b1    :   e2a[1];
    end
end


ASYNCFIFO_1024x36 pkt_data_fifo(
			.e1a                (w_data_e1a                     ),
			.e2a                (w_data_e2a                     ),
            .rd_aclr            (~i_rv_rst_n                    ),
            .wr_aclr            (~i_rst_clk_rx_n                ),
			.data				(i_pkt_data                     ),
            .rdclk              (i_rv_clk                       ),
			.rdreq				(r_pkt_data_rd                  ),
			.wrclk              (i_clk_rx                       ),
			.wrreq				(i_pkt_data_en                  ),
			.q					(w_pkt_data_q                   ),
            .wrfull             (                               ),
	        .wralfull           (                               ),
	        .wrempty            (                               ),
	        .wralempty          (                               ),
	        .rdfull             (                               ),
	        .rdalfull           (                               ),
			.rdempty			(w_pkt_data_empty               ),
			.rdalempty          (							    ),
			.wrusedw			(w_pkt_data_usedw               ),
			.rdusedw			(							    )
);

ASYNCFIFO_128x16 pkt_info_fifo
(
            .e1a                (w_info_e1a                     ),
            .e2a                (w_info_e2a                     ),
            .rd_aclr            (~i_rv_rst_n                    ),
            .wr_aclr            (~i_rst_clk_rx_n                ),
            .data               (i_pkt_val                      ),
            .rdclk              (i_rv_clk                       ),
            .rdreq              (r_pkt_info_rd                  ),
            .wrclk              (i_clk_rx                       ),
            .wrreq              (i_pkt_val_en                   ),
            .q                  (w_pkt_info_q                   ),
            .wrfull             (                               ),
            .wralfull           (                               ),
            .wrempty            (                               ),
            .wralempty          (                               ),
            .rdfull             (                               ),
            .rdalfull           (                               ),
            .rdempty            (w_pkt_info_empty               ),
            .rdalempty          (                               ),
            .wrusedw            (w_pkt_info_usedw               ),
            .rdusedw            (                               )
);

endmodule
