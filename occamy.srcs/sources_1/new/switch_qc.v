`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/18 10:30:15
// Design Name: 
// Module Name: switch_qc
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

module switch_qc(
input					clk,
input					rstn,

input		  [15:0]	q_din,	
input					q_wr,
output					q_full,

output					ptr_rdy,	
input					ptr_ack,		
output		  [15:0]	ptr_dout,

output reg [15:0] frame_head,

//input roll_back
input headdrop,
output reg headdrop_buzy

//output   reg  [15:0]    FQ_din,
//output   reg            FQ_wr	
    );

assign q_full = 0;

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

reg [15:0] ptr_ram_din_b;
wire[15:0] ptr_ram_dout_b;
reg ptr_ram_wr_b;
reg [9:0] ptr_ram_addr_b;


wire [1:0] sig;
assign sig = {q_wr, ptr_ack};
assign ptr_dout = head;
assign ptr_rdy = depth_flag;
reg [3:0] state;
reg in_frame;
reg [15:0] next_head;
reg read_one;

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
	    
	    frame_head<=#2 0;
        in_frame<=#2 0;
        
        
        read_one<=#2 0;
//	    FQ_din<=#2 0;
//	    FQ_wr<=#2 0;
		end
	else begin
	   // while read, delay 1 cycle
	   if(read_one) begin
            #2 head<=#2 ptr_ram_dout_b;
            if(head[15]) begin
	    		depth_frame<=#2  depth_frame-1;
                in_frame<=#2 0;
	    		if(depth_frame>1) depth_flag<=#2 1;
	    		else depth_flag<=#2 0;
	    	end	   
	    	else begin
                in_frame<=#2 1;
            end
            if(ptr_ram_dout_b[14]) begin
	    	    frame_head<=#2 ptr_ram_dout_b; 
	    	end
	    	if(!sig[0])
	    	  read_one<=#2 0;
	   end
	
        case(sig)
        2'b00: begin
            ptr_ram_wr<=#2  0;
        end
        2'b01: begin
            // read
            read_one<=#2 1;
            ptr_ram_addr_b[9:0]<=#2 head[9:0];
            ptr_ram_wr<=#2 0;
            depth_cell<=#2 depth_cell-1;
        end
        2'b10: begin
            // write
//            FQ_wr<=#2 0;
            if(depth_cell[9:0])	begin	
				ptr_ram_wr<=#2  1;
				ptr_ram_addr[9:0]<=#2  tail[9:0];
				ptr_ram_din[15:0]<=#2  q_din[15:0];
				tail<=#2  q_din;
				end
			else begin
				ptr_ram_wr<=#2  1;			
				ptr_ram_addr[9:0]<=#2  q_din[9:0];
				ptr_ram_din[15:0]<=#2  q_din[15:0];
				tail<=#2  q_din;
				head<=#2  q_din;
				// cannot change head
				next_head<=#2 q_din;
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
				ptr_ram_din[15:0]<=#2  q_din[15:0];
				tail<=#2  q_din;
			    if(q_din[15])	begin		
                    depth_flag<=#2 1;
                    depth_frame<=#2 depth_frame+1;
                    end
                read_one<=#2 1;
                
                ptr_ram_addr_b[9:0]<=#2 head[9:0];
            end 
            else begin
//                FQ_wr<=#2 0;
                ptr_ram_wr<=#2 0;
                head<=#2 q_din;
            end
        end
		endcase
		end


reg[3:0] headdrop_state;
reg[15:0] headdrop_head;

always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
        headdrop_state<=#2 0;
        headdrop_head<=#2 0;
        headdrop_buzy<=#2 0;
    end 
    else begin
        case(headdrop_state) 
        0: begin
            if(headdrop && ptr_rdy && !ptr_ack) begin
                headdrop_head<=#2 head; 
                headdrop_buzy <=#2 1;
                headdrop_state<=#2 1;
            end
        end
        1: begin
            if(ptr_ack) headdrop_state<=#2 0;
            else begin
                headdrop_head<=#2 ptr_ram_dout_b;
                if(ptr_ram_dout_b[15]) begin
                    headdrop_state<=#2 2;
                end 
            end
        end
        2: begin
            if(ptr_ack) headdrop_state<=#2 0;
            else begin
                headdrop_buzy<=#2 0;
                head<=#2 ptr_ram_dout_b;
                headdrop_state<=#2 0;
            end
        end
        endcase
    end
end


dpsram_w16_d512 u_ptr_ram (
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
