`timescale 1ns / 1ps

module pd_memory_control_o (
    input                   clk,              // Clock input
    input                   rstn,             // Asynchronous reset, active low

    // [Admission]  - write into qc
    input       [3:0]       pd_qc_wr_ptr_wr_en,
    input       [127:0]     pd_qc_wr_ptr_din,
    output [3:0]       pd_qc_ptr_full,

    // [Cell read]  - read from qc
    output      [3:0]       pd_ptr_rdy,
    input       [3:0]       pd_ptr_ack,
    output      [511:0]     pd_ptr_dout,  

    // [Headdrop] - read from qc
    input [3:0] pd_ptr_ack_hd
);

// 内部信号定义
wire [127:0] pd_ptr_dout0, pd_ptr_dout1,
             pd_ptr_dout2, pd_ptr_dout3;  // 四个指针数据输出

wire [3:0] pd_rd_en;
assign pd_rd_en = pd_ptr_ack | pd_ptr_ack_hd;

wire pd_empty0, pd_empty1, pd_empty2, pd_empty3;
assign pd_ptr_rdy = {!pd_empty3, !pd_empty2, !pd_empty1, !pd_empty0};
assign pd_ptr_dout = {pd_ptr_dout3, pd_ptr_dout2, pd_ptr_dout1, pd_ptr_dout0};


sfifo_ft_w128_d512 pd_list0(
    .clk(clk),
    .rst(!rstn),
    .din(pd_qc_wr_ptr_din),
    .wr_en(pd_qc_wr_ptr_wr_en[0]),
    .rd_en(pd_rd_en[0]),
    .dout(pd_ptr_dout0),
    .full(pd_qc_ptr_full[0]),
    .empty(pd_empty0),
    .data_count()
);

sfifo_ft_w128_d512 pd_list1(
    .clk(clk),
    .rst(!rstn),
    .din(pd_qc_wr_ptr_din),
    .wr_en(pd_qc_wr_ptr_wr_en[1]),
    .rd_en(pd_rd_en[1]),
    .dout(pd_ptr_dout1),
    .full(pd_qc_ptr_full[1]),
    .empty(pd_empty1),
    .data_count()
);

sfifo_ft_w128_d512 pd_list2(
    .clk(clk),
    .rst(!rstn),
    .din(pd_qc_wr_ptr_din),
    .wr_en(pd_qc_wr_ptr_wr_en[2]),
    .rd_en(pd_rd_en[2]),
    .dout(pd_ptr_dout2),
    .full(pd_qc_ptr_full[2]),
    .empty(pd_empty2),
    .data_count()
);

sfifo_ft_w128_d512 pd_list3(
    .clk(clk),
    .rst(!rstn),
    .din(pd_qc_wr_ptr_din),
    .wr_en(pd_qc_wr_ptr_wr_en[3]),
    .rd_en(pd_rd_en[3]),
    .dout(pd_ptr_dout3),
    .full(pd_qc_ptr_full[3]),
    .empty(pd_empty3),
    .data_count()
);

endmodule

