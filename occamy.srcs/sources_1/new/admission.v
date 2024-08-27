`timescale 1ns / 1ps

//  i_cell_ptr structure:
//      |15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00|
//                  | ports map |     |   cell_number   |

module admission(
    input               clk,                    // 时钟信号
    input               rstn,                   // 低电平复位信号

    // 与前级交换
    output reg          i_cell_bp,              // 输入单元的背压信号
    input      [127:0]  data_in,                // 输入数据
    input               data_wr,                // 输入数据写使能
    input      [15:0]   i_cell_ptr_fifo_din,    // 输入单元指针 FIFO 的输入数据
    input               i_cell_ptr_fifo_wr,     // 输入单元指针 FIFO 的写使能

    // 与 sram 交换             
    output     [11:0]   sram_addr,              // SRAM 地址
    output     [127:0]  sram_din,               // SRAM 数据输入
    output              sram_wr,                // SRAM 写使能
    
    // 与 free queue 交换
    output reg          FQ_rd,                  // free queue (FQ) 的读使能
    input               FQ_empty,               // free queue (FQ) 的空状态信号
    input      [9:0]    ptr_dout_s,             // free queue (FQ) 的输出指针
        
    output reg          pd_FQ_rd,               // free PD queue (FPDQ) 的读使能
    input               pd_FQ_empty,            // free PD queue (FPDQ) 的空状态信号
    input      [9:0]    pd_ptr_dout_s,          // free PD queue (FPDQ) 的输出指针
    
    // 与 qc 交换
    output reg     qc_wr_ptr_wr_en,        // queue collector (qc) 写指针写使能
    output reg [15:0]   qc_wr_ptr_din,          // queue collector (qc) 写指针数据输入
    output reg [15:0]   qc_wr_preptr_din,       // queue collector (qc) 写指针(pre)数据输入
    input               qc_ptr_full,            // queue collector (qc) 指针满状态信号
    
    output reg [3:0]    pd_qc_wr_ptr_wr_en,     // PD queue collector (pd_qc) 写指针写使能
    output reg [127:0]  pd_qc_wr_ptr_din,       // PD queue collector (pd_qc) 写指针数据输入
    input               pd_qc_ptr_full,         // PD queue collector (pd_qc) 指针满状态信号
        
    // 与 statistic 交换
    output reg          in,                     // 指示数据包接收
    output reg [3:0]    in_port,                // 传入数据包的端口号
    output reg [10:0]   pkt_len_in,             // 传入数据包的长度
    input      [3:0]    bitmap                  // 位图，用于包丢弃检查
    
    
);

    reg  [3:0]     qc_portmap;                  // 队列控制器端口映射

    reg            i_cell_data_fifo_rd;         // 输入单元数据 FIFO 读使能
    wire [127:0]   i_cell_data_fifo_dout;       // 输入单元数据 FIFO 输出数据
    wire [8:0]     i_cell_data_fifo_depth;      // 输入单元数据 FIFO 深度
    wire           i_cell_data_fifo_empty;
    
    reg  [5:0]     cell_number;                 // 数据包中单元的数量
    reg [5:0] cell_number_pd;
    reg            i_cell_last;                 // 指示数据包中的最后一个单元
    reg            i_cell_first;                // 指示数据包中的第一个单元

    reg  [1:0]     sram_cnt_a;                  // SRAM 计数器 A

    reg            i_cell_ptr_fifo_rd;          // 输入单元指针 FIFO 读使能
    wire [15:0]    i_cell_ptr_fifo_dout;        // 输入单元指针 FIFO 输出数据
    wire           i_cell_ptr_fifo_full;        // 输入单元指针 FIFO 满状态信号
    wire           i_cell_ptr_fifo_empty;       // 输入单元指针 FIFO 空状态信号

    reg  [9:0]     FQ_dout;                     // free queue (FQ) 的数据输出

    reg  [9:0]     pd_FQ_dout;                  // free PD queue (FPDQ) 的数据输出
    
    reg  [9:0]     pre_cell_ptr;

    reg            first_flg;                   // 第一个单元标志
    reg last_flg;
    wire [10:0]    pkt_len;                     // 数据包长度
    reg            drop;                        // 数据包丢弃标


    reg [15:0] cell_head, cell_tail;


    // 写状态机
    reg [3:0] wr_state;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wr_state            <= #2 0;
            FQ_rd               <= #2 0;           // free queue (FQ) 的读使能
            FQ_dout             <= #2 0;          // free queue (FQ) 的数据输出
            sram_cnt_a          <= #2 0;           // SRAM 计数器 A
            i_cell_data_fifo_rd <= #2 0;         // 输入单元数据 FIFO 读使能
            i_cell_ptr_fifo_rd  <= #2 0;          // 输入单元指针 FIFO 读使能
            qc_wr_ptr_wr_en     <= #2 0;          // queue collector (qc) 写指针写使能
            qc_wr_ptr_din       <= #2 0;          // queue collector (qc) 写指针数据输入
            qc_wr_preptr_din    <= #2 0;
            qc_portmap          <= #2 0;          // 队列控制器端口映射
            cell_number         <= #2 0;          // 数据包中单元的数量
            cell_number_pd<=#2 0;
            i_cell_last         <= #2 0;          // 指示数据包中的最后一个单元
            i_cell_first        <= #2 0;          // 指示数据包中的第一个单元
            first_flg           <= #2 0;          // 第一个单元标志
            pd_FQ_rd            <= #2 0;          // free PD queue (FPDQ) 的读使能
            pd_FQ_dout          <= #2 0;          // free PD queue (FPDQ) 的数据输出
            pd_qc_wr_ptr_wr_en  <= #2 0;          // PD queue collector (pd_qc) 写指针写使能
            pd_qc_wr_ptr_din    <= #2 0;          // PD queue collector (pd_qc) 写指针数据输入
            in                  <= #2 0;          // 指示数据包接收
            in_port             <= #2 0;          // 传入数据包的端口号
            pkt_len_in          <= #2 0;          // 传入数据包的长度
            drop                <= #2 0;          // 数据包丢弃标志
            pre_cell_ptr        <= #2 0;

            cell_head<=#2 0;
            cell_tail<=#2 0;
            last_flg<=#2 0;
            
        end else begin
            FQ_rd               <= #2 0;           // free queue (FQ) 的读使能
            pd_FQ_rd            <= #2 0;           // free queue (FQ) 的读使能
            qc_wr_ptr_wr_en     <= #2 0;           // queue collector (qc) 写指针写使能
            pd_qc_wr_ptr_wr_en  <= #2 0;           // PD queue collector (pd_qc) 写指针写使能
            i_cell_ptr_fifo_rd  <= #2 0;           // 输入单元指针 FIFO 读使能
            i_cell_data_fifo_rd <= #2 0;
            
            case (wr_state)
                0: begin
                    sram_cnt_a      <= #2 0;           // SRAM 计数器 A
                    i_cell_last     <= #2 0;           // 指示数据包中的最后一个单元
                    i_cell_first    <= #2 0;           // 指示数据包中的第一个单元
    
                    if (!i_cell_ptr_fifo_empty & !qc_ptr_full & !pd_qc_ptr_full & !pd_FQ_empty & !FQ_empty) begin

                        if(!i_cell_data_fifo_empty) begin
                            i_cell_data_fifo_rd <= #2 1;  // 输入单元数据 FIFO 读使能
                        end
                        
                        i_cell_ptr_fifo_rd  <= #2 1;  // 输入单元指针 FIFO 读使能
                        cell_number[5:0]    <= #2 i_cell_ptr_fifo_dout[5:0]; // 数据包中单元的数量
                        cell_number_pd[5:0] <=#2 i_cell_ptr_fifo_dout[5:0]; 
    
                        if (i_cell_ptr_fifo_dout[5:0] == 6'b1) begin  
                            i_cell_last  <= #2 1;     // 指示数据包中的最后一个单元
                            last_flg<=#2 1;
                        end 
    
                        if ((i_cell_ptr_fifo_dout[11:8] & bitmap) == 4'b0) begin
                            wr_state     <= #2 5;
                            drop         <= #2 1;    // 数据包丢弃标志
                        end else begin
                            FQ_rd        <= #2 1;    // free queue (FQ) 的读使能
                            FQ_dout      <= #2 ptr_dout_s; // free queue (FQ) 的输出指针
                            pd_FQ_rd     <= #2 1;    // free PD queue (FPDQ) 的读使能
                            pd_FQ_dout   <= #2 pd_ptr_dout_s; // free PD queue (FPDQ) 的输出指针
    
                            i_cell_first <= #2 1;    // 指示数据包中的第一个单元
                            first_flg    <= #2 1;    // 第一个单元标志
                            qc_portmap   <= #2 i_cell_ptr_fifo_dout[11:8]; // 队列控制器端口映射
                            
                            if(!i_cell_data_fifo_empty) begin
                                wr_state     <= #2 1;
                            end else begin
                                wr_state     <= #2 6;
                            end
                                    
                        end
                    end
                end
    
                1: begin
                    if(!i_cell_data_fifo_empty) begin
                        i_cell_data_fifo_rd <= #2 1;
                        
                        cell_number    <= #2 cell_number - 1; // 数据包中单元的数量
                        sram_cnt_a     <= #2 1;               // SRAM 计数器 A
                        
                        if(!i_cell_first) begin
                            pre_cell_ptr        <= #2 {i_cell_last, i_cell_first, 4'b0, FQ_dout};
                            qc_wr_preptr_din    <= #2 pre_cell_ptr;

                        end else begin
                            pre_cell_ptr        <= #2 {i_cell_last, i_cell_first, 4'b0, FQ_dout};
                            qc_wr_preptr_din    <= #2 {16{1'b1}};    
                        end
                        
                        qc_wr_ptr_din  <= #2 {i_cell_last, i_cell_first, 4'b0, FQ_dout}; // queue collector (qc) 写指针数据输入
                        pd_qc_wr_ptr_din <= #2 {47'b0, cell_head, {i_cell_last, i_cell_first, 4'b0, FQ_dout}, pkt_len, cell_number_pd[5:0], 22'b0, pd_FQ_dout}; // PD queue collector (pd_qc) 写指针数据输入

                            if(first_flg) begin 
                                cell_head<=#2 {i_cell_last, i_cell_first, 4'b0, FQ_dout};
                                first_flg <=#2 0;
                            end
                        // if(i_cell_last) cell_tail<=#2 {i_cell_last, i_cell_first, 4'b0, FQ_dout};
                        
                        wr_state      <= #2 2;
                        pkt_len_in    <= #2 pkt_len;            // 传入数据包的长度
                        
                        qc_wr_ptr_wr_en<=#2 1;
                        in<=#2 1;
                        last_flg<=#2 0;
                        if (qc_portmap[0]) begin 
                            if (last_flg) begin
                                in_port   <= #2 0;              // 传入数据包的端口号
                                pd_qc_wr_ptr_wr_en[0] <= #2 1;  // PD queue collector (pd_qc) 写指针写使能
                            end
                        end
                        if (qc_portmap[1]) begin
                            if (last_flg) begin
                                in_port   <= #2 1;              // 传入数据包的端口号
                                pd_qc_wr_ptr_wr_en[1] <= #2 1;  // PD queue collector (pd_qc) 写指针写使能
                            end
                        end
                        if (qc_portmap[2]) begin
                            if (last_flg) begin 
                                in_port   <= #2 2;              // 传入数据包的端口号
                                pd_qc_wr_ptr_wr_en[2] <= #2 1;  // PD queue collector (pd_qc) 写指针写使能
                            end
                        end
                        if (qc_portmap[3]) begin
                            if (last_flg) begin 
                                in_port     <= #2 3;              // 传入数据包的端口号
                                pd_qc_wr_ptr_wr_en[3] <= #2 1;  // PD queue collector (pd_qc) 写指针写使能
                            end
                        end
    
                    end else begin
                        wr_state            <= #2 1;
                    end
                end
                2: begin
                    if(!i_cell_data_fifo_empty) begin
                        i_cell_data_fifo_rd <= #2 1;
                        in                  <= #2 0;                   // 指示数据包接收
                        sram_cnt_a          <= #2 2;                   // SRAM 计数器 A
                        wr_state            <= #2 3;
                    end else begin
                        wr_state            <= #2 2;
                    end
                end
                3: begin
                    if(!i_cell_data_fifo_empty) begin
                        i_cell_data_fifo_rd <= #2 1;
                        in                  <= #2 0;                   // 指示数据包接收
                        sram_cnt_a          <= #2 3;                   // SRAM 计数器 A
                        wr_state            <= #2 4;
                        
                    end else begin
                        wr_state            <= #2 3;
                    end
                end
                4: begin
                    if(!i_cell_data_fifo_empty) begin
                        i_cell_first <= #2 0;                  // 指示数据包中的第一个单元
                        
                        if (cell_number) begin                  // 数据包中单元的数量
                            i_cell_data_fifo_rd <= #2 1;
                            if (!FQ_empty) begin                // free queue (FQ) 的空状态信号
                                FQ_rd   <= #2 1;                // free queue (FQ) 的读使能
                                FQ_dout <= #2 ptr_dout_s;       // free queue (FQ) 的输出指针
                                
                                sram_cnt_a <= #2 0;             // SRAM 计数器 A
                                wr_state <= #2 1;
                                
                                if (cell_number == 1) begin 
                                    i_cell_last <= #2 1;        // 指示数据包中的最后一个单元
                                    last_flg <=#2 1;
                                end 
                                else
                                    i_cell_last <= #2 0;        // 指示数据包中的最后一个单元
                            end
                        end else begin
                            i_cell_data_fifo_rd <= #2 0;        // 输入单元数据 FIFO 读使能
                            wr_state     <= #2 0;
                        end
                        
                    end else begin
                        wr_state     <= #2 4;
                    end
                end
                5: begin
                    sram_cnt_a   <= #2 sram_cnt_a + 1;      // SRAM 计数器 A
                    if (sram_cnt_a >= 3) begin 
                        if (cell_number == 1) begin         // 数据包中单元的数量
                            wr_state <= #2 0;
                            i_cell_data_fifo_rd <= #2 0;    // 输入单元数据 FIFO 读使能
                            drop <= #2 0;                   // 清除drop标志    [?]
                        end
                        cell_number <= #2 cell_number - 1;  // 数据包中单元的数量
                    end
                end 
                  
                6:begin
                    if(!i_cell_data_fifo_empty) begin
                        i_cell_data_fifo_rd <= #2 1;  // 输入单元数据 FIFO 读使能
                        wr_state     <= #2 1;
                    end else begin            
                        wr_state     <= #2 6;
                    end
                end
                
                default:
                    wr_state <= #2 0;
            endcase
        end
    end



    // 分配 SRAM 写信号、地址和数据
    assign sram_wr   = (i_cell_data_fifo_rd & !drop);         // SRAM 写使能
    assign sram_addr = {FQ_dout[9:0], sram_cnt_a[1:0]};       // SRAM 地址
    assign sram_din  = i_cell_data_fifo_dout[127:0];          // SRAM 数据输入
    // 计算数据包长度：cell_number * 64 Byte
    assign pkt_len   = {cell_number, 6'd0};                  // 数据包长度
    // back-push 信号，
    // 当 data FIFO 深度超过 161 [ (256 - 160) * 128 / 8 = 1,536 Byte ] 
    // 或指针 FIFO 满时，拉高back-push信号
    always @(posedge clk) begin
        i_cell_bp <= #2 (i_cell_data_fifo_depth[8:0] > 161) | i_cell_ptr_fifo_full;
    end


    // input cell data FIFO 实例化
    sfifo_ft_w128_d256 u_i_cell_fifo(
      .clk(         clk                            ),  // 时钟信号   
      .rst(        !rstn                           ),  // 复位信号   
      .din(         data_in                [127:0] ),  // 指针 FIFO 输入数据   
      .wr_en(       data_wr                        ),  // 指针 FIFO 写使能   
      .rd_en(       i_cell_data_fifo_rd            ),  // 指针 FIFO 读使能   
      .dout(        i_cell_data_fifo_dout  [127:0] ),  // 指针 FIFO 输出数据   
      .full(                                       ),  // 指针 FIFO 满状态信号   
      .empty(       i_cell_data_fifo_empty         ),  // 指针 FIFO 空状态信号
      .data_count(  i_cell_data_fifo_depth [8:0]   )   // 指针 FIFO 数据计数
    );

    // input cell ptr FIFO 实例化
    sfifo_ft_w16_d32 u_i_ptr_fifo (
      .clk(         clk                   ),  // 时钟信号
      .rst(        !rstn                  ),  // 复位信号
      .din(         i_cell_ptr_fifo_din   ),  // 指针 FIFO 输入数据
      .wr_en(       i_cell_ptr_fifo_wr    ),  // 指针 FIFO 写使能
      .rd_en(       i_cell_ptr_fifo_rd    ),  // 指针 FIFO 读使能
      .dout(        i_cell_ptr_fifo_dout  ),  // 指针 FIFO 输出数据
      .full(        i_cell_ptr_fifo_full  ),  // 指针 FIFO 满状态信号
      .empty(       i_cell_ptr_fifo_empty ),  // 指针 FIFO 空状态信号
      .data_count(                        )   // 指针 FIFO 数据计数
    );


endmodule