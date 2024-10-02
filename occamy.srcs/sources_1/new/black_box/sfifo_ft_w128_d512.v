// sfifo_ft_w128_d512.v

(* black_box *)

module sfifo_ft_w128_d512 (
    input               clk,            // 时钟信号
    input               rst,            // 复位信号
    input   [127:0]     din,            // 数据输入
    input               wr_en,          // 写使能
    input               rd_en,          // 读使能
    output  [127:0]     dout,           // 数据输出
    output              full,           // FIFO 满信号
    output              empty,          // FIFO 空信号
    output  [9:0]       data_count      // 数据计数
);
endmodule
