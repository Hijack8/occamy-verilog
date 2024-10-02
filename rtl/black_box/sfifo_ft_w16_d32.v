// sfifo_ft_w16_d32.v

(* black_box *)

module sfifo_ft_w16_d32 (
    input           clk,            // 时钟信号
    input           rst,            // 复位信号
    input   [15:0]  din,            // 数据输入
    input           wr_en,          // 写使能
    input           rd_en,          // 读使能
    output  [15:0]  dout,           // 数据输出
    output          full,           // FIFO 满信号
    output          empty,          // FIFO 空信号
    output  [4:0]   data_count      // 数据计数
);
endmodule
