`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/23 15:19:48
// Design Name: 
// Module Name: switch_qc_tb
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
//module switch_qc(
//input					clk,
//input					rstn,

//input		  [15:0]	q_din,	
//input					q_wr,
//output					q_full,

//output					ptr_rdy,	
//input					ptr_ack,		
//output		  [15:0]	ptr_dout	
//    );


module switch_qc_tb;
    reg clk, rstn;
    reg[15:0] q_din;
    wire [15:0] ptr_dout;
    reg q_wr;
    wire q_full;
    wire ptr_rdy;
    reg ptr_ack;
    switch_qc qc(
        .clk(clk),
        .rstn(rstn),
        .q_din(q_din),
        .q_wr(q_wr),
        .q_full(q_full),
        .ptr_rdy(ptr_rdy),
        .ptr_ack(ptr_ack),
        .ptr_dout(ptr_dout)
        );
    always #5 clk = ~clk;
    initial begin
        clk = 0;
        rstn = 1;
        q_din = 0;
        q_wr = 0;
        ptr_ack = 0;
    end
    initial begin
        rstn = 0;
        #100;
        rstn = 1;
        #100;
        repeat(1) @(posedge clk);
        #2;
        q_din = 16'hf001;
        q_wr = 1;
        repeat(1) @(posedge clk);
        #2;
        q_din = 16'hf002;
        q_wr = 1;
        repeat(1) @(posedge clk);
        #2;
        q_din = 16'hf003;
        q_wr = 1;
        #1500;
        repeat(1) @(posedge clk);
        #2;
        q_wr = 0;
        ptr_ack = 1;
        repeat(1) @(posedge clk);
        #2;
        ptr_ack = 1;
        repeat(1) @(posedge clk);
        #2;
        ptr_ack = 0;
    end

endmodule













