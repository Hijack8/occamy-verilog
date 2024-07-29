`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/22 13:38:31
// Design Name: 
// Module Name: switch_pd_qc
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


module switch_pd_qc(
input					clk,
input					rstn,

input		  [127:0]	q_din,	
input					q_wr,
output					q_full,

output					ptr_rdy,	
input					ptr_ack,		
output		  [127:0]	ptr_dout	
    );

assign q_full = 0;

reg	  [127:0]	ptr_fifo_din;
reg				ptr_rd_ack;

reg	  [127:0]	head;
reg	  [127:0]	tail;
reg	  [15:0]	depth_cell;
reg   			depth_flag;
reg	  [15:0]	depth_frame;

reg	  [127:0]	ptr_ram_din;
wire  [127:0]	ptr_ram_dout;
reg				ptr_ram_wr;
reg   [9:0]		ptr_ram_addr;

reg [127:0] ptr_ram_din_b;
wire[127:0] ptr_ram_dout_b;
reg ptr_ram_wr_b;
reg [9:0] ptr_ram_addr_b;


wire [1:0] sig;
assign sig = {q_wr, ptr_ack};
assign ptr_dout = head;
assign ptr_rdy = (depth_cell > 0);

always@(posedge clk or negedge rstn)
	if(!rstn)	begin
		ptr_ram_wr<=#2  0;
		head <=#2  0;	
		tail <=#2  0;	
		depth_cell <=#2  0;	
		depth_frame<=#2  0;
		ptr_rd_ack<=#2  0;
		ptr_ram_din<=#2  0;
		ptr_ram_addr<=#2  0;
		ptr_fifo_din<=#2  0;
		depth_flag<=#2 0;
		
		ptr_ram_din_b<=#2 0;
	    ptr_ram_wr_b<=#2 0;
	    ptr_ram_addr_b<=#2 0;
	    
		end
	else begin
	    ptr_ram_addr_b[9:0]<=#2  head[9:0];
        case(sig)
        2'b00: begin
            ptr_ram_wr<=#2  0;
        end
        2'b01: begin
            // read
			head<=#2  ptr_ram_dout_b;
			depth_cell<=#2 depth_cell-1;
			if(head[15]) begin
				depth_frame<=#2  depth_frame-1;
				if(depth_frame>1) depth_flag<=#2 1;
				else depth_flag<=#2 0;
				end
        end
        2'b10: begin
            // write
            if(depth_cell[9:0])	begin	
				ptr_ram_wr<=#2  1;
				ptr_ram_addr[9:0]<=#2  tail[9:0];
				ptr_ram_din[127:0]<=#2  q_din[127:0];
				tail<=#2  q_din;
				end
			else begin
				ptr_ram_wr<=#2  1;			
				ptr_ram_addr[9:0]<=#2  q_din[9:0];
				ptr_ram_din[127:0]<=#2  q_din[127:0];
				tail<=#2  q_din;
				head<=#2  q_din;
				end	
			depth_cell<=#2 depth_cell+1;
			if(q_din[15])	begin		
				depth_flag<=#2 1;
				depth_frame<=#2 depth_frame+1;
				end
        end
        2'b11: begin
            // read && write
            if(depth_cell[9:0]) begin
				ptr_ram_wr<=#2  1;
				ptr_ram_addr[9:0]<=#2  tail[9:0];
				ptr_ram_din[127:0]<=#2  q_din[127:0];
				tail<=#2  q_din;
			    if(q_din[15])	begin		
                    depth_flag<=#2 1;
                    depth_frame<=#2 depth_frame+1;
                    end
                
                head<=#2  ptr_ram_dout_b;
                depth_cell<=#2 depth_cell-1;
                if(head[15]) begin
                    depth_frame<=#2  depth_frame-1;
                    if(depth_frame>1) depth_flag<=#2 1;
                    else depth_flag<=#2 0;
                    end
            end 
            else begin
                ptr_ram_wr<=#2 0;
                head<=#2 q_din;
            end
        end
		endcase
		end

dpsram_w128_d512 u_ptr_ram (
  .clka(clk), 			
  .wea(ptr_ram_wr),     
  .addra(ptr_ram_addr[8:0]), 
  .dina(ptr_ram_din),   
  .douta(ptr_ram_dout),
  .ena(1),
  .clkb(clk),
  .web(ptr_ram_wr_b),
  .addrb(ptr_ram_addr_b),
  .dinb(ptr_ram_din_b),
  .doutb(ptr_ram_dout_b),
  .enb(1)
);		
endmodule

