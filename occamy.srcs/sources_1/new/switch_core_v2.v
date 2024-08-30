`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/27 10:19:46
// Design Name: 
// Module Name: switch_core_v2
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


module switch_core_v2(
    input clk,
    input rstn,
    input [127:0] data_in,
    input data_wr,
    input [15:0] i_cell_ptr_fifo_din,
    input i_cell_ptr_fifo_wr,
    
    output data_valid,
    output [127:0] data_dout
);

// output 
// wire [127:0] data_dout;

// admission TO data_sram
wire [11:0] sram_addr_a;
wire [127:0] sram_din_a;
wire sram_wr_a;

// admission TO cell_ptr_mem
wire FQ_rd;
wire FQ_empty;
wire [9:0] ptr_dout_s;

wire qc_ptr_full;
wire qc_wr_ptr_wr_en;
wire [15:0] qc_wr_ptr_din;
wire [15:0] qc_wr_preptr_din;

// admission TO pd_mem
wire pd_qc_ptr_full;
wire [3:0] pd_qc_wr_ptr_wr_en;
wire [127:0] pd_qc_wr_ptr_din;

// admission TO statistics
wire in;
wire [3:0] in_port;
wire [10:0] pkt_len_in;
wire [3:0] bitmap;

// cell_ptr_mem TO cell_read
wire FQ_wr;
wire [15:0] FQ_din_head, FQ_din_tail;
wire cell_mem_rd;
wire [15:0] cell_mem_addr;
wire [31:0] cell_mem_dout;

// pd_mem TO cell_read
wire [3:0] pd_ptr_ack;
wire [3:0] pd_ptr_rdy;
wire [511:0] pd_ptr_dout;

// data_sram TO cell_read
wire [10:0] sram_addr_b;
wire [127:0] sram_dout_b;

// cell_read TO statistics
wire out;
wire [3:0] out_port;
wire [10:0] pkt_len_out;

// headdrop TO cell_ptr_mem
wire FQ_wr_hd;
wire [15:0] FQ_din_head_hd;
wire [15:0] FQ_din_tail_hd;

// cell_read TO headdrop
wire cell_rd_pd_buzy;
wire cell_rd_cell_buzy;

// headdrop TO statistics
wire headdrop_out;
wire [3:0] headdrop_out_port;
wire [10:0] headdrop_pkt_len_out;

// headdrop TO pd_mem
wire [3:0] pd_ptr_ack_hd;
assign data_dout = sram_dout_b;


admission ad(
    .clk(clk),
    .rstn(rstn),
    
    // .i_cell_bp(i_cell_bp),
    .data_in(data_in),
    .data_wr(data_wr),
    .i_cell_ptr_fifo_din(i_cell_ptr_fifo_din),
    .i_cell_ptr_fifo_wr(i_cell_ptr_fifo_wr),
    
    .sram_addr(sram_addr_a),
    .sram_din(sram_din_a),
    .sram_wr(sram_wr_a),
    
    .FQ_rd(FQ_rd),
    .FQ_empty(FQ_empty),
    .ptr_dout_s(ptr_dout_s),
    
    .qc_wr_ptr_wr_en(qc_wr_ptr_wr_en),
    .qc_wr_ptr_din(qc_wr_ptr_din),
    .qc_ptr_full(qc_ptr_full),
    .qc_wr_preptr_din(qc_wr_preptr_din),
    
    .pd_qc_wr_ptr_wr_en(pd_qc_wr_ptr_wr_en),
    .pd_qc_wr_ptr_din(pd_qc_wr_ptr_din),
    .pd_qc_ptr_full(pd_qc_ptr_full),
    
    .in(in),
    .in_port(in_port),
    .pkt_len_in(pkt_len_in),
    .bitmap(bitmap)
);

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
    
// pd_memory_control pdm(
//     .clk(clk),              
//     .rstn(rstn),             
//     
//     .pd_FQ_rd(pd_FQ_rd),           
//     .pd_FQ_empty(pd_FQ_empty),        
//     .pd_ptr_dout_s(pd_ptr_dout_s),      
//       
//     .pd_qc_wr_ptr_wr_en(pd_qc_wr_ptr_wr_en), 
//     .pd_qc_wr_ptr_din(pd_qc_wr_ptr_din),   
//     .pd_qc_ptr_full(pd_qc_ptr_full),     
//    
//     .pd_FQ_wr(pd_FQ_wr),           
//     .pd_FQ_din(pd_FQ_din),
//              
//     .pd_ptr_rdy(pd_ptr_rdy),         
//     .pd_ptr_ack(pd_ptr_ack),         
//     .pd_ptr_dout(pd_ptr_dout),
// 
//     .pd_FQ_wr_hd(pd_FQ_wr_hd),
//     .pd_FQ_din_hd(pd_FQ_din_hd),
//     .pd_ptr_ack_hd(pd_ptr_ack_hd)
// 
// );

pd_memory_control_o pdm_o(
    .clk(clk),
    .rstn(rstn),
    
    .pd_qc_wr_ptr_wr_en(pd_qc_wr_ptr_wr_en),
    .pd_qc_wr_ptr_din(pd_qc_wr_ptr_din),
    .pd_qc_ptr_full(pd_qc_ptr_full),

    .pd_ptr_rdy(pd_ptr_rdy),
    .pd_ptr_ack(pd_ptr_ack),
    .pd_ptr_dout(pd_ptr_dout),

    .pd_ptr_ack_hd(pd_ptr_ack_hd)
);


cell_read_v2 cr (
    .clk(clk),
    .rstn(rstn),
    .FQ_wr(FQ_wr),
    .FQ_din_head(FQ_din_head),
    .FQ_din_tail(FQ_din_tail),

    .cell_mem_rd(cell_mem_rd),
    .cell_mem_dout(cell_mem_dout),
    .cell_mem_addr(cell_mem_addr),


    .pd_ptr_rdy(pd_ptr_rdy),
    .pd_ptr_ack(pd_ptr_ack),
    .pd_ptr_dout(pd_ptr_dout),

    .data_sram_addr_b(sram_addr_b),
    .data_sram_dout_b(sram_dout_b),
    .data_valid(data_valid),

    .out(out),
    .out_port(out_port),
    .pkt_len_out(pkt_len_out),

    .cell_rd_pd_buzy(cell_rd_pd_buzy),
    .cell_rd_cell_buzy(cell_rd_cell_buzy)
);

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
