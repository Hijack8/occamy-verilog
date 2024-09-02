`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/02 09:53:08
// Design Name: 
// Module Name: tb_statistics
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


module tb_statistics();

reg clk, rstn;
reg in, out, headdrop_out;
reg [3:0] in_port, out_port, headdrop_out_port;
reg [10:0] pkt_len_in, pkt_len_out, headdrop_pkt_len_out;

wire [3:0] bitmap;

statistics sts(
    .clk(clk),
    .rstn(rstn),
    .in(in),
    .out(out),
    .in_port(in_port),
    .out_port(out_port),
    .pkt_len_out(pkt_len_out),
    .pkt_len_in(pkt_len_in),

    .headdrop_out(headdrop_out),
    .headdrop_out_port(headdrop_out_port),
    .headdrop_pkt_len_out(headdrop_pkt_len_out),

    .bitmap(bitmap)
);

real CYCLE = 10;
always begin 
    clk = 0; #(CYCLE / 2);
    clk = 1; #(CYCLE / 2);
end

initial begin 
    rstn = 1'b1;
    in = 0; out = 0; 
    headdrop_out = 0; 
    in_port = 0; 
    out_port = 0;
    headdrop_out_port = 0;
    pkt_len_in = 0; 
    pkt_len_out = 0;
    headdrop_pkt_len_out = 0;
    #18 rstn = 1'b0;
    #18 rstn = 1'b1;

    #102;
    in = 1; in_port = 0; pkt_len_in = 100;
    repeat(1)@(posedge clk);
    in = 0; 

    #102;
    in = 1; in_port = 0; pkt_len_in = 200; out = 1; out_port = 0; pkt_len_out = 100;
    repeat(1)@(posedge clk);
    in = 0; out = 0;

    #102; 
    in = 1; in_port = 0; pkt_len_in = 100;
    repeat(1)@(posedge clk);
    in = 0; 

    #102; 
    in = 1; in_port = 0; pkt_len_in = 100;
    repeat(1)@(posedge clk);
    in = 0; 

    #102; 
    in = 1; in_port = 0; pkt_len_in = 100;
    repeat(1)@(posedge clk);
    in = 0; 

    #102; 
    out = 1; out_port = 0; pkt_len_out = 100; 
    headdrop_out = 1; headdrop_out_port = 0; headdrop_pkt_len_out = 100; 
    repeat(1)@(posedge clk);
    out = 0; headdrop_out = 0;

    #102; 
    out = 1; out_port = 0; pkt_len_out = 100; 
    headdrop_out = 1; headdrop_out_port = 0; headdrop_pkt_len_out = 100; 
    repeat(1)@(posedge clk);
    out = 0; headdrop_out = 0;

    #102; 
    out = 1; out_port = 0; pkt_len_out = 100;
    repeat(1)@(posedge clk);
    out = 0;

    #102; 
    in = 1; in_port = 1; out = 1; out_port = 1; pkt_len_in = 1024 + 64; pkt_len_out = 1024;
    repeat(105)@(posedge clk);
    in = 0; out = 0;

    #102;
    in = 1; in_port = 1; out = 1; out_port = 1; pkt_len_in = 1024; pkt_len_out = 1024;
    repeat(105)@(posedge clk);
    in = 0; out = 0;

    #102; 
    out = 1; out_port = 1; pkt_len_out = 32;
    headdrop_out = 1; headdrop_out_port = 1; headdrop_pkt_len_out = 32;
    repeat(105)@(posedge clk);
    out = 0; headdrop_out = 0;


    #102;
    in = 1; in_port = 2; pkt_len_in = 1024;
    out = 1; out_port = 2; pkt_len_out = 512;
    headdrop_out = 1; headdrop_out_port = 2; headdrop_pkt_len_out = 512;
    repeat(105)@(posedge clk);
    in = 0; out = 0; headdrop_out = 0;

    #102;
    in = 1; in_port = 3; pkt_len_in = 1024;
    headdrop_out = 1; headdrop_out_port = 3; headdrop_pkt_len_out = 512;
    repeat(105)@(posedge clk);
    in = 0; headdrop_out = 0;    

    #102
    in = 1; in_port = 2; pkt_len_in = 1024;
    out = 1; out_port = 2; pkt_len_out = 512;
    headdrop_out = 1; headdrop_out_port = 3; headdrop_pkt_len_out = 512;
    repeat(105)@(posedge clk);
    in = 0; out = 0; headdrop_out = 0;
end

endmodule
