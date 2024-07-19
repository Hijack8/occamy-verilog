`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/18 10:28:52
// Design Name: 
// Module Name: multi_user_fq
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

module multi_user_fq(
input					clk,
input					rstn,

input		  [15:0]	ptr_din,
input					FQ_wr,
input					FQ_rd,
output		  [9:0]		ptr_dout_s,
output		  			ptr_fifo_empty
    );
reg	  [2:0]		FQ_state;
reg	  [9:0]		addr_cnt;
reg	  [9:0]		ptr_fifo_din;
reg				ptr_fifo_wr;
		
always@(posedge clk or negedge rstn)
	if(!rstn)
		begin
		FQ_state<=#2 0;
		addr_cnt<=#2 0;
		ptr_fifo_wr<=#2 0;
		end
	else
		begin
		ptr_fifo_wr<=#2 0;
		ptr_fifo_din<=#2 ptr_din[9:0];
		case(FQ_state)
		0:FQ_state<=#2 1;
		1:FQ_state<=#2 2;
		2:FQ_state<=#2 3;
		3:FQ_state<=#2 4;
		4:begin				
			ptr_fifo_din<=#2 addr_cnt;
			if(addr_cnt<10'h1ff) 		
				addr_cnt<=#2 addr_cnt+1;
			if(ptr_fifo_din<10'h1ff)	
				ptr_fifo_wr<=#2 1;
			else begin
				FQ_state<=#2 5;
				ptr_fifo_wr<=#2 0;
				end
			end
		5:begin								
			if(FQ_wr)ptr_fifo_wr<=#2 1;
			end
		endcase
	end

sfifo_ft_w10_d512 u_ptr_fifo(
	.clk(clk),
	.rst(!rstn),
	.din(ptr_fifo_din[9:0]),
	.wr_en(ptr_fifo_wr),
	.rd_en(FQ_rd),
	.dout(ptr_dout_s[9:0]),
	.empty(ptr_fifo_empty),
	.full(),
	.data_count()	
	);

endmodule
