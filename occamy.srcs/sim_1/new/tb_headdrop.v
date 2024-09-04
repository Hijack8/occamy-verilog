`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/04 13:09:44
// Design Name: 
// Module Name: tb_headdrop
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


module tb_headdrop();

reg clk, rstn;
wire FQ_wr_hd;
wire [15:0] FQ_din_head_hd;
wire [15:0] FQ_din_tail_hd;
reg [3:0] pd_ptr_rdy;
wire [3:0] pd_ptr_ack_hd;
reg [511:0] pd_ptr_dout;

reg cell_rd_cell_buzy, cell_rd_pd_buzy;
wire headdrop_out;
wire [3:0] headdrop_out_port;
wire [10:0] headdrop_pkt_len_out;

reg [3:0] bitmap;

headdrop_v3 hd(
    .clk(clk),
    .rstn(rstn),
    .FQ_wr(FQ_wr_hd),
    .FQ_din_head(FQ_din_head_hd),
    .FQ_din_tail(FQ_din_tail_hd),
    .pd_ptr_rdy(pd_ptr_rdy),
    .pd_ptr_ack(pd_ptr_ack_hd),
    .pd_ptr_dout(pd_ptr_dout),
    
    .cell_rd_pd_buzy(cell_rd_pd_buzy),
    .cell_rd_cell_buzy(cell_rd_cell_buzy),

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
    rstn = 1; 
    pd_ptr_rdy = 0; pd_ptr_dout = 0; cell_rd_cell_buzy = 0; cell_rd_pd_buzy = 0; bitmap = 4'b1111;
    #18; rstn = 0;
    #18; rstn = 1;


    pd_ptr_rdy = 4'b0001; bitmap = 4'b1110; 
    repeat(1)@(posedge clk);
    #2 pd_ptr_rdy = 0; #2 bitmap = 4'b1111;


    #102; 
    pd_ptr_rdy = 4'b0001; bitmap = 4'b1011;
    repeat(1)@(posedge clk);
    #2 pd_ptr_rdy = 4'b0000; #2 bitmap = 4'b1111;

    #102; 
    pd_ptr_rdy = 4'b1111; bitmap = 4'b1000; 
    repeat(30)@(posedge clk);
    #2 pd_ptr_rdy = 4'b0000; #2 bitmap = 4'b1111;

    #102; 
    pd_ptr_rdy = 4'b1111; bitmap = 4'b0000; 
    repeat(30)@(posedge clk);
    #2 pd_ptr_rdy = 0; #2 bitmap = 4'b1111; 

    #102;
    pd_ptr_rdy = 4'b0001; bitmap = 4'b1110; cell_rd_pd_buzy = 1; cell_rd_cell_buzy = 1;
    repeat(1)@(posedge clk);
    #2 pd_ptr_rdy = 4'b0000; #2 bitmap = 4'b1111; #2 cell_rd_pd_buzy = 0; #2 cell_rd_cell_buzy = 0;

    #102; 
    pd_ptr_rdy = 4'b0001; bitmap = 4'b1110; 
    repeat(1)@(posedge clk);
    #2 cell_rd_pd_buzy = 1; #2 pd_ptr_rdy = 4'b0000; #2 bitmap = 4'b1111;   
    repeat(1)@(posedge clk);
    #2 cell_rd_pd_buzy = 0;

    #102; 
    pd_ptr_rdy = 4'b0001; bitmap = 4'b1110; 
    repeat(1)@(posedge clk);
    #2 pd_ptr_rdy = 0; #2 bitmap = 4'b1111; 
    repeat(1)@(posedge clk);
    #2 cell_rd_cell_buzy = 1;
    repeat(20)@(posedge clk);
    #2 cell_rd_cell_buzy = 0; 

    #102; 
    pd_ptr_rdy = 4'b0011; bitmap = 4'b1100;
    repeat(1)@(posedge clk);
    #2 pd_ptr_rdy = 4'b0010; #2 bitmap = 4'b1101; 
    repeat(1)@(posedge clk);
    #2 cell_rd_cell_buzy = 1; 
    repeat(20)@(posedge clk);
    #2 cell_rd_cell_buzy = 0;
    repeat(1)@(posedge clk);
    #2 pd_ptr_rdy = 0; #2 bitmap = 4'b1111;
end

endmodule
