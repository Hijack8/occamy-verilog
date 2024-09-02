`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/02 10:57:48
// Design Name: 
// Module Name: tb_cpm
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


module tb_cpm();

reg clk, rstn;
reg FQ_rd;
wire FQ_empty;
wire [9:0] ptr_dout_s;
reg qc_wr_ptr_wr_en;
reg [15:0] qc_wr_ptr_din;
reg [15:0] qc_wr_preptr_din;
wire qc_ptr_full;

reg FQ_wr;
reg [15:0] FQ_din_head;
reg [15:0] FQ_din_tail;
reg cell_mem_rd;
wire [31:0] cell_mem_dout;
reg [15:0] cell_mem_addr;

reg FQ_wr_hd;
reg [15:0] FQ_din_head_hd;
reg [15:0] FQ_din_tail_hd;

cell_pointer_memory_control cpm(
    .clk(clk), 
    .rstn(rstn), 
    
    .FQ_rd(FQ_rd), 
    .FQ_empty(FQ_empty), 
    .ptr_dout_s(ptr_dout_s),
     
    .qc_wr_ptr_wr_en(qc_wr_ptr_wr_en), 
    .qc_wr_ptr_din(qc_wr_ptr_din), 
    .qc_wr_preptr_din(qc_wr_preptr_din),
    .qc_ptr_full(qc_ptr_full),
    
    .FQ_wr(FQ_wr), 
    .FQ_din_head(FQ_din_head), 
    .FQ_din_tail(FQ_din_tail),
    .cell_mem_rd(cell_mem_rd),
    .cell_mem_dout(cell_mem_dout),
    .cell_mem_addr(cell_mem_addr),
    
    .FQ_wr_hd(FQ_wr_hd),
    .FQ_din_head_hd(FQ_din_head_hd),
    .FQ_din_tail_hd(FQ_din_tail_hd)
);

real CYCLE = 10;
always begin 
    clk = 0; #(CYCLE / 2);
    clk = 1; #(CYCLE / 2);
end

integer i;
initial begin  
    rstn = 1'b1;
    FQ_rd = 0; qc_wr_ptr_wr_en = 0; qc_wr_ptr_din = 0; qc_wr_preptr_din = 0; 
    FQ_wr = 0; FQ_din_head = 0; FQ_din_tail = 0; cell_mem_rd = 0; cell_mem_addr = 0;
    FQ_wr_hd = 0; FQ_din_head_hd = 0; FQ_din_tail_hd = 0;
    #18 rstn = 1'b0; 
    #18 rstn = 1'b1;

    #6212;
    FQ_rd = 1; 
    repeat(560)@(posedge clk);
    #2 FQ_rd = 0;

    #102;
    FQ_wr = 1; FQ_din_head = 0; FQ_din_tail = 279;
    repeat(1)@(posedge clk);
    #2 FQ_wr = 0;

    #102; 
    FQ_rd = 1; 
    repeat(560)@(posedge clk);
    #2 FQ_rd = 0;

    #102;
    FQ_wr = 1; FQ_din_head = 280; FQ_din_tail = 47;
    repeat(1)@(posedge clk);
    #2 FQ_wr = 0;

    #102;
    FQ_rd = 1;
    repeat(560)@(posedge clk);
    #2 FQ_rd = 0;

    #102;
    FQ_wr = 1; FQ_din_head = 48; FQ_din_tail = 327;
    repeat(1)@(posedge clk);
    #2 FQ_wr = 0;

    #102;
    FQ_rd = 1; 
    repeat(560)@(posedge clk);
    #2 FQ_rd = 0;

    // headdrop and cell_read conflict 
    #102; 
    FQ_wr = 1; FQ_din_head = 328; FQ_din_tail = 95;
    FQ_wr_hd = 1; FQ_din_head_hd = 329; FQ_din_tail_hd = 94;
    repeat(1)@(posedge clk);
    #2 FQ_wr = 0; #2 FQ_wr_hd = 0; 


    #102; 
    FQ_rd = 1; 
    repeat(560)@(posedge clk);
    #2 FQ_rd = 0; 


    // headdrop is slower 1 cycle
    #102;
    FQ_wr = 1; FQ_din_head = 96; FQ_din_tail = 300;
    repeat(1)@(posedge clk);
    #2 FQ_wr = 0; 
    FQ_wr_hd = 1; FQ_din_head_hd = 301; FQ_din_tail_hd = 375;
    repeat(1)@(posedge clk);
    #2 FQ_wr_hd = 0;

    #102; 
    FQ_rd = 1; 
    repeat(1000)@(posedge clk);
    #2 FQ_rd = 0;

    // headrop is faster 1 cycle
    #102; 
    FQ_wr_hd = 1; FQ_din_head_hd = 376; FQ_din_tail_hd = 100; 
    repeat(1)@(posedge clk);
    #2 FQ_wr_hd = 0; 
    FQ_wr = 1; FQ_din_head = 101; FQ_din_tail = 363; 
    repeat(1)@(posedge clk);
    #2 FQ_wr = 0;

    #102; 
    FQ_rd = 1; 
    repeat(1000)@(posedge clk);
    #2 FQ_rd = 0;


//     #500;
//     for(i = 0; i < 1000; i = i + 1) begin 
//         process_1_pkt;
//         #20;
//     end
 end

task process_1_pkt();
begin 
    FQ_din_head = ptr_dout_s;
    #2 FQ_rd = 1; 
    repeat(1)@(posedge clk);
    #2 FQ_rd = 0;
    repeat(1)@(posedge clk);
    #2 FQ_rd = 1;
    repeat(1)@(posedge clk);
    #2 FQ_rd = 0;
    repeat(1)@(posedge clk);
    #2 FQ_rd = 1;
    repeat(1)@(posedge clk);
    #2 FQ_rd = 0;
    repeat(1)@(posedge clk);
    #2 FQ_rd = 1;
    repeat(1)@(posedge clk);
    #2 FQ_rd = 0;
    repeat(1)@(posedge clk);
    #2 FQ_din_tail = ptr_dout_s;

    repeat(1)@(posedge clk);
    #2 FQ_wr = 1;
    repeat(1)@(posedge clk);
    #2 FQ_wr = 0;
end
endtask

endmodule
