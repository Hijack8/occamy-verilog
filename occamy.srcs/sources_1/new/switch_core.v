`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/18 10:25:48
// Design Name: 
// Module Name: switch_core
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

module switch_core(
input					clk,
input					rstn,

input		  [127:0]	i_cell_data_fifo_din,				
input		 			i_cell_data_fifo_wr,					
input		  [15:0]	i_cell_ptr_fifo_din,				
input		 			i_cell_ptr_fifo_wr,					
output					i_cell_bp,

output					o_cell_fifo_wr,
output	  [3:0]		o_cell_fifo_sel,
output	     [127:0]	o_cell_fifo_din,
output					o_cell_first,
output					o_cell_last,
input		 [3:0]		o_cell_bp
    );
wire 	[127:0]	sram_din_a;				
wire 	[127:0]	sram_dout_b;			
wire 	[11:0]	sram_addr_a;			
wire 	[11:0]	sram_addr_b;			
wire			sram_wr_a;				

			
wire  [15:0]		FQ_din;		
wire				FQ_wr;
wire				FQ_rd;

// ADD(PD)
wire [15:0]      FPDQ_din;
wire             FPDQ_wr;
wire             FPDQ_rd;
		
wire  [3:0]		qc_wr_ptr_wr_en;
wire			qc_ptr_full0;
wire			qc_ptr_full1;
wire			qc_ptr_full2;
wire			qc_ptr_full3;
reg				qc_ptr_full;
wire [9:0]		ptr_dout_s;		
wire  [15:0]		qc_wr_ptr_din;	
		
wire 			FQ_empty;

wire  [3:0]		pd_qc_wr_ptr_wr_en;
wire			pd_qc_ptr_full0;
wire			pd_qc_ptr_full1;
wire			pd_qc_ptr_full2;
wire			pd_qc_ptr_full3;
reg				pd_qc_ptr_full;
wire [9:0]		pd_ptr_dout_s;		
wire  [127:0]		pd_qc_wr_ptr_din;	
wire            FPDQ_empty;

// For statistics
wire in;
wire [3:0] in_port;
wire [10:0] pkt_len_in;
wire [3:0] bitmap;

wire out;
wire [3:0] out_port;
wire[10:0] pkt_len_out;

admission ad(
    .clk(clk),
    .rstn(rstn),
    .data_in(i_cell_data_fifo_din),
    .data_wr(i_cell_data_fifo_wr),
    .FQ_rd(FQ_rd),
    .sram_addr(sram_addr_a),
    .sram_wr(sram_wr_a),
    .sram_din(sram_din_a),
    .qc_wr_ptr_wr_en(qc_wr_ptr_wr_en),
    .qc_wr_ptr_din(qc_wr_ptr_din),
    .FPDQ_rd(FPDQ_rd),
    .pd_qc_wr_ptr_wr_en(pd_qc_wr_ptr_wr_en),
    .pd_qc_wr_ptr_din(pd_qc_wr_ptr_din),
    .in(in),
    .in_port(in_port),
    .pkt_len_in(pkt_len_in),
    .bitmap(bitmap),
    .qc_ptr_full(qc_ptr_full),
    .pd_qc_ptr_full(pd_qc_ptr_full),
    .i_cell_bp(i_cell_bp),
    .ptr_dout_s(ptr_dout_s),
    .i_cell_ptr_fifo_din(i_cell_ptr_fifo_din),
    .i_cell_ptr_fifo_wr(i_cell_ptr_fifo_wr),
    .FQ_empty(FQ_empty),
    .FPDQ_empty(FPDQ_empty),
    .pd_ptr_dout_s(pd_ptr_dout_s)
    );
always@(posedge clk) begin
	qc_ptr_full<=#2 ({	qc_ptr_full3,qc_ptr_full2,qc_ptr_full1, qc_ptr_full0}==4'b0)?0:1;
    pd_qc_ptr_full<= #2 ({  pd_qc_ptr_full3, pd_qc_ptr_full2, pd_qc_ptr_full1, pd_qc_ptr_full0}  == 4'b0) ? 0: 1;
end

wire [15:0]		qc_rd_ptr_dout0,qc_rd_ptr_dout1,
                qc_rd_ptr_dout2,qc_rd_ptr_dout3;
                
wire [127:0]     pd_qc_rd_ptr_dout0, pd_qc_rd_ptr_dout1,
                pd_qc_rd_ptr_dout2, pd_qc_rd_ptr_dout3;

wire  [3:0]		ptr_ack;
wire  [3:0]      pd_ptr_ack;
wire [3:0]		ptr_rd_req_pre;

wire			ptr_rdy0,ptr_rdy1,ptr_rdy2,ptr_rdy3;		
wire			ptr_ack0,ptr_ack1,ptr_ack2,ptr_ack3;

wire            pd_ptr_rdy0, pd_ptr_rdy1, pd_ptr_rdy2, pd_ptr_rdy3;
wire            pd_ptr_ack0, pd_ptr_ack1, pd_ptr_ack2, pd_ptr_ack3;

assign	ptr_rd_req_pre={ptr_rdy3,ptr_rdy2,ptr_rdy1,ptr_rdy0} & (~o_cell_bp);
assign	{ptr_ack3,ptr_ack2,ptr_ack1,ptr_ack0}=ptr_ack;
assign {pd_ptr_ack3, pd_ptr_ack2, pd_ptr_ack1, pd_ptr_ack0} = pd_ptr_ack;


assign pd_ptr_rd_req_pre = {pd_ptr_rdy3, pd_ptr_rdy2, pd_ptr_rdy1, pd_ptr_rdy0} & {~o_cell_bp};


wire [63:0]cell_read_ptr_dout;
wire [63:0]cell_read_pd_ptr_dout;

cell_read cr(
    .clk(clk),
    .rstn(rstn),
    .ptr_rdy(ptr_rd_req_pre),
    .ptr_ack(ptr_ack),
    .ptr_dout(cell_read_ptr_dout),
    .FQ_wr(FQ_wr),
    .ptr_din(FQ_din),
    .pd_ptr_rdy(pd_ptr_rd_req_pre),
    .pd_ptr_ack(pd_ptr_ack),
    .pd_ptr_dout(cell_read_pd_ptr_dout),
    .FPDQ_wr(FPDQ_wr),
    .pd_ptr_din(FPDQ_din),
    .sram_addr_b(sram_addr_b),
    .sram_dout_b(sram_dout_b),
    .o_cell_last(o_cell_last),
    .o_cell_first(o_cell_first),
    .o_cell_fifo_din(o_cell_fifo_din),
    .o_cell_fifo_wr(o_cell_fifo_wr),
    .o_cell_fifo_sel(o_cell_fifo_sel),
    .out(out),
    .out_port(out_port),
    .pkt_len_out(pkt_len_out)
    );
assign cell_read_ptr_dout = {qc_rd_ptr_dout3, qc_rd_ptr_dout2, qc_rd_ptr_dout1, qc_rd_ptr_dout0};
assign cell_read_pd_ptr_dout = {pd_qc_rd_ptr_dout3, pd_qc_rd_ptr_dout2, pd_qc_rd_ptr_dout1, pd_qc_rd_ptr_dout0};

multi_user_fq u_fq (
	.clk(clk), 
	.rstn(rstn), 
	.ptr_din({6'b0,FQ_din[9:0]}), 
	.FQ_wr(FQ_wr), 
	.FQ_rd(FQ_rd), 
	.ptr_dout_s(ptr_dout_s), 
	.ptr_fifo_empty(FQ_empty)
);

multi_user_fpdq u_fpdq(
	.clk(clk), 
	.rstn(rstn), 
	.ptr_din({6'b0,FPDQ_din[9:0]}), 
	.FQ_wr(FPDQ_wr), 
	.FQ_rd(FPDQ_rd), 
	.ptr_dout_s(pd_ptr_dout_s), 
	.ptr_fifo_empty(FPDQ_empty)
);

switch_qc qc0(
	.clk(clk), 
	.rstn(rstn), 
	.q_din(qc_wr_ptr_din), 
	.q_wr(qc_wr_ptr_wr_en[0]), 
	.q_full(qc_ptr_full0), 
	.ptr_rdy(ptr_rdy0),
	.ptr_ack(ptr_ack0),
	.ptr_dout(qc_rd_ptr_dout0)
);

switch_qc qc1(
	.clk(clk), 
	.rstn(rstn), 
	
	.q_din(qc_wr_ptr_din), 
	.q_wr(qc_wr_ptr_wr_en[1]), 
	.q_full(qc_ptr_full1), 
	
	.ptr_rdy(ptr_rdy1),
	.ptr_ack(ptr_ack1),
	.ptr_dout(qc_rd_ptr_dout1)
);

switch_qc qc2(
	.clk(clk), 
	.rstn(rstn), 
	
	.q_din(qc_wr_ptr_din), 
	.q_wr(qc_wr_ptr_wr_en[2]), 
	.q_full(qc_ptr_full2), 
	
	.ptr_rdy(ptr_rdy2),
	.ptr_ack(ptr_ack2),
	.ptr_dout(qc_rd_ptr_dout2)
);

switch_qc qc3(
	.clk(clk), 
	.rstn(rstn), 
	
	.q_din(qc_wr_ptr_din), 
	.q_wr(qc_wr_ptr_wr_en[3]), 
	.q_full(qc_ptr_full3), 
	
	.ptr_rdy(ptr_rdy3),
	.ptr_ack(ptr_ack3),
	.ptr_dout(qc_rd_ptr_dout3)
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

dpsram_w128_d2k u_data_ram (
  .clka(clk), 			
  .wea(sram_wr_a), 		
  .addra(sram_addr_a[10:0]),	
  .dina(sram_din_a), 	
  .douta(), 			
  .clkb(clk), 		
  .web(1'b0), 			
  .addrb(sram_addr_b[10:0]), 	
  .dinb(128'b0),
  .ena(1),
  .enb(1), 		
  .doutb(sram_dout_b) 	
);


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
endmodule
