`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/25 19:58:25
// Design Name: 
// Module Name: cell_ptr_linked_list_tb
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

//module cell_ptr_linked_list(
//    input clk, 
//    input rstn,
//    input[3:0] wr_en,
//    input[31:0] wr_din,
//    output reg [10:0] depth[3:0],
    
//    input[3:0] free_en
//    );
module cell_ptr_linked_list_tb;
reg clk, rstn;
always #5 clk = ~clk;


wire[10:0] depth_0;
wire[10:0] depth_1;
wire[10:0] depth_2;
wire[10:0] depth_3;
reg[3:0] wr_en;
reg[31:0] wr_din;
reg[3:0] free_en;
initial begin 
clk = 0;
rstn = 0;
wr_en = 0;
wr_din = 0;
free_en = 0;

#500;
rstn = 1;
#100;
repeat(1) @(posedge clk);
wr_en = 1;
wr_din = 111;

#100;
repeat(1) @(posedge clk);
wr_en = 2;
wr_din = 222;

#100;
repeat(1) @(posedge clk);
wr_en = 0;

#100;
repeat(1) @(posedge clk);
free_en = 1;


end



cell_ptr_linked_list cell_list(
    .clk(clk),
    .rstn(rstn),
    .wr_en(wr_en),
    .wr_din(wr_din),
    .depth_0(depth_0),
    .depth_1(depth_1),
    .depth_2(depth_2),
    .depth_3(depth_3),
    .free_en(free_en)
    );


endmodule
