`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/29 10:07:56
// Design Name: 
// Module Name: cell_read
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


module cell_read(
    input clk,
    input rstn,
    input [3:0] ptr_rdy,
    output reg[3:0] ptr_ack,
    input [63:0]ptr_dout,
    output reg FQ_wr,
    output [15:0] ptr_din,
    
    input [3:0] pd_ptr_rdy,
    output reg[3:0] pd_ptr_ack,
    input [511:0]pd_ptr_dout,
    output reg FPDQ_wr,
    output [15:0] pd_ptr_din,
    
    output [11:0] sram_addr_b,
    input [127:0] sram_dout_b,
    
    
    output o_cell_last,
    output o_cell_first,
    
    output  [127:0] o_cell_fifo_din,
    output reg o_cell_fifo_wr,
    output reg [3:0] o_cell_fifo_sel,
    
    output reg out,
    output reg[3:0] out_port,
    output reg[10:0] pkt_len_out
    );
reg  [3:0]		rd_state;
wire [15:0]		qc_rd_ptr_dout0,qc_rd_ptr_dout1,
                qc_rd_ptr_dout2,qc_rd_ptr_dout3;
                
wire [127:0]     pd_qc_rd_ptr_dout0, pd_qc_rd_ptr_dout1,
                pd_qc_rd_ptr_dout2, pd_qc_rd_ptr_dout3;

reg  [1:0]		RR;
wire [3:0]		ptr_rd_req_pre;

reg  [15:0]		FQ_din;	
reg [15:0]      FPDQ_din;

reg	 [1:0]		sram_cnt_b;
assign	ptr_rd_req_pre=ptr_rdy;
assign	{ptr_ack3,ptr_ack2,ptr_ack1,ptr_ack0}=ptr_ack;
assign	sram_addr_b={FQ_din[9:0],sram_cnt_b[1:0]};
assign	o_cell_last=FQ_din[15];
assign	o_cell_first=FQ_din[14];
assign	o_cell_fifo_din[127:0]= sram_dout_b[127:0];
assign ptr_din = FQ_din;
assign pd_ptr_din = FPDQ_din;

wire [5:0] cell_num;
assign cell_num = FPDQ_din[15:10];
assign {pd_ptr_ack3, pd_ptr_ack2, pd_ptr_ack1, pd_ptr_ack0} = pd_ptr_ack;
assign pd_ptr_rd_req_pre = pd_ptr_rdy;



assign {qc_rd_ptr_dout3, qc_rd_ptr_dout2, qc_rd_ptr_dout1, qc_rd_ptr_dout0} = ptr_dout;
assign {pd_qc_rd_ptr_dout3, pd_qc_rd_ptr_dout2, pd_qc_rd_ptr_dout1, pd_qc_rd_ptr_dout0} = pd_ptr_dout;



reg [5:0]   cell_num_reg;

reg sram_rd;
reg sram_rd_dv;

reg head_drop;
reg [3:0] head_drop_counter;
always@(posedge clk or negedge rstn)
	if(!rstn)begin
		rd_state<=#2  0;
		FQ_wr<=#2  0;
		FQ_din<=#2  0;
		FPDQ_wr<=#2 0;
		FPDQ_din<=#2 0;
		RR<=#2  0;
		ptr_ack<=#2  0;
		pd_ptr_ack<=#2 0;
		
		sram_rd<=#2  0;
		sram_rd_dv<=#2  0;
		sram_cnt_b<=#2  0;
		o_cell_fifo_wr<=#2  0;
		o_cell_fifo_sel<=#2  0;

        cell_num_reg <= 0;
        
        out<=#2 0;
        out_port<=#2 0;
        pkt_len_out<=#2 0;
		end
	else begin
		o_cell_fifo_wr<=#2 sram_rd;
		case(rd_state)
		0:begin
		    ptr_ack<=#2 0;
		    out<=#2 0;
			sram_rd<=#2  0;
			sram_cnt_b<=#2  0;
			if(ptr_rd_req_pre)	rd_state<=#2  1;	
			end
		1:begin
			rd_state<=#2  2;
			
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
                        out_port <= #2 0;	FPDQ_wr<=#2 1;
                    end
				end
				4'bxx10:begin 
                    FQ_din<=#2  qc_rd_ptr_dout1; o_cell_fifo_sel<=#2  4'b0010; ptr_ack<=#2  4'b0010; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout1[15:0]; pd_ptr_ack<=#2 4'b0010;
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout1[26:16]; 		
                        out_port <= #2 1;	FPDQ_wr<=#2 1;

                    end
                end
				4'bx100:begin 
                    FQ_din<=#2  qc_rd_ptr_dout2; o_cell_fifo_sel<=#2  4'b0100; ptr_ack<=#2  4'b0100; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout2[15:0]; pd_ptr_ack<=#2 4'b0100; 
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout2[26:16];	
                        out_port <= #2 2;	FPDQ_wr<=#2 1;
	
                    end
                end
				4'b1000:begin 
                    FQ_din<=#2  qc_rd_ptr_dout3; o_cell_fifo_sel<=#2  4'b1000; ptr_ack<=#2  4'b1000; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout3[15:0]; pd_ptr_ack<=#2 4'b1000; 	
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout3[26:16];		
                        out_port <= #2 3;	FPDQ_wr<=#2 1;

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
                        out_port <= #2 1;	FPDQ_wr<=#2 1;
                    end
                end
				4'bxx10:begin 
                    FQ_din<=#2  qc_rd_ptr_dout2; o_cell_fifo_sel<=#2  4'b0100; ptr_ack<=#2  4'b0100; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout2[15:0]; pd_ptr_ack<=#2 4'b0100; 
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout2[26:16];		
                        out_port <= #2 2;	FPDQ_wr<=#2 1;	

                    end
                end
				4'bx100:begin 
                    FQ_din<=#2  qc_rd_ptr_dout3; o_cell_fifo_sel<=#2  4'b1000; ptr_ack<=#2  4'b1000; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout3[15:0]; pd_ptr_ack<=#2 4'b1000; 		
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout3[26:16];		
                        out_port <= #2 3;   FPDQ_wr<=#2 1;

                    end
                end
				4'b1000:begin 
                    FQ_din<=#2  qc_rd_ptr_dout0; o_cell_fifo_sel<=#2  4'b0001; ptr_ack<=#2  4'b0001; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout0[15:0]; pd_ptr_ack<=#2 4'b0001;
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout0[26:16]; 				
                        out_port <= #2 0;   FPDQ_wr<=#2 1;

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
                        out_port <= #2 2;   FPDQ_wr<=#2 1;
                    end
                end
				4'bxx10:begin 
                    FQ_din<=#2  qc_rd_ptr_dout3; o_cell_fifo_sel<=#2  4'b1000; ptr_ack<=#2  4'b1000; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout3[15:0]; pd_ptr_ack<=#2 4'b1000; 		
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout3[26:16];		
                        out_port <= #2 3;   FPDQ_wr<=#2 1;

                    end
                end
				4'bx100:begin 
                    FQ_din<=#2  qc_rd_ptr_dout0; o_cell_fifo_sel<=#2  4'b0001; ptr_ack<=#2  4'b0001; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout0[15:0]; pd_ptr_ack<=#2 4'b0001; 		
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout0[26:16];		
                        out_port <= #2 0;   FPDQ_wr<=#2 1;

                    end
                end
				4'b1000:begin 
                    FQ_din<=#2  qc_rd_ptr_dout1; o_cell_fifo_sel<=#2  4'b0010; ptr_ack<=#2  4'b0010; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout1[15:0]; pd_ptr_ack<=#2 4'b0010; 	
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout1[26:16];			
                        out_port <= #2 1;   FPDQ_wr<=#2 1;

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
                        out_port <= #2 3;   FPDQ_wr<=#2 1;

                    end
                end
				4'bxx10:begin 
                    FQ_din<=#2  qc_rd_ptr_dout0; o_cell_fifo_sel<=#2  4'b0001; ptr_ack<=#2  4'b0001; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout0[15:0]; pd_ptr_ack<=#2 4'b0001; 			
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout0[26:16];		
                        out_port <= #2 0;   FPDQ_wr<=#2 1;

                    end
                end
				4'bx100:begin 
                    FQ_din<=#2  qc_rd_ptr_dout1; o_cell_fifo_sel<=#2  4'b0010; ptr_ack<=#2  4'b0010; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout1[15:0]; pd_ptr_ack<=#2 4'b0010; 				
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout1[26:16];	
                        out_port <= #2 1;   FPDQ_wr<=#2 1;
                    end
                end
				4'b1000:begin 
                    FQ_din<=#2  qc_rd_ptr_dout2; o_cell_fifo_sel<=#2  4'b0100; ptr_ack<=#2  4'b0100; 
                    if(cell_num_reg == 0) begin
                        FPDQ_din<=#2 pd_qc_rd_ptr_dout2[15:0]; pd_ptr_ack<=#2 4'b0100; 				
                        pkt_len_out<=#2 pd_qc_rd_ptr_dout2[26:16];	
                        out_port <= #2 2;   FPDQ_wr<=#2 1;

                    end
                end
				endcase
				end
			endcase
			FQ_wr<=#2 1;
			
			end
		2:begin
		    sram_rd<=#2  1;
		    case(ptr_ack)
		    4'b0001: FQ_din<=#2 qc_rd_ptr_dout0;
		    4'b0010: FQ_din<=#2 qc_rd_ptr_dout1;
		    4'b0100: FQ_din<=#2 qc_rd_ptr_dout2;
		    4'b1000: FQ_din<=#2 qc_rd_ptr_dout3;
		    endcase
		    FQ_wr<=#2 1;
			FPDQ_wr<=#2 0;
			ptr_ack<=#2  0;
            if(cell_num_reg == 0) cell_num_reg<=#2 cell_num;
            pd_ptr_ack<=#2 0;
			sram_cnt_b<=#2  0;
			rd_state<=#2  3;
		  end
		3:begin
		    FQ_wr<=#2 0;
			sram_cnt_b<=#2  sram_cnt_b+1;
			rd_state<=#2  4;
		  end
		4:begin
			sram_cnt_b<=#2  sram_cnt_b+1;
			rd_state<=#2  5;
		  end
		5:begin
			sram_cnt_b<=#2  sram_cnt_b+1;
			rd_state<=#2  6;
		  end
		6:begin
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
    
endmodule
