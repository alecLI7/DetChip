/*========================================================================================================*\
          Filename : Ingress.v
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
module Ingress
(
//============================================== clk & rst ===========================================//

//system clock & resets
 input     wire                 i_sys_clk                       //system clk
,input     wire                 i_sys_rst_n                     //rst of sys_clk

//========================================== Input pkt data  =======================================//

,input	    wire	[35:0]	    i_pkt_data					    //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,input	    wire			    i_pkt_data_en				    //data enable
,input	    wire	[15:0]	    i_pkt_val					    //frame valid & length
,input	    wire			    i_pkt_val_en				    //valid enable
,output	    wire    [9:0]       o_pkt_data_usedw			    //fifo allmostfull

,output	    reg	    [35:0]	    o_be_pkt_data				    //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,output	    reg			        o_be_pkt_data_en			    //data enable
,output	    reg	    [15:0]	    o_be_pkt_val				    //frame valid & length
,output	    reg			        o_be_pkt_val_en				    //valid enable
,input	    wire    [9:0]       i_be_pkt_data_usedw			    //fifo allmostfull

,output	    reg	    [35:0]	    o_ts_pkt_data				    //[35:34]:10 head \ 00 body \ 01 tail\,[33:32]:valid bytes,[31:0],data
,output	    reg			        o_ts_pkt_data_en			    //data enable
,output	    reg	    [15:0]	    o_ts_pkt_val				    //frame valid & length
,output	    reg			        o_ts_pkt_val_en				    //valid enable
,input	    wire	[9:0]       i_ts_pkt_data_usedw			    //fifo allmostfull

,output     reg     [ 1:0]      e1a                             //e1a
,output     reg     [ 1:0]      e2a                             //e2a

);

//====================================== internal reg/wire/param declarations ======================================//



reg						    r_pkt_data_rd               ;   //rden
wire		[9:0]			w_pkt_data_usedw            ;   //usedwords
wire		[35:0]			w_pkt_data_q                ;   //read data out
wire						w_pkt_data_empty            ;   //empty

reg						    r_pkt_info_rd               ;   //rden
wire		[9:0]			w_pkt_info_usedw            ;   //usedwords
wire		[15:0]			w_pkt_info_q                ;   //read data out
wire						w_pkt_info_empty            ;   //empty

reg         [3:0]           r_ingress_cs                ;   //

wire                        w_be_pkt_data_alf           ;
wire                        w_ts_pkt_data_alf           ;
assign      o_pkt_data_usedw    =   w_pkt_data_usedw    ;
assign      w_be_pkt_data_alf   =   i_be_pkt_data_usedw[9]  ;
assign      w_ts_pkt_data_alf   =   i_ts_pkt_data_usedw[9]  ;

localparam	IDLE_INGR               =	4'h1        ,
            TS_TRANS_INGR           =	4'h2        ,
            BE_TRANS_INGR           =	4'h4        ,
            DISC_INGR               =	4'h8        ;

always @(posedge i_sys_clk)begin
    if(!i_sys_rst_n) begin
        o_be_pkt_data	                <=   36'b0              ;
        o_be_pkt_data_en                <=    1'b0              ;
        o_be_pkt_val	                <=   16'b0              ;
        o_be_pkt_val_en	                <=    1'b0              ;

        o_ts_pkt_data	                <=   36'b0              ;
        o_ts_pkt_data_en                <=    1'b0              ;
        o_ts_pkt_val	                <=   16'b0              ;
        o_ts_pkt_val_en	                <=    1'b0              ;

        r_pkt_data_rd                   <=    1'b0              ;
        r_pkt_info_rd                   <=    1'b0              ;

        r_ingress_cs                    <=  IDLE_INGR           ;
    end
    else begin
        case(r_ingress_cs)
            IDLE_INGR:begin
                o_be_pkt_data	                <=   36'b0              ;
                o_be_pkt_data_en                <=    1'b0              ;
                o_be_pkt_val	                <=  {w_pkt_info_q[15],1'b0,w_pkt_info_q[13:0]}  ;
                o_be_pkt_val_en	                <=    1'b0              ;

                o_ts_pkt_data	                <=   36'b0              ;
                o_ts_pkt_data_en                <=    1'b0              ;
                o_ts_pkt_val	                <=  {w_pkt_info_q[15],1'b0,w_pkt_info_q[13:0]}  ;
                o_ts_pkt_val_en	                <=    1'b0              ;

                if(~w_pkt_info_empty)begin
                    if(w_pkt_info_q[15])begin
                        if(w_pkt_info_q[14])begin
                            if(~w_ts_pkt_data_alf)begin
                                r_pkt_data_rd                   <=    1'b1              ;
                                r_pkt_info_rd                   <=    1'b1              ;
                                r_ingress_cs                    <=  TS_TRANS_INGR       ;
                            end
                            else begin
                                r_pkt_data_rd                   <=    1'b1              ;
                                r_pkt_info_rd                   <=    1'b1              ;
                                r_ingress_cs                    <=  DISC_INGR           ;
                            end
                        end
                        else if(~w_pkt_info_q[14])begin
                            if((~w_be_pkt_data_alf))begin
                                r_pkt_data_rd                   <=    1'b1              ;
                                r_pkt_info_rd                   <=    1'b1              ;
                                r_ingress_cs                    <=  BE_TRANS_INGR       ;
                            end
                            else begin
                                r_pkt_data_rd                   <=    1'b1              ;
                                r_pkt_info_rd                   <=    1'b1              ;
                                r_ingress_cs                    <=  DISC_INGR           ;
                            end
                        end
                        else begin
                            r_pkt_data_rd                   <=    1'b0              ;
                            r_pkt_info_rd                   <=    1'b0              ;
                            r_ingress_cs                    <=  IDLE_INGR           ;
                        end
                    end
                    else begin
                        r_pkt_data_rd                   <=    1'b1              ;
                        r_pkt_info_rd                   <=    1'b1              ;
                        r_ingress_cs                    <=  DISC_INGR           ;
                    end
                end
                else begin
                    r_pkt_data_rd                   <=    1'b0              ;
                    r_pkt_info_rd                   <=    1'b0              ;
                    r_ingress_cs                    <=  IDLE_INGR           ;
                end
            end
            TS_TRANS_INGR:begin
                o_ts_pkt_data	                <=  w_pkt_data_q        ;
                o_ts_pkt_data_en                <=    1'b1              ;
                o_ts_pkt_val	                <=  o_ts_pkt_val        ;

                r_pkt_info_rd                   <=    1'b0              ;
                if(w_pkt_data_q[34])begin
                    o_ts_pkt_val_en	                <=    1'b1              ;
                    r_pkt_data_rd                   <=    1'b0              ;
                    r_ingress_cs                    <=  IDLE_INGR           ;
                end
                else begin
                    o_ts_pkt_val_en	                <=    1'b0              ;
                    r_pkt_data_rd                   <=    1'b1              ;
                    r_ingress_cs                    <=  TS_TRANS_INGR       ;
                end
            end
            BE_TRANS_INGR:begin
                o_be_pkt_data	                <=  w_pkt_data_q        ;
                o_be_pkt_data_en                <=    1'b1              ;
                o_be_pkt_val	                <=  o_be_pkt_val        ;

                r_pkt_info_rd                   <=    1'b0              ;
                if(w_pkt_data_q[34])begin
                    o_be_pkt_val_en	                <=    1'b1              ;
                    r_pkt_data_rd                   <=    1'b0              ;
                    r_ingress_cs                    <=  IDLE_INGR           ;
                end
                else begin
                    o_be_pkt_val_en	                <=    1'b0              ;
                    r_pkt_data_rd                   <=    1'b1              ;
                    r_ingress_cs                    <=  BE_TRANS_INGR       ;
                end
            end
            DISC_INGR:begin
                o_be_pkt_data	                <=   36'b0              ;
                o_be_pkt_data_en                <=    1'b0              ;
                o_be_pkt_val	                <=   16'b0              ;
                o_be_pkt_val_en	                <=    1'b0              ;

                o_ts_pkt_data	                <=   36'b0              ;
                o_ts_pkt_data_en                <=    1'b0              ;
                o_ts_pkt_val	                <=   16'b0              ;
                o_ts_pkt_val_en	                <=    1'b0              ;

                r_pkt_info_rd                   <=    1'b0              ;
                if(w_pkt_data_q[34])begin
                    r_pkt_data_rd                   <=    1'b0              ;
                    r_ingress_cs                    <=  IDLE_INGR           ;
                end
                else begin
                    r_pkt_data_rd                   <=    1'b1              ;
                    r_ingress_cs                    <=  DISC_INGR           ;
                end
            end
            default:begin
                r_ingress_cs                    <=  IDLE_INGR           ;
            end
        endcase
    end
end


//=========================================== fifo instantiations ==========================================//

wire		    		w_data_e1a      			;           //active-high,one bit or two bit error is detected(ECC)
wire		    		w_data_e2a      			;           //active-high,two or more bit error is detected(ECC)

wire		    		w_info_e1a      			;           //active-high,one bit or two bit error is detected(ECC)
wire		    		w_info_e2a      			;           //active-high,two or more bit error is detected(ECC)


always @(posedge i_sys_clk)begin
    if(!i_sys_rst_n) begin
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

reg         [8:0]           r_pkt_data_cnt                ;   //
reg                         r_ts_flag                   ;   //

always @(posedge i_sys_clk)begin
    if(!i_sys_rst_n) begin
        r_pkt_data_cnt                  <=    9'b0              ;
        r_ts_flag                       <=    1'b0              ;
    end
    else begin
        if(i_pkt_data_en & i_pkt_data[34])begin//eop
            r_pkt_data_cnt                  <=    9'b0                  ;
        end
        else begin
            r_pkt_data_cnt                  <=  r_pkt_data_cnt + i_pkt_data_en   ;
        end

        if((r_pkt_data_cnt == 9'h3) && (i_pkt_data_en) )begin
            if(i_pkt_data[31:16] == 16'h98f7)begin
                r_ts_flag                       <=    1'b1              ;
            end
            else begin
                r_ts_flag                       <=    1'b0              ;
            end
        end
        else if(i_pkt_data_en & i_pkt_data[34])begin
            r_ts_flag                       <=    1'b0              ;
        end
        else begin
            r_ts_flag                       <=  r_ts_flag           ;
        end
    end
end


ASYNCFIFO_1024x36 pkt_data_fifo(
			.e1a                (w_data_e1a                     ),
			.e2a                (w_data_e2a                     ),
            .rd_aclr            (~i_sys_rst_n                   ),
            .wr_aclr            (~i_sys_rst_n                   ),
			.data				(i_pkt_data                     ),
            .rdclk              (i_sys_clk                       ),
			.rdreq				(r_pkt_data_rd                  ),
			.wrclk              (i_sys_clk                       ),
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
            .rd_aclr            (~i_sys_rst_n                   ),
            .wr_aclr            (~i_sys_rst_n                   ),
            .data               ({i_pkt_val[15],r_ts_flag,i_pkt_val[13:0]}  ),
            .rdclk              (i_sys_clk                       ),
            .rdreq              (r_pkt_info_rd                  ),
            .wrclk              (i_sys_clk                       ),
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