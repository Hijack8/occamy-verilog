`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/18 11:12:07
// Design Name: 
// Module Name: switch_core_tb
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


module switch_core_tb;

//switch_core(
//input					clk,
//input					rstn,

//input		  [127:0]	i_cell_data_fifo_din,				
//input		 			i_cell_data_fifo_wr,					
//input		  [15:0]	i_cell_ptr_fifo_din,				
//input		 			i_cell_ptr_fifo_wr,					
//output	reg				i_cell_bp,

//output	reg				o_cell_fifo_wr,
//output	reg  [3:0]		o_cell_fifo_sel,
//output	     [127:0]	o_cell_fifo_din,
//output					o_cell_first,
//output					o_cell_last,
//input		 [3:0]		o_cell_bp
//    );


reg clk, rstn;
reg[127:0] data_in;
reg data_wr;
reg[15:0] ptr_in;
reg ptr_wr;
wire bp;

wire o_wr;
wire[3:0] o_sel;
wire[127:0] o_data;
wire o_first, o_last;
reg[3:0] o_bp;



switch_core core(
    .clk(clk),
    .rstn(rstn),
    .i_cell_data_fifo_din(data_in[127:0]),
    .i_cell_data_fifo_wr(data_wr),
    .i_cell_ptr_fifo_din(ptr_in[15:0]),
    .i_cell_ptr_fifo_wr(ptr_wr),
    .i_cell_bp(bp),
    .o_cell_fifo_wr(o_wr),
    .o_cell_fifo_sel(sel),
    .o_cell_fifo_din(o_data),
    .o_cell_first(o_first),
    .o_cell_last(o_last),
    .o_cell_bp(o_bp)
    );


initial begin
    clk = 0;
    rstn = 0;
    data_in = 0;
    data_wr = 0;
    ptr_in = 0;
    ptr_wr = 0;
    o_bp = 0;
    #500;
    rstn = 1;
    #500;
    send_frame(8, 4'b0001);
    #300;
    send_frame(8, 4'b0100);
    #300;
    send_frame(8, 4'b0010);
    #300;
    send_frame(8, 4'b1000);
end

always #5 clk = ~clk;

task send_frame;
input [5:0] cell_num;
input [3:0] port_map;
integer i;
begin
    repeat(1)@(posedge clk);
    #2;
    for(i = 0; i < cell_num * 4; i = i + 1) begin
        if(i == 0) begin
            ptr_in = {1'b0, port_map, 2'b0, cell_num};
            ptr_wr = 1;
            data_in = i + 1;
            data_wr = 1;
        end
        else if(i == 1) begin
            ptr_wr = 0;
            data_in = i + 1;
        end  
        else data_in = i + 1;
        repeat(1)@(posedge clk);
        #2;      
    end
    data_wr = 0;
    data_in = 0;
end

endtask


endmodule












