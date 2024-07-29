`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/29 15:25:47
// Design Name: 
// Module Name: pd_linked_list
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


module pd_linked_list(
    input clk,
    input rstn,
    input FPDQ_rd,
    output FPDQ_empty,
    output [9:0] pd_ptr_dout_s,
    input [3:0]pd_qc_wr_ptr_wr_en,
    input [127:0]pd_qc_wr_ptr_din,
    output reg [3:0]pd_qc_ptr_full,
    output [3:0]pd_ptr_rdy,
    input [3:0] pd_ptr_ack,
    output [511:0] pd_ptr_dout,
    input FPDQ_wr,
    input [15:0]FPDQ_din
    );

wire [127:0]     pd_qc_rd_ptr_dout0, pd_qc_rd_ptr_dout1,
                pd_qc_rd_ptr_dout2, pd_qc_rd_ptr_dout3;
wire            pd_ptr_rdy0, pd_ptr_rdy1, pd_ptr_rdy2, pd_ptr_rdy3;
wire            pd_ptr_ack0, pd_ptr_ack1, pd_ptr_ack2, pd_ptr_ack3;
wire			pd_qc_ptr_full0, pd_qc_ptr_full1, pd_qc_ptr_full2, pd_qc_ptr_full3;

assign pd_ptr_dout = {pd_qc_rd_ptr_dout3, pd_qc_rd_ptr_dout2, pd_qc_rd_ptr_dout1, pd_qc_rd_ptr_dout0};

assign pd_ptr_rdy = {pd_ptr_rdy3, pd_ptr_rdy2, pd_ptr_rdy1, pd_ptr_rdy0};

assign {pd_ptr_ack3, pd_ptr_ack2, pd_ptr_ack1, pd_ptr_ack0} = pd_ptr_ack;

always@(posedge clk) begin
    pd_qc_ptr_full<= #2 ({  pd_qc_ptr_full3, pd_qc_ptr_full2, pd_qc_ptr_full1, pd_qc_ptr_full0}  == 4'b0) ? 0: 1;
end


multi_user_fpdq u_fpdq(
	.clk(clk), 
	.rstn(rstn), 
	.ptr_din({6'b0,FPDQ_din[9:0]}), 
	.FQ_wr(FPDQ_wr), 
	.FQ_rd(FPDQ_rd), 
	.ptr_dout_s(pd_ptr_dout_s), 
	.ptr_fifo_empty(FPDQ_empty)
);


switch_pd_qc pd_qc0(
    .clk(clk),
    .rstn(rstn),
    .q_din(pd_qc_wr_ptr_din),
    .q_wr(pd_qc_wr_ptr_wr_en[0]),
    .q_full(pd_qc_ptr_full0), 
	
	.ptr_rdy(pd_ptr_rdy0),
	.ptr_ack(pd_ptr_ack0),
	.ptr_dout(pd_qc_rd_ptr_dout0)
);

switch_pd_qc pd_qc1(
    .clk(clk),
    .rstn(rstn),
    .q_din(pd_qc_wr_ptr_din),
    .q_wr(pd_qc_wr_ptr_wr_en[1]),
    .q_full(pd_qc_ptr_full1), 
	
	.ptr_rdy(pd_ptr_rdy1),
	.ptr_ack(pd_ptr_ack1),
	.ptr_dout(pd_qc_rd_ptr_dout1)
);

switch_pd_qc pd_qc2(
    .clk(clk),
    .rstn(rstn),
    .q_din(pd_qc_wr_ptr_din),
    .q_wr(pd_qc_wr_ptr_wr_en[2]),
    .q_full(pd_qc_ptr_full2), 
	
	.ptr_rdy(pd_ptr_rdy2),
	.ptr_ack(pd_ptr_ack2),
	.ptr_dout(pd_qc_rd_ptr_dout2)
);

switch_pd_qc pd_qc3(
    .clk(clk),
    .rstn(rstn),
    .q_din(pd_qc_wr_ptr_din),
    .q_wr(pd_qc_wr_ptr_wr_en[3]),
    .q_full(pd_qc_ptr_full3), 
	
	.ptr_rdy(pd_ptr_rdy3),
	.ptr_ack(pd_ptr_ack3),
	.ptr_dout(pd_qc_rd_ptr_dout3)
);

endmodule
