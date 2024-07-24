`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/23 20:21:51
// Design Name: 
// Module Name: switch_qc_no_fifo
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


module switch_qc_no_fifo(
input					clk,
input					rstn,

input		  [15:0]	q_din,	
// write one
input					q_wr,
output					q_full,

output					ptr_rdy,
// read one	
input					ptr_ack,		
output		  [15:0]	ptr_dout	
    );



reg				ptr_rd;
reg	  [15:0]	ptr_fifo_din;
reg				ptr_rd_ack;

reg	  [15:0]	head;
reg	  [15:0]	tail;
reg	  [15:0]	depth_cell;
reg   			depth_flag;
reg	  [15:0]	depth_frame;

reg	  [15:0]	ptr_ram_din;
wire  [15:0]	ptr_ram_dout;
reg				ptr_ram_wr;
reg   [9:0]		ptr_ram_addr;

reg	  [3:0]		mstate;

assign ptr_dout = head;

wire [1:0] input_sig;
assign input_sig = {q_wr, ptr_ack};

always@(posedge clk or negedge rstn)
	if(!rstn)	begin
		mstate<=#2  0;
		ptr_ram_wr<=#2  0;
		ptr_wr_ack<=#2  0;
		head <=#2  0;	
		tail <=#2  0;	
		depth_cell <=#2  0;	
		depth_frame<=#2  0;
		ptr_rd_ack<=#2  0;
		ptr_ram_din<=#2  0;
		ptr_ram_addr<=#2  0;
		ptr_fifo_din<=#2  0;
		depth_flag<=#2 0;
		end
	else begin
        case(input_sig) 
        2'b00: begin
        
        end
        2'b01: begin
            ptr_ram_addr[9:0]<=#2 head[9:0];
            
        end
        2'b10: begin
        
        end
        2'b11: begin
        
        end
	end

always@(posedge clk or negedge rstn)
	if(!rstn)	begin
		mstate<=#2  0;
		ptr_ram_wr<=#2  0;
		ptr_wr_ack<=#2  0;
		head <=#2  0;	
		tail <=#2  0;	
		depth_cell <=#2  0;	
		depth_frame<=#2  0;
		ptr_rd_ack<=#2  0;
		ptr_ram_din<=#2  0;
		ptr_ram_addr<=#2  0;
		ptr_fifo_din<=#2  0;
		depth_flag<=#2 0;
		end
	else begin
		ptr_wr_ack<=#2  0;	
		ptr_rd_ack<=#2  0;	
		ptr_ram_wr<=#2  0;	
		case(mstate)					
		0:begin							
			if(ptr_wr)begin
				mstate<=#2  1;
				end
			else if(ptr_rd)
				begin					
				ptr_fifo_din<=#2  head;
				ptr_ram_addr[9:0]<=#2  head[9:0];
				mstate<=#2  3;
				end
		  end
		1:begin
			if(depth_cell[9:0])	begin	
				ptr_ram_wr<=#2  1;
				ptr_ram_addr[9:0]<=#2  tail[9:0];
				ptr_ram_din[15:0]<=#2  ptr_din[15:0];
				tail<=#2  ptr_din;
				end
			else begin
				ptr_ram_wr<=#2  1;			
				ptr_ram_addr[9:0]<=#2  ptr_din[9:0];
				ptr_ram_din[15:0]<=#2  ptr_din[15:0];
				tail<=#2  ptr_din;
				head<=#2  ptr_din;
				end	
			depth_cell<=#2 depth_cell+1;
			if(ptr_din[15])	begin		
				depth_flag<=#2 1;
				depth_frame<=#2 depth_frame+1;
				end
			ptr_wr_ack<=#2  1;				
			mstate<=#2  2;
			end
		2:begin
			ptr_ram_addr<=#2  tail[9:0];
			ptr_ram_din	<=#2  tail[15:0];
			ptr_ram_wr<=#2  1;
			mstate<=#2  0;
		  end
		3:begin
			ptr_rd_ack<=#2  1;				
			mstate<=#2  4;
		  end
		4:begin
			head<=#2  ptr_ram_dout;
			depth_cell<=#2 depth_cell-1;
			if(head[15]) begin
				depth_frame<=#2  depth_frame-1;
				if(depth_frame>1) depth_flag<=#2 1;
				else depth_flag<=#2 0;
				end
			mstate<=#2  0;
		  end
		endcase
	end
dp_sram_w16_d512 u_ptr_ram (
  .clka(clk), 			
  .wea(ptr_ram_wr),     
  .addra(ptr_ram_addr[8:0]), 
  .dina(ptr_ram_din),   
  .douta(ptr_ram_dout),
  .ena(1)
);	
endmodule
