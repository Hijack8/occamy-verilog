`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/22 14:44:11
// Design Name: 
// Module Name: statistics_tb
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

//module statistics(
//    input clk,
//    input rstn,
//    input in,
//    input out,
//    input [3:0] in_port,
//    input [3:0] out_port,
//    input[10:0] pkt_len_in,
//    input[10:0] pkt_len_out,
//    output reg [3:0] bitmap
//    );
module statistics_tb;
    reg clk, rstn;
    
    reg in, out;
    reg [3:0] in_port, out_port;
    reg [10:0] pkt_len_in, pkt_len_out;
    wire [3:0] bitmap;
    
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
    
    initial begin
        clk = 0;
        rstn = 1;
        in = 0;
        out = 0;
        in_port = 0;
        out_port = 0;
        pkt_len_in = 0;
        pkt_len_out = 0;
    end
    always #5 clk = ~clk;

    initial begin
        rstn = 0;
        #100;
        rstn = 1;
        #100;
        
        
        repeat(1) @(posedge clk);
        #2;
        in = 1;
        out = 0;
        pkt_len_in = 100;
        
        repeat(1) @(posedge clk);
        #2;
        in = 0;
        out = 1;
        pkt_len_out = 100;
        
        repeat(1) @(posedge clk);
        #2;
        in = 1;
        out = 0;
        pkt_len_in = 200;
        in_port = 2;
        
        repeat(1) @(posedge clk);
        #2;
        in = 1;
        out = 1;
        pkt_len_in = 200;
        pkt_len_out = 100;
        
        repeat(1) @(posedge clk);
        #2;
        in = 0;
        out = 0;
    end
    
endmodule






