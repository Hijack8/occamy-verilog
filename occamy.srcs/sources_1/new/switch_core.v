`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/18 10:25:48
// Design Name: 
// Module Name: switch_core
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module switch_core(
input					clk,
input					rstn,

input		  [127:0]	i_cell_data_fifo_din,				
input		 			i_cell_data_fifo_wr,					
input		  [15:0]	i_cell_ptr_fifo_din,				
input		 			i_cell_ptr_fifo_wr,					
output					i_cell_bp,

output	reg				o_cell_fifo_wr,
output	reg  [3:0]		o_cell_fifo_sel,
output	     [127:0]	o_cell_fifo_din,
output					o_cell_first,
output					o_cell_last,
input		 [3:0]		o_cell_bp
    );
wire 	[127:0]	sram_din_a;				
wire 	[127:0]	sram_dout_b;			
wire 	[11:0]	sram_addr_a;			
wire 	[11:0]	sram_addr_b;			
wire			sram_wr_a;				

			
reg  [15:0]		FQ_din;		
reg				FQ_wr;
wire				FQ_rd;

// ADD(PD)
reg [15:0]      FPDQ_din;
reg             FPDQ_wr;
wire             FPDQ_rd;

reg	 [1:0]		sram_cnt_b;
reg				sram_rd;	
reg				sram_rd_dv;
		
wire  [3:0]		qc_wr_ptr_wr_en;
wire			qc_ptr_full0;
wire			qc_ptr_full1;
wire			qc_ptr_full2;
wire			qc_ptr_full3;
reg				qc_ptr_full;
wire [9:0]		ptr_dout_s;		
wire  [15:0]		qc_wr_ptr_din;	
		
wire 			FQ_empty;
// ADD(PD)
wire  [3:0]		pd_qc_wr_ptr_wr_en;
wire			pd_qc_ptr_full0;
wire			pd_qc_ptr_full1;
wire			pd_qc_ptr_full2;
wire			pd_qc_ptr_full3;
reg				pd_qc_ptr_full;
wire [9:0]		pd_ptr_dout_s;		
wire  [127:0]		pd_qc_wr_ptr_din;	
wire            FPDQ_empty;

//wire[11:0]		MC_ram_addra;	
//wire [3:0]		MC_ram_dina;	
//reg	 			MC_ram_wra;		
//reg				MC_ram_wrb;		
//reg  [3:0]		MC_ram_dinb;	
//wire [3:0]		MC_ram_doutb;	

// For statistics
wire in;
reg out;
wire [3:0] in_port;
reg [3:0] out_port;
wire [10:0] pkt_len_in;
reg[10:0] pkt_len_out;
wire [3:0] bitmap;

admission ad(
    .clk(clk),
    .rstn(rstn),
    .data_in(i_cell_data_fifo_din),
    .data_wr(i_cell_data_fifo_wr),
    .FQ_rd(FQ_rd),
    .sram_addr(sram_addr_a),
    .sram_wr(sram_wr_a),
    .sram_din(sram_din_a),
    .qc_wr_ptr_wr_en(qc_wr_ptr_wr_en),
    .qc_wr_ptr_din(qc_wr_ptr_din),
//    .FQ_dout(FQ_dout),
    .FPDQ_rd(FPDQ_rd),
//    .FPDQ_dout(FPDQ_dout),
    .pd_qc_wr_ptr_wr_en(pd_qc_wr_ptr_wr_en),
    .pd_qc_wr_ptr_din(pd_qc_wr_ptr_din),
    .in(in),
    .in_port(in_port),
    .pkt_len_in(pkt_len_in),
    .bitmap(bitmap),
    .qc_ptr_full(qc_ptr_full),
    .pd_qc_ptr_full(pd_qc_ptr_full),
    .i_cell_bp(i_cell_bp),
    .ptr_dout_s(ptr_dout_s),
    .i_cell_ptr_fifo_din(i_cell_ptr_fifo_din),
    .i_cell_ptr_fifo_wr(i_cell_ptr_fifo_wr),
    .FQ_empty(FQ_empty),
    .FPDQ_empty(FPDQ_empty),
    .pd_ptr_dout_s(pd_ptr_dout_s)
    );
always@(posedge clk) begin
	qc_ptr_full<=#2 ({	qc_ptr_full3,qc_ptr_full2,qc_ptr_full1, qc_ptr_full0}==4'b0)?0:1;
    pd_qc_ptr_full<= #2 ({  pd_qc_ptr_full3, pd_qc_ptr_full2, pd_qc_ptr_full1, pd_qc_ptr_full0}  == 4'b0) ? 0: 1;
end

//assign MC_ram_addra= {2'b0,FQ_dout[9:0]};
//assign MC_ram_dina = qc_portmap[0]+qc_portmap[1]+qc_portmap[2]+qc_portmap[3];

reg  [3:0]		rd_state;
wire [15:0]		qc_rd_ptr_dout0,qc_rd_ptr_dout1,
                qc_rd_ptr_dout2,qc_rd_ptr_dout3;
                
wire [127:0]     pd_qc_rd_ptr_dout0, pd_qc_rd_ptr_dout1,
                pd_qc_rd_ptr_dout2, pd_qc_rd_ptr_dout3;

reg  [1:0]		RR;
reg  [3:0]		ptr_ack;
reg  [3:0]      pd_ptr_ack;
wire [3:0]		ptr_rd_req_pre;

wire			ptr_rdy0,ptr_rdy1,ptr_rdy2,ptr_rdy3;		
wire			ptr_ack0,ptr_ack1,ptr_ack2,ptr_ack3;

wire            pd_ptr_rdy0, pd_ptr_rdy1, pd_ptr_rdy2, pd_ptr_rdy3;
wire            pd_ptr_ack0, pd_ptr_ack1, pd_ptr_ack2, pd_ptr_ack3;

assign	ptr_rd_req_pre={ptr_rdy3,ptr_rdy2,ptr_rdy1,ptr_rdy0} & (~o_cell_bp);
assign	{ptr_ack3,ptr_ack2,ptr_ack1,ptr_ack0}=ptr_ack;
assign	sram_addr_b={FQ_din[9:0],sram_cnt_b[1:0]};
assign	o_cell_last=FQ_din[15];
assign	o_cell_first=FQ_din[14];
assign	o_cell_fifo_din[127:0]= sram_dout_b[127:0];

// ADD(PD)
wire [5:0] cell_num;
assign cell_num = FPDQ_din[15:10];
assign {pd_ptr_ack3, pd_ptr_ack2, pd_ptr_ack1, pd_ptr_ack0} = pd_ptr_ack;
assign pd_ptr_rd_req_pre = {pd_ptr_rdy3, pd_ptr_rdy2, pd_ptr_rdy1, pd_ptr_rdy0} & {~o_cell_bp};


reg [5:0]   cell_num_reg;

reg head_drop;
reg [3:0] head_drop_counter;

always@(posedge clk or negedge rstn)
	if(!rstn)begin
		rd_state<=#2  0;
		FQ_wr<=#2  0;
		FQ_din<=#2  0;
		FPDQ_wr<=#2 0;
		FPDQ_din<=#2 0;
//		MC_ram_wrb<=#2  0;
//		MC_ram_dinb<=#2  0;
		RR<=#2  0;
		ptr_ack<=#2  0;
		pd_ptr_ack<=#2 0;
		
		sram_rd<=#2  0;
		sram_rd_dv<=#2  0;
		sram_cnt_b<=#2  0;
		o_cell_fifo_wr<=#2  0;
		o_cell_fifo_sel<=#2  0;


        // ADD(PD)
        cell_num_reg <= 0;
        
        
        out<=#2 0;
        out_port<=#2 0;
        pkt_len_out<=#2 0;
        
        head_drop<=#2 0;
        head_drop_counter<=#2 0;
		end
	else begin
//		FQ_wr<=#2  0;
//		MC_ram_wrb<=#2  0;
		o_cell_fifo_wr<=#2 sram_rd;
		case(rd_state)
        6:begin
            pd_ptr_ack<=#2 0;

            FPDQ_wr<=#2 0;
            if(cell_num_reg == 0) begin
                cell_num_reg <=#2 cell_num;
            end
            rd_state<=#2 7;
            case(ptr_ack)
            4'b0001: FQ_din<=#2 qc_rd_ptr_dout0[15:0];
            4'b0010: FQ_din<=#2 qc_rd_ptr_dout1[15:0];
            4'b0100: FQ_din<=#2 qc_rd_ptr_dout2[15:0];
            4'b1000: FQ_din<=#2 qc_rd_ptr_dout3[15:0];
            endcase
        end	
        7:begin
            if(cell_num_reg == 2) begin
                rd_state<=#2 0;
                ptr_ack<=#2 0;
                cell_num_reg<=#2 0;
                FQ_wr<=#2 0;
            end
            else cell_num_reg <=#2 cell_num_reg - 1;
            
            case(ptr_ack)
            4'b0001: FQ_din<=#2 qc_rd_ptr_dout0[15:0];
            4'b0010: FQ_din<=#2 qc_rd_ptr_dout1[15:0];
            4'b0100: FQ_din<=#2 qc_rd_ptr_dout2[15:0];
            4'b1000: FQ_din<=#2 qc_rd_ptr_dout3[15:0];
            endcase 
        end
		0:begin
		    ptr_ack<=#2 0;
		    out<=#2 0;
			sram_rd<=#2  0;
			sram_cnt_b<=#2  0;
			if(ptr_rd_req_pre)	rd_state<=#2  1;	
			end
		1:begin
//			rd_state<=#2  2;
//			sram_rd<=#2  1;
            // In pkts
            if(cell_num_reg == 0) RR<=#2 RR+2'b01;
			case(RR)	
			0:begin							
				casex(ptr_rd_req_pre[3:0])  
				4'bxxx1:begin 
                    FQ_din<=#2  qc_rd_ptr_dout0; o_cell_fifo_sel<=#2  4'b0001; ptr_ack<=#2  4'b0001; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout0[15:0]; pd_ptr_ack<=#2 4'b0001;
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout0[26:16]; 
                        out_port <= #2 0;	
                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b0001) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end		
				end
				4'bxx10:begin 
                    FQ_din<=#2  qc_rd_ptr_dout1; o_cell_fifo_sel<=#2  4'b0010; ptr_ack<=#2  4'b0010; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout1[15:0]; pd_ptr_ack<=#2 4'b0010;
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout1[26:16]; 		
                        out_port <= #2 1;	

                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b0010) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end	
                end
				4'bx100:begin 
                    FQ_din<=#2  qc_rd_ptr_dout2; o_cell_fifo_sel<=#2  4'b0100; ptr_ack<=#2  4'b0100; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout2[15:0]; pd_ptr_ack<=#2 4'b0100; 
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout2[26:16];	
                        out_port <= #2 2;	
	
                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b0100) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				4'b1000:begin 
                    FQ_din<=#2  qc_rd_ptr_dout3; o_cell_fifo_sel<=#2  4'b1000; ptr_ack<=#2  4'b1000; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout3[15:0]; pd_ptr_ack<=#2 4'b1000; 	
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout3[26:16];		
                        out_port <= #2 3;	

                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b1000) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				endcase
			end
			1:begin
			    out<=#2 0;
				casex({ptr_rd_req_pre[0],ptr_rd_req_pre[3:1]})
				4'bxxx1:begin 
                    FQ_din<=#2  qc_rd_ptr_dout1; o_cell_fifo_sel<=#2  4'b0010; ptr_ack<=#2  4'b0010; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout1[15:0]; pd_ptr_ack<=#2 4'b0010; 	
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout1[26:16];		
                        out_port <= #2 1;	
                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b0010) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				4'bxx10:begin 
                    FQ_din<=#2  qc_rd_ptr_dout2; o_cell_fifo_sel<=#2  4'b0100; ptr_ack<=#2  4'b0100; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout2[15:0]; pd_ptr_ack<=#2 4'b0100; 
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout2[26:16];		
                        out_port <= #2 2;		

                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b0100) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				4'bx100:begin 
                    FQ_din<=#2  qc_rd_ptr_dout3; o_cell_fifo_sel<=#2  4'b1000; ptr_ack<=#2  4'b1000; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout3[15:0]; pd_ptr_ack<=#2 4'b1000; 		
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout3[26:16];		
                        out_port <= #2 3;

                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b1000) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end 
                end
				4'b1000:begin 
                    FQ_din<=#2  qc_rd_ptr_dout0; o_cell_fifo_sel<=#2  4'b0001; ptr_ack<=#2  4'b0001; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout0[15:0]; pd_ptr_ack<=#2 4'b0001;
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout0[26:16]; 				
                        out_port <= #2 0;

                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b0001) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				endcase
			end
			2:begin
				casex({ptr_rd_req_pre[1:0],ptr_rd_req_pre[3:2]})
				4'bxxx1:begin 
                    FQ_din<=#2  qc_rd_ptr_dout2; o_cell_fifo_sel<=#2  4'b0100; ptr_ack<=#2  4'b0100; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout2[15:0]; pd_ptr_ack<=#2 4'b0100; 		
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout2[26:16];		
                        out_port <= #2 2;
                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b0100) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				4'bxx10:begin 
                    FQ_din<=#2  qc_rd_ptr_dout3; o_cell_fifo_sel<=#2  4'b1000; ptr_ack<=#2  4'b1000; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout3[15:0]; pd_ptr_ack<=#2 4'b1000; 		
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout3[26:16];		
                        out_port <= #2 3;

                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b1000) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				4'bx100:begin 
                    FQ_din<=#2  qc_rd_ptr_dout0; o_cell_fifo_sel<=#2  4'b0001; ptr_ack<=#2  4'b0001; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout0[15:0]; pd_ptr_ack<=#2 4'b0001; 		
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout0[26:16];		
                        out_port <= #2 0;

                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b0001) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				4'b1000:begin 
                    FQ_din<=#2  qc_rd_ptr_dout1; o_cell_fifo_sel<=#2  4'b0010; ptr_ack<=#2  4'b0010; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout1[15:0]; pd_ptr_ack<=#2 4'b0010; 	
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout1[26:16];			
                        out_port <= #2 1;

                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b0010) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				endcase
			end
			3:begin
				casex({ptr_rd_req_pre[2:0],ptr_rd_req_pre[3]})
				4'bxxx1:begin 
                    FQ_din<=#2  qc_rd_ptr_dout3; o_cell_fifo_sel<=#2  4'b1000; ptr_ack<=#2  4'b1000; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout3[15:0]; pd_ptr_ack<=#2 4'b1000; 				
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout3[26:16];	
                        out_port <= #2 3;

                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b1000) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				4'bxx10:begin 
                    FQ_din<=#2  qc_rd_ptr_dout0; o_cell_fifo_sel<=#2  4'b0001; ptr_ack<=#2  4'b0001; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout0[15:0]; pd_ptr_ack<=#2 4'b0001; 			
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout0[26:16];		
                        out_port <= #2 0;

                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b0001) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				4'bx100:begin 
                    FQ_din<=#2  qc_rd_ptr_dout1; o_cell_fifo_sel<=#2  4'b0010; ptr_ack<=#2  4'b0010; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout1[15:0]; pd_ptr_ack<=#2 4'b0010; 				
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout1[26:16];	
                        out_port <= #2 1;
                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b0010) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				4'b1000:begin 
                    FQ_din<=#2  qc_rd_ptr_dout2; o_cell_fifo_sel<=#2  4'b0100; ptr_ack<=#2  4'b0100; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout2[15:0]; pd_ptr_ack<=#2 4'b0100; 				
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout2[26:16];	
                        out_port <= #2 2;

                    end
                    if(cell_num_reg == 0 &&(bitmap & 4'b0100) == 0) begin
                        // headdrop
                        rd_state <=#2 6;
                    end	
                    else begin
                        rd_state <=#2 2;
                        sram_rd<=#2  1;
                    end
                end
				endcase
				end
			endcase
			FQ_wr<=#2 1;
			FPDQ_wr<=#2 1;
			end
		2:begin
		    FQ_wr<=#2 0;
			FPDQ_wr<=#2 0;
			ptr_ack<=#2  0;
            if(cell_num_reg == 0) cell_num_reg<=#2 cell_num;
            pd_ptr_ack<=#2 0;
			sram_cnt_b<=#2  sram_cnt_b+1;
			rd_state<=#2  3;
		  end
		3:begin
			sram_cnt_b<=#2  sram_cnt_b+1;
//			MC_ram_wrb<=#2  1;
//			if(MC_ram_doutb==1)	
//				begin
//				MC_ram_dinb<=#2  0;
				FQ_wr<=#2  1;
                FPDQ_wr<=#2 1;
//				end
//			else
//				MC_ram_dinb<=#2  MC_ram_doutb-1;
			rd_state<=#2  4;
		  end
		4:begin
			sram_cnt_b<=#2  sram_cnt_b+1;
			rd_state<=#2  5;
		  end
		5:begin
			sram_rd<=#2  0;
            cell_num_reg<= #2 cell_num_reg - 1;
			
			if(cell_num_reg == 1) begin
			     out<=#2 1;
			end
			if(ptr_rd_req_pre)	begin 
			    rd_state<=#2  1;
			    sram_cnt_b<=#2  0;		    
			    sram_rd<=#2  0;
			end
			else rd_state<=#2  0;
		  end
		default:rd_state<=#2  0;
		endcase
		end

//reg [15:0]last_ptr;
//reg [3:0] RR_state;
//// For pipeline
//always@(posedge clk or negedge rstn) begin
//    if(!rstn) begin 
//        last_ptr<=#2 0;
//        RR_state<=#2 0;
//    end
//    else begin
//        case(RR_state)
//        0: begin
//        end
//        1: begin
//        end
//        endcase
//    end
//end



multi_user_fq u_fq (
	.clk(clk), 
	.rstn(rstn), 
	.ptr_din({6'b0,FQ_din[9:0]}), 
	.FQ_wr(FQ_wr), 
	.FQ_rd(FQ_rd), 
	.ptr_dout_s(ptr_dout_s), 
	.ptr_fifo_empty(FQ_empty)
);

multi_user_fpdq u_fpdq(
	.clk(clk), 
	.rstn(rstn), 
	.ptr_din({6'b0,FPDQ_din[9:0]}), 
	.FQ_wr(FPDQ_wr), 
	.FQ_rd(FPDQ_rd), 
	.ptr_dout_s(pd_ptr_dout_s), 
	.ptr_fifo_empty(FPDQ_empty)
);

//dpsram_w4_d512 u_MC_dpram (
//  .clka(clk), 				
//  .wea(MC_ram_wra), 		
//  .addra(MC_ram_addra[8:0]), 	
//  .dina(MC_ram_dina), 		
//  .douta(), 				
//  .clkb(clk), 				
//  .web(MC_ram_wrb), 		
//  .addrb(FQ_din[8:0]), 	
//  .dinb(MC_ram_dinb), 		
//  .doutb(MC_ram_doutb),
//  .ena(1),
//  .enb(1)
//);

switch_qc qc0(
	.clk(clk), 
	.rstn(rstn), 
	.q_din(qc_wr_ptr_din), 
	.q_wr(qc_wr_ptr_wr_en[0]), 
	.q_full(qc_ptr_full0), 
	.ptr_rdy(ptr_rdy0),
	.ptr_ack(ptr_ack0),
	.ptr_dout(qc_rd_ptr_dout0)
);

switch_qc qc1(
	.clk(clk), 
	.rstn(rstn), 
	
	.q_din(qc_wr_ptr_din), 
	.q_wr(qc_wr_ptr_wr_en[1]), 
	.q_full(qc_ptr_full1), 
	
	.ptr_rdy(ptr_rdy1),
	.ptr_ack(ptr_ack1),
	.ptr_dout(qc_rd_ptr_dout1)
);

switch_qc qc2(
	.clk(clk), 
	.rstn(rstn), 
	
	.q_din(qc_wr_ptr_din), 
	.q_wr(qc_wr_ptr_wr_en[2]), 
	.q_full(qc_ptr_full2), 
	
	.ptr_rdy(ptr_rdy2),
	.ptr_ack(ptr_ack2),
	.ptr_dout(qc_rd_ptr_dout2)
);

switch_qc qc3(
	.clk(clk), 
	.rstn(rstn), 
	
	.q_din(qc_wr_ptr_din), 
	.q_wr(qc_wr_ptr_wr_en[3]), 
	.q_full(qc_ptr_full3), 
	
	.ptr_rdy(ptr_rdy3),
	.ptr_ack(ptr_ack3),
	.ptr_dout(qc_rd_ptr_dout3)
);

switch_pd_qc pd_qc0(
    .clk(clk),
    .rstn(rstn),
    .q_din(pd_qc_wr_ptr_din),
    .q_wr(pd_qc_wr_ptr_wr_en[0]),
    .q_full(pd_qc_ptr_full0), 
	
	.ptr_rdy(pd_ptr_rdy0),
	.ptr_ack(pd_ptr_ack0),
	.ptr_dout(pd_qc_rd_ptr_dout0)
);

switch_pd_qc pd_qc1(
    .clk(clk),
    .rstn(rstn),
    .q_din(pd_qc_wr_ptr_din),
    .q_wr(pd_qc_wr_ptr_wr_en[1]),
    .q_full(pd_qc_ptr_full1), 
	
	.ptr_rdy(pd_ptr_rdy1),
	.ptr_ack(pd_ptr_ack1),
	.ptr_dout(pd_qc_rd_ptr_dout1)
);

switch_pd_qc pd_qc2(
    .clk(clk),
    .rstn(rstn),
    .q_din(pd_qc_wr_ptr_din),
    .q_wr(pd_qc_wr_ptr_wr_en[2]),
    .q_full(pd_qc_ptr_full2), 
	
	.ptr_rdy(pd_ptr_rdy2),
	.ptr_ack(pd_ptr_ack2),
	.ptr_dout(pd_qc_rd_ptr_dout2)
);

switch_pd_qc pd_qc3(
    .clk(clk),
    .rstn(rstn),
    .q_din(pd_qc_wr_ptr_din),
    .q_wr(pd_qc_wr_ptr_wr_en[3]),
    .q_full(pd_qc_ptr_full3), 
	
	.ptr_rdy(pd_ptr_rdy3),
	.ptr_ack(pd_ptr_ack3),
	.ptr_dout(pd_qc_rd_ptr_dout3)
);

dpsram_w128_d2k u_data_ram (
  .clka(clk), 			
  .wea(sram_wr_a), 		
  .addra(sram_addr_a[10:0]),	
  .dina(sram_din_a), 	
  .douta(), 			
  .clkb(clk), 		
  .web(1'b0), 			
  .addrb(sram_addr_b[10:0]), 	
  .dinb(128'b0),
  .ena(1),
  .enb(1), 		
  .doutb(sram_dout_b) 	
);


statistics sts(
    .clk(clk),
    .rstn(rstn),
    .in(in),
    .out(out),
    .in_port(in_port),
    .out_port(out_port),
    .pkt_len_in(pkt_len_in),
    .pkt_len_out(pkt_len_out),
    .bitmap(bitmap)
    );
endmodule
