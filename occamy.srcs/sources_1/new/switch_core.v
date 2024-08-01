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
output	     [3:0]		o_cell_fifo_sel,
output	     [127:0]	o_cell_fifo_din,
output					o_cell_first,
output					o_cell_last,
input		 [3:0]		o_cell_bp
    );

// for sram
wire 	[127:0]	sram_din_a;				
wire 	[127:0]	sram_dout_b;			
wire 	[11:0]	sram_addr_a;			
wire 	[11:0]	sram_addr_b;			
wire			sram_wr_a;				

	
wire    [15:0]	FQ_din;		
wire			FQ_wr;
wire			FQ_rd;
wire 			FQ_empty;
wire    [9:0]	ptr_dout_s;	
wire    [3:0]	qc_wr_ptr_wr_en;
wire			qc_ptr_full;
wire    [15:0]	qc_wr_ptr_din;	


wire    [15:0]  FPDQ_din;
wire            FPDQ_wr;
wire            FPDQ_rd;
wire            FPDQ_empty;
wire    [3:0]	pd_qc_wr_ptr_wr_en;
wire			pd_qc_ptr_full;
wire    [9:0]	pd_ptr_dout_s;		
wire    [127:0]	pd_qc_wr_ptr_din;	


// For statistics
wire            in;
wire    [3:0]   in_port;
wire    [10:0]  pkt_len_in;
wire    [3:0]   bitmap;

wire            out;
wire    [3:0]   out_port;
wire    [10:0]  pkt_len_out;

// linked list & cell_read
wire    [3:0]   cell_ptr_rdy;
wire    [3:0]	cell_ptr_ack;
wire    [63:0]  cpll_ptr_dout;

wire    [3:0]   pd_ptr_rdy;
wire    [3:0]   pd_ptr_ack;
wire    [511:0] pdll_ptr_dout;


reg [3:0] headdrop;
wire [3:0] headdrop_buzy;

initial begin 
    headdrop= 0;
end


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
//    .FPDQ_rd(FPDQ_rd),
    .pd_FQ_rd(FPDQ_rd),
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
//    .FPDQ_empty(FPDQ_empty),
    .pd_FQ_empty(FPDQ_empty),
    .pd_ptr_dout_s(pd_ptr_dout_s)
    );

                


cell_read cr(
    .clk(clk),
    .rstn(rstn),
    .ptr_rdy(cell_ptr_rdy),
    .ptr_ack(cell_ptr_ack),
    .ptr_dout(cpll_ptr_dout),
    .FQ_wr(FQ_wr),
    .ptr_din(FQ_din),
    .pd_ptr_rdy(pd_ptr_rdy),
    .pd_ptr_ack(pd_ptr_ack),
    .pd_ptr_dout(pdll_ptr_dout),
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


wire hd_FQ_wr;
wire [15:0] hd_FQ_din;
wire hd_FPDQ_wr;
wire [127:0] hd_FPDQ_din;
wire [3:0] hd_pd_ptr_ack;
wire [3:0] fail;
wire [1:0] headdrop_out_port;
wire headdrop_out;
wire [10:0] headdrop_pkt_len_out;

headdrop hd(
    .clk(clk),
    .rstn(rstn),
    .ptr_rdy(cell_ptr_rdy),
    .headdrop_en(headdrop),
    .FQ_wr(hd_FQ_wr),
    .FQ_din(hd_FQ_din),
    .pd_ptr_rdy(pd_ptr_rdy),
    .pd_ptr_ack(hd_pd_ptr_ack),
    .FPDQ_wr(hd_FPDQ_wr),
    .FPDQ_din(hd_FPDQ_din),
    .cell_ptr_dout(cpll_ptr_dout),
    .pd_dout(pdll_ptr_dout),
    .fail(fail),
    .bitmap(bitmap),
    .out_port(headdrop_out_port),
    .out(headdrop_out),
    .pkt_len_out(headdrop_pkt_len_out)
);

cell_ptr_linked_list cpll(
    .clk(clk),
    .rstn(rstn),
    .FQ_rd(FQ_rd),
    .FQ_empty(FQ_empty),
    .ptr_dout_s(ptr_dout_s),
    .qc_wr_ptr_wr_en(qc_wr_ptr_wr_en),
    .qc_wr_ptr_din(qc_wr_ptr_din),
    .qc_ptr_full(qc_ptr_full),
    .ptr_rdy(cell_ptr_rdy),
    .ptr_ack(cell_ptr_ack),
    .ptr_dout(cpll_ptr_dout),
    .FQ_wr(FQ_wr),
    .FQ_din(FQ_din),

    .headdrop(headdrop),
    .headdrop_buzy(headdrop_buzy)
    );



pd_linked_list pdll(
    .clk(clk),
    .rstn(rstn),
    .FPDQ_rd(FPDQ_rd),
    .FPDQ_empty(FPDQ_empty),
    .pd_ptr_dout_s(pd_ptr_dout_s),
    .pd_qc_wr_ptr_wr_en(pd_qc_wr_ptr_wr_en),
    .pd_qc_wr_ptr_din(pd_qc_wr_ptr_din),
    .pd_qc_ptr_full(pd_qc_ptr_full),
    .pd_ptr_rdy(pd_ptr_rdy),
    .pd_ptr_ack(pd_ptr_ack),
    .pd_ptr_dout(pdll_ptr_dout),
    .FPDQ_wr(FPDQ_wr),
    .FPDQ_din(FPDQ_din)
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

    .headdrop_out(headdrop_out),
    .headdrop_out_port(headdrop_out_port),
    .headdrop_pkt_len_out(headdrop_pkt_len_out),
    .bitmap(bitmap)
    );
endmodule
