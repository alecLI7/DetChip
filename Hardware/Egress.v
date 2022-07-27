/*========================================================================================================*\
          Filename : Egress.v
            Author : zc
       Description : 
	     Called by : 
  Revision History : 01/15/2022 Revision 1.0  zc
                     mm/dd/yy
           Company : NUDT
============================================================================================================
          Comments :
          a. 
\*========================================================================================================*/
module Egress
(
//============================================== clk & rst ===========================================//

//system clock & resets
 input     wire                 i_sys_clk                       //system clk
,input     wire                 i_sys_rst_n                     //rst of sys_clk

//========================================== Input pkt data  =======================================//

,input	    wire	[35:0]	    i_be_pkt_data				    //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,input	    wire			    i_be_pkt_data_en			    //data enable
,input	    wire	[15:0]	    i_be_pkt_val				    //frame valid & length
,input	    wire			    i_be_pkt_val_en				    //valid enable
,output	    wire                o_be_pkt_data_alf			    //fifo allmostfull

,input	    wire	[35:0]	    i_ts_pkt_data				    //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,input	    wire			    i_ts_pkt_data_en			    //data enable
,input	    wire	[15:0]	    i_ts_pkt_val				    //frame valid & length
,input	    wire			    i_ts_pkt_val_en				    //valid enable
,output	    wire                o_ts_pkt_data_alf			    //fifo allmostfull

,output	    reg	    [35:0]	    o_pkt_data				        //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,output	    reg			        o_pkt_data_en			        //data enable
,output	    reg	    [15:0]	    o_pkt_val				        //frame valid & length
,output	    reg			        o_pkt_val_en				    //valid enable
,input	    wire	    	    i_pkt_data_alf			        //fifo allmostfull

,output     reg     [ 3:0]      e1a                             //e1a
,output     reg     [ 3:0]      e2a                             //e2a

);

//====================================== internal reg/wire/param declarations ======================================//

reg						    r_be_pkt_data_rd            ;   //rden
wire		[9:0]			w_be_pkt_data_usedw         ;   //usedwords
wire		[35:0]			w_be_pkt_data_q             ;   //read data out
wire						w_be_pkt_data_empty         ;   //empty

reg						    r_be_pkt_info_rd            ;   //rden
wire		[9:0]			w_be_pkt_info_usedw         ;   //usedwords
wire		[15:0]			w_be_pkt_info_q             ;   //read data out
wire						w_be_pkt_info_empty         ;   //empty

reg						    r_ts_pkt_data_rd            ;   //rden
wire		[9:0]			w_ts_pkt_data_usedw         ;   //usedwords
wire		[35:0]			w_ts_pkt_data_q             ;   //read data out
wire						w_ts_pkt_data_empty         ;   //empty

reg						    r_ts_pkt_info_rd            ;   //rden
wire		[9:0]			w_ts_pkt_info_usedw         ;   //usedwords
wire		[15:0]			w_ts_pkt_info_q             ;   //read data out
wire						w_ts_pkt_info_empty         ;   //empty

assign      o_be_pkt_data_alf   =   w_be_pkt_data_usedw[9]  ;
assign      o_ts_pkt_data_alf   =   w_ts_pkt_data_usedw[9]  ;

reg         [4:0]           r_egress_cs                 ;   //

localparam	IDLE_EGR                =	5'h01       ,
            TS_TRANS_EGR            =	5'h02       ,
            BE_TRANS_EGR            =	5'h04       ,
            TS_DISC_EGR             =	5'h08       ,
            BE_DISC_EGR             =	5'h10       ;

always @(posedge i_sys_clk)begin
    if(!i_sys_rst_n) begin
        o_pkt_data	                    <=   36'b0              ;
        o_pkt_data_en                   <=    1'b0              ;
        o_pkt_val	                    <=   16'b0              ;
        o_pkt_val_en	                <=    1'b0              ;

        r_ts_pkt_data_rd                <=    1'b0              ;
        r_ts_pkt_info_rd                <=    1'b0              ;

        r_be_pkt_data_rd                <=    1'b0              ;
        r_be_pkt_info_rd                <=    1'b0              ;

        r_egress_cs                     <=  IDLE_EGR            ;
    end
    else begin
        case(r_egress_cs)
            IDLE_EGR:begin
                o_pkt_data	                    <=   36'b0              ;
                o_pkt_data_en                   <=    1'b0              ;
                o_pkt_val_en	                <=    1'b0              ;

                if(~w_ts_pkt_info_empty)begin
                    if(w_ts_pkt_info_q[15])begin
                        if(~i_pkt_data_alf)begin
                            o_pkt_val	                    <=   w_ts_pkt_info_q    ;

                            r_ts_pkt_data_rd                <=    1'b1              ;
                            r_ts_pkt_info_rd                <=    1'b1              ;
                            r_be_pkt_data_rd                <=    1'b0              ;
                            r_be_pkt_info_rd                <=    1'b0              ;

                            r_egress_cs                     <=  TS_TRANS_EGR        ;
                        end
                        else begin
                            o_pkt_val	                    <=   16'b0              ;

                            r_ts_pkt_data_rd                <=    1'b0              ;
                            r_ts_pkt_info_rd                <=    1'b0              ;
                            r_be_pkt_data_rd                <=    1'b0              ;
                            r_be_pkt_info_rd                <=    1'b0              ;

                            r_egress_cs                     <=  IDLE_EGR            ;
                        end
                    end
                    else begin
                        o_pkt_val	                    <=   16'b0              ;

                        r_ts_pkt_data_rd                <=    1'b1              ;
                        r_ts_pkt_info_rd                <=    1'b1              ;
                        r_be_pkt_data_rd                <=    1'b0              ;
                        r_be_pkt_info_rd                <=    1'b0              ;

                        r_egress_cs                     <=  TS_DISC_EGR         ;
                    end
                end
                else if(~w_be_pkt_info_empty)begin
                    if(w_be_pkt_info_q[15])begin
                        if(~i_pkt_data_alf)begin
                            o_pkt_val	                    <=   w_be_pkt_info_q    ;

                            r_ts_pkt_data_rd                <=    1'b0              ;
                            r_ts_pkt_info_rd                <=    1'b0              ;
                            r_be_pkt_data_rd                <=    1'b1              ;
                            r_be_pkt_info_rd                <=    1'b1              ;

                            r_egress_cs                     <=  BE_TRANS_EGR        ;
                        end
                        else begin
                            o_pkt_val	                    <=   16'b0              ;

                            r_ts_pkt_data_rd                <=    1'b0              ;
                            r_ts_pkt_info_rd                <=    1'b0              ;
                            r_be_pkt_data_rd                <=    1'b1              ;
                            r_be_pkt_info_rd                <=    1'b1              ;

                            r_egress_cs                     <=  BE_DISC_EGR         ;
                        end
                    end
                    else begin
                        o_pkt_val	                    <=   16'b0              ;

                        r_ts_pkt_data_rd                <=    1'b0              ;
                        r_ts_pkt_info_rd                <=    1'b0              ;
                        r_be_pkt_data_rd                <=    1'b1              ;
                        r_be_pkt_info_rd                <=    1'b1              ;

                        r_egress_cs                     <=  BE_DISC_EGR         ;
                    end
                end
                else begin
                    o_pkt_val	                    <=   16'b0              ;

                    r_ts_pkt_data_rd                <=    1'b0              ;
                    r_ts_pkt_info_rd                <=    1'b0              ;
                    r_be_pkt_data_rd                <=    1'b0              ;
                    r_be_pkt_info_rd                <=    1'b0              ;

                    r_egress_cs                     <=  IDLE_EGR            ;
                end
            end
            TS_TRANS_EGR:begin
                r_ts_pkt_info_rd                <=    1'b0              ;
                r_be_pkt_data_rd                <=    1'b0              ;
                r_be_pkt_info_rd                <=    1'b0              ;

                o_pkt_data	                    <=  w_ts_pkt_data_q     ;
                o_pkt_data_en                   <=    1'b1              ;
                o_pkt_val	                    <=  o_pkt_val           ;
                if(w_ts_pkt_data_q[34])begin
                    o_pkt_val_en	                <=    1'b1              ;
                    r_ts_pkt_data_rd                <=    1'b0              ;
                    r_egress_cs                     <=  IDLE_EGR            ;
                end
                else begin
                    o_pkt_val_en	                <=    1'b0              ;
                    r_ts_pkt_data_rd                <=    1'b1              ;
                    r_egress_cs                     <=  TS_TRANS_EGR        ;
                end
            end
            BE_TRANS_EGR:begin
                r_ts_pkt_data_rd                <=    1'b0              ;
                r_ts_pkt_info_rd                <=    1'b0              ;
                r_be_pkt_info_rd                <=    1'b0              ;

                o_pkt_data	                    <=  w_be_pkt_data_q     ;
                o_pkt_data_en                   <=    1'b1              ;
                o_pkt_val	                    <=  o_pkt_val           ;
                if(w_be_pkt_data_q[34])begin
                    o_pkt_val_en	                <=    1'b1              ;
                    r_be_pkt_data_rd                <=    1'b0              ;
                    r_egress_cs                     <=  IDLE_EGR            ;
                end
                else begin
                    o_pkt_val_en	                <=    1'b0              ;
                    r_be_pkt_data_rd                <=    1'b1              ;
                    r_egress_cs                     <=  BE_TRANS_EGR        ;
                end
            end
            TS_DISC_EGR:begin
                r_ts_pkt_info_rd                <=    1'b0              ;
                r_be_pkt_data_rd                <=    1'b0              ;
                r_be_pkt_info_rd                <=    1'b0              ;
                
                o_pkt_data	                    <=   36'b0              ;
                o_pkt_data_en                   <=    1'b0              ;
                o_pkt_val	                    <=   16'b0              ;
                o_pkt_val_en	                <=    1'b0              ;
                if(w_ts_pkt_data_q[34])begin
                    r_ts_pkt_data_rd                <=    1'b0              ;
                    r_egress_cs                     <=  IDLE_EGR            ;
                end
                else begin
                    r_ts_pkt_data_rd                <=    1'b1              ;
                    r_egress_cs                     <=  TS_DISC_EGR         ;
                end
            end
            BE_DISC_EGR:begin
                r_ts_pkt_data_rd                <=    1'b0              ;
                r_ts_pkt_info_rd                <=    1'b0              ;
                r_be_pkt_info_rd                <=    1'b0              ;

                o_pkt_data	                    <=   36'b0              ;
                o_pkt_data_en                   <=    1'b0              ;
                o_pkt_val	                    <=   16'b0              ;
                o_pkt_val_en	                <=    1'b0              ;
                if(w_be_pkt_data_q[34])begin
                    r_be_pkt_data_rd                <=    1'b0              ;
                    r_egress_cs                     <=  IDLE_EGR            ;
                end
                else begin
                    r_be_pkt_data_rd                <=    1'b1              ;
                    r_egress_cs                     <=  BE_DISC_EGR         ;
                end
            end
            default:begin
                r_egress_cs                     <=  IDLE_EGR            ;
            end
        endcase
    end
end


//=========================================== fifo instantiations ==========================================//

wire		[1:0]		w_data_e1a      			;           //active-high,one bit or two bit error is detected(ECC)
wire		[1:0]		w_data_e2a      			;           //active-high,two or more bit error is detected(ECC)

wire		[1:0]		w_info_e1a      			;           //active-high,one bit or two bit error is detected(ECC)
wire		[1:0]		w_info_e2a      			;           //active-high,two or more bit error is detected(ECC)


always @(posedge i_sys_clk or negedge i_sys_rst_n)begin
    if(!i_sys_rst_n) begin
        e1a   <=  8'b0            ;
        e2a   <=  8'b0            ;
    end
    else begin
        e1a[0]    <=  w_data_e1a[0]   ?   1'b1    :   e1a[0];
        e1a[1]    <=  w_data_e1a[1]   ?   1'b1    :   e1a[1];
        e1a[2]    <=  w_info_e1a[0]   ?   1'b1    :   e1a[2];
        e1a[3]    <=  w_info_e1a[1]   ?   1'b1    :   e1a[3];

        e2a[0]    <=  w_data_e2a[0]   ?   1'b1    :   e2a[0];
        e2a[1]    <=  w_data_e2a[1]   ?   1'b1    :   e2a[1];
        e2a[2]    <=  w_info_e2a[0]   ?   1'b1    :   e2a[2];
        e2a[3]    <=  w_info_e2a[1]   ?   1'b1    :   e2a[3];
    end
end

ASYNCFIFO_1024x36 ts_pkt_data_fifo(
			.e1a                (w_data_e1a[0]                  ),
			.e2a                (w_data_e2a[0]                  ),
            .rd_aclr            (~i_sys_rst_n                   ),
            .wr_aclr            (~i_sys_rst_n                   ),
			.data				(i_ts_pkt_data                  ),
            .rdclk              (i_sys_clk                      ),
			.rdreq				(r_ts_pkt_data_rd               ),
			.wrclk              (i_sys_clk                      ),
			.wrreq				(i_ts_pkt_data_en               ),
			.q					(w_ts_pkt_data_q                ),
            .wrfull             (                               ),
	        .wralfull           (                               ),
	        .wrempty            (                               ),
	        .wralempty          (                               ),
	        .rdfull             (                               ),
	        .rdalfull           (                               ),
			.rdempty			(w_ts_pkt_data_empty            ),
			.rdalempty          (							    ),
			.wrusedw			(w_ts_pkt_data_usedw            ),
			.rdusedw			(							    )
);

ASYNCFIFO_128x16 ts_pkt_info_fifo
(
            .e1a                (w_info_e1a[0]                  ),
            .e2a                (w_info_e2a[0]                  ),
            .rd_aclr            (~i_sys_rst_n                   ),
            .wr_aclr            (~i_sys_rst_n                   ),
            .data               (i_ts_pkt_val                   ),
            .rdclk              (i_sys_clk                      ),
            .rdreq              (r_ts_pkt_info_rd               ),
            .wrclk              (i_sys_clk                      ),
            .wrreq              (i_ts_pkt_val_en                ),
            .q                  (w_ts_pkt_info_q                ),
            .wrfull             (                               ),
            .wralfull           (                               ),
            .wrempty            (                               ),
            .wralempty          (                               ),
            .rdfull             (                               ),
            .rdalfull           (                               ),
            .rdempty            (w_ts_pkt_info_empty            ),
            .rdalempty          (                               ),
            .wrusedw            (w_ts_pkt_info_usedw            ),
            .rdusedw            (                               )
);

ASYNCFIFO_1024x36 be_pkt_data_fifo(
			.e1a                (w_data_e1a[1]                  ),
			.e2a                (w_data_e2a[1]                  ),
            .rd_aclr            (~i_sys_rst_n                   ),
            .wr_aclr            (~i_sys_rst_n                   ),
			.data				(i_be_pkt_data                  ),
            .rdclk              (i_sys_clk                      ),
			.rdreq				(r_be_pkt_data_rd               ),
			.wrclk              (i_sys_clk                      ),
			.wrreq				(i_be_pkt_data_en               ),
			.q					(w_be_pkt_data_q                ),
            .wrfull             (                               ),
	        .wralfull           (                               ),
	        .wrempty            (                               ),
	        .wralempty          (                               ),
	        .rdfull             (                               ),
	        .rdalfull           (                               ),
			.rdempty			(w_be_pkt_data_empty            ),
			.rdalempty          (							    ),
			.wrusedw			(w_be_pkt_data_usedw            ),
			.rdusedw			(							    )
);

ASYNCFIFO_128x16 be_pkt_info_fifo
(
            .e1a                (w_info_e1a[1]                  ),
            .e2a                (w_info_e2a[1]                  ),
            .rd_aclr            (~i_sys_rst_n                   ),
            .wr_aclr            (~i_sys_rst_n                   ),
            .data               (i_be_pkt_val                   ),
            .rdclk              (i_sys_clk                      ),
            .rdreq              (r_be_pkt_info_rd               ),
            .wrclk              (i_sys_clk                      ),
            .wrreq              (i_be_pkt_val_en                ),
            .q                  (w_be_pkt_info_q                ),
            .wrfull             (                               ),
            .wralfull           (                               ),
            .wrempty            (                               ),
            .wralempty          (                               ),
            .rdfull             (                               ),
            .rdalfull           (                               ),
            .rdempty            (w_be_pkt_info_empty            ),
            .rdalempty          (                               ),
            .wrusedw            (w_be_pkt_info_usedw            ),
            .rdusedw            (                               )
);

endmodule