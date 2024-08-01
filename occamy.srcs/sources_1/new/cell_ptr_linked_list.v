`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/25 11:30:43
// Design Name: 
// Module Name: cell_ptr_linked_list
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


module cell_ptr_linked_list(
    input               clk, 
    input               rstn,
    input               FQ_rd,
    output              FQ_empty,
    output      [9:0]   ptr_dout_s,
    input       [3:0]   qc_wr_ptr_wr_en,
    input       [15:0]  qc_wr_ptr_din,
    output reg  [3:0]   qc_ptr_full,
    
    output      [3:0]   ptr_rdy,
    input       [3:0]   ptr_ack,
    output      [63:0]  ptr_dout,
    input               FQ_wr,
    input       [15:0]  FQ_din,

    input [3:0] headdrop,
    output [3:0] headdrop_buzy
    );
    
    
wire			ptr_rdy0,ptr_rdy1,ptr_rdy2,ptr_rdy3;		
wire			ptr_ack0,ptr_ack1,ptr_ack2,ptr_ack3;
wire [15:0]		qc_rd_ptr_dout0,qc_rd_ptr_dout1,
                qc_rd_ptr_dout2,qc_rd_ptr_dout3;
wire			qc_ptr_full0, qc_ptr_full1, qc_ptr_full2, qc_ptr_full3;

assign ptr_dout = {qc_rd_ptr_dout3, qc_rd_ptr_dout2, qc_rd_ptr_dout1, qc_rd_ptr_dout0};

always@(posedge clk) begin
	qc_ptr_full<=#2 ({	qc_ptr_full3,qc_ptr_full2,qc_ptr_full1, qc_ptr_full0}==4'b0)?0:1;
end
assign	{ptr_ack3,ptr_ack2,ptr_ack1,ptr_ack0}=ptr_ack;

assign ptr_rdy = {ptr_rdy3, ptr_rdy2, ptr_rdy1, ptr_rdy0};

wire headdrop0, headdrop1, headdrop2, headdrop3;
assign {headdrop3, headdrop2, headdrop1, headdrop0} = headdrop;
wire headdrop_buzy0, headdrop_buzy1, headdrop_buzy2, headdrop_buzy3;
assign headdrop_buzy = {headdrop_buzy3, headdrop_buzy2, headdrop_buzy1, headdrop_buzy0};




multi_user_fq u_fq (
	.clk(clk), 
	.rstn(rstn), 
	.ptr_din({6'b0,FQ_din[9:0]}), 
	.FQ_wr(FQ_wr), 
	.FQ_rd(FQ_rd), 
	.ptr_dout_s(ptr_dout_s), 
	.ptr_fifo_empty(FQ_empty)
);

switch_qc qc0(
	.clk(clk), 
	.rstn(rstn), 
	.q_din(qc_wr_ptr_din), 
	.q_wr(qc_wr_ptr_wr_en[0]), 
	.q_full(qc_ptr_full0), 
	.ptr_rdy(ptr_rdy0),
	.ptr_ack(ptr_ack0),
	.ptr_dout(qc_rd_ptr_dout0),

    .headdrop(headdrop0),
    .headdrop_buzy(headdrop_buzy0)
);

switch_qc qc1(
	.clk(clk), 
	.rstn(rstn), 
	
	.q_din(qc_wr_ptr_din), 
	.q_wr(qc_wr_ptr_wr_en[1]), 
	.q_full(qc_ptr_full1), 
	
	.ptr_rdy(ptr_rdy1),
	.ptr_ack(ptr_ack1),
	.ptr_dout(qc_rd_ptr_dout1),

    .headdrop(headdrop1),
    .headdrop_buzy(headdrop_buzy1)
);

switch_qc qc2(
	.clk(clk), 
	.rstn(rstn), 
	
	.q_din(qc_wr_ptr_din), 
	.q_wr(qc_wr_ptr_wr_en[2]), 
	.q_full(qc_ptr_full2), 
	
	.ptr_rdy(ptr_rdy2),
	.ptr_ack(ptr_ack2),
	.ptr_dout(qc_rd_ptr_dout2),

    .headdrop(headdrop2),
    .headdrop_buzy(headdrop_buzy2)
);

switch_qc qc3(
	.clk(clk), 
	.rstn(rstn), 
	
	.q_din(qc_wr_ptr_din), 
	.q_wr(qc_wr_ptr_wr_en[3]), 
	.q_full(qc_ptr_full3), 
	
	.ptr_rdy(ptr_rdy3),
	.ptr_ack(ptr_ack3),
	.ptr_dout(qc_rd_ptr_dout3),

    .headdrop(headdrop3),
    .headdrop_buzy(headdrop_buzy3)
);


wire 	[31:0]	sram_din_a;				
wire 	[31:0]	sram_dout_b;			
wire 	[10:0]	sram_addr_a;			
wire 	[10:0]	sram_addr_b;			
wire			sram_wr_a;	
wire sram_wr_b;


dpsram_w32_d512 u_ptr_ram(
  .clka(clk), 			
  .wea(sram_wr_a), 		
  .addra(sram_addr_a[10:0]),	
  .dina(sram_din_a), 	
  .douta(), 			
  .clkb(clk), 		
  .web(sram_wr_b), 			
  .addrb(sram_addr_b[10:0]), 	
  .dinb(sram_din_b),
  .ena(1),
  .enb(1), 		
  .doutb(sram_dout_b) 
)


endmodule
