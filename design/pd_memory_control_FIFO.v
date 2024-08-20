`timescale 1ns / 1ps

module pd_memory_control_o(
    input                   clk,              // Clock input
    input                   rstn,             // Asynchronous reset, active low

    // [Admission]  - read from free queue
    input                   pd_FQ_rd,
    output                  pd_FQ_empty,
    output      [9:0]       pd_ptr_dout_s,

    // [Admission]  - write into qc
    input       [3:0]       pd_qc_wr_ptr_wr_en,
    input       [127:0]     pd_qc_wr_ptr_din,
    output reg  [3:0]       pd_qc_ptr_full,

    // [Cell read]  - write into free queue
    input                   pd_FQ_wr,
    input       [15:0]      pd_FQ_din,
    // [Cell read]  - read from qc
    output      [3:0]       pd_ptr_rdy,
    input       [3:0]       pd_ptr_ack,
    output      [511:0]     pd_ptr_dout   

);

    // 内部信号定义
    wire [127:0] pd_qc_rd_ptr_dout0, pd_qc_rd_ptr_dout1,
                 pd_qc_rd_ptr_dout2, pd_qc_rd_ptr_dout3;  // 四个指针数据输出
    wire         pd_ptr_rdy0, pd_ptr_rdy1, pd_ptr_rdy2, pd_ptr_rdy3;  // 四个指针准备好信号
    wire         pd_ptr_ack0, pd_ptr_ack1, pd_ptr_ack2, pd_ptr_ack3;  // 四个指针应答信号
    wire         pd_qc_ptr_full0, pd_qc_ptr_full1, pd_qc_ptr_full2, pd_qc_ptr_full3;  // 四个指针满信号

    // 将四个指针数据连接为一个 512 位宽的输出
    assign pd_ptr_dout = {pd_qc_rd_ptr_dout3, pd_qc_rd_ptr_dout2, pd_qc_rd_ptr_dout1, pd_qc_rd_ptr_dout0};

    // 将四个指针准备好信号组合为一个 4 位宽的输出
    assign pd_ptr_rdy = {pd_ptr_rdy3, pd_ptr_rdy2, pd_ptr_rdy1, pd_ptr_rdy0};

    // 将输入的 4 位宽的应答信号分解到四个单独的信号中
    assign {pd_ptr_ack3, pd_ptr_ack2, pd_ptr_ack1, pd_ptr_ack0} = pd_ptr_ack;

    // 在时钟上升沿，更新指针满标志寄存器
    always @(posedge clk) begin
        pd_qc_ptr_full <= #2 ({pd_qc_ptr_full3, pd_qc_ptr_full2, pd_qc_ptr_full1, pd_qc_ptr_full0} == 4'b0) ? 0 : 1;
    end

    // 多用户 FPDQ 实例化
    multi_user_fpdq u_fpdq(
        .clk           (clk), 
        .rstn          (rstn), 
        .ptr_din       ({6'b0, pd_FQ_din[9:0]}),  // 指针数据输入，带有 6 位填充
        .FQ_wr         (pd_FQ_wr),                // 写请求信号
        .FQ_rd         (pd_FQ_rd),                // 读请求信号
        .ptr_dout_s    (pd_ptr_dout_s),           // 指针数据输出
        .ptr_fifo_empty(pd_FQ_empty)              // FIFO 空标志
    );

    // 四个 switch_pd_qc 实例化，分别对应四个通道
    switch_pd_qc pd_qc0(
        .clk      (clk),
        .rstn     (rstn),
        .q_din    (pd_qc_wr_ptr_din),
        .q_wr     (pd_qc_wr_ptr_wr_en[0]),
        .q_full   (pd_qc_ptr_full0), 
        .ptr_rdy  (pd_ptr_rdy0),
        .ptr_ack  (pd_ptr_ack0),
        .ptr_dout (pd_qc_rd_ptr_dout0)
    );

    switch_pd_qc pd_qc1(
        .clk      (clk),
        .rstn     (rstn),
        .q_din    (pd_qc_wr_ptr_din),
        .q_wr     (pd_qc_wr_ptr_wr_en[1]),
        .q_full   (pd_qc_ptr_full1), 
        .ptr_rdy  (pd_ptr_rdy1),
        .ptr_ack  (pd_ptr_ack1),
        .ptr_dout (pd_qc_rd_ptr_dout1)
    );

    switch_pd_qc pd_qc2(
        .clk      (clk),
        .rstn     (rstn),
        .q_din    (pd_qc_wr_ptr_din),
        .q_wr     (pd_qc_wr_ptr_wr_en[2]),
        .q_full   (pd_qc_ptr_full2), 
        .ptr_rdy  (pd_ptr_rdy2),
        .ptr_ack  (pd_ptr_ack2),
        .ptr_dout (pd_qc_rd_ptr_dout2)
    );

    switch_pd_qc pd_qc3(
        .clk      (clk),
        .rstn     (rstn),
        .q_din    (pd_qc_wr_ptr_din),
        .q_wr     (pd_qc_wr_ptr_wr_en[3]),
        .q_full   (pd_qc_ptr_full3), 
        .ptr_rdy  (pd_ptr_rdy3),
        .ptr_ack  (pd_ptr_ack3),
        .ptr_dout (pd_qc_rd_ptr_dout3)
    );

endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module switch_pd_qc(
        input          clk,          // 时钟信号
        input          rstn,         // 复位信号（低电平有效）
    
        input  [127:0] q_din,        // 输入数据
        input          q_wr,         // 写入使能信号
        output         q_full,       // 队列满标志
    
        output         ptr_rdy,      // 指针准备好信号
        input          ptr_ack,      // 指针应答信号
        output [127:0] ptr_dout      // 指针数据输出
    );
    
    // 初始化信号
    assign q_full = 0;  // 队列永不满
    
    // 寄存器定义
    reg  [127:0] ptr_fifo_din;
    reg          ptr_rd_ack;
    reg  [127:0] head;               // 指向当前数据头部的指针
    reg  [127:0] tail;               // 指向当前数据尾部的指针
    reg  [15:0]  depth_cell;         // 当前队列的深度（以单元为单位）
    reg          depth_flag;         // 深度标志
    reg  [15:0]  depth_frame;        // 当前帧的深度
    
    // RAM 接口信号
    reg  [127:0] ptr_ram_din;
    wire [127:0] ptr_ram_dout;
    reg          ptr_ram_wr;
    reg  [9:0]   ptr_ram_addr;
    
    // RAM B 接口信号
    reg  [127:0] ptr_ram_din_b;
    wire [127:0] ptr_ram_dout_b;
    reg          ptr_ram_wr_b;
    reg  [9:0]   ptr_ram_addr_b;
    
    // 信号组合
    wire [1:0] sig;
    assign sig = {q_wr, ptr_ack};   // 将写入和应答信号组合为一个 2 位信号
    assign ptr_dout = head;         // 输出当前头指针指向的数据
    assign ptr_rdy = (depth_cell > 0);  // 如果队列深度大于 0，则表示指针准备好
    
    // 控制逻辑块
    always @(posedge clk or negedge rstn)
        if (!rstn) begin
            // 异步复位，复位所有寄存器
            ptr_ram_wr   <= #2 0;
            head         <= #2 0;    
            tail         <= #2 0;    
            depth_cell   <= #2 0;    
            depth_frame  <= #2 0;
            ptr_rd_ack   <= #2 0;
            ptr_ram_din  <= #2 0;
            ptr_ram_addr <= #2 0;
            ptr_fifo_din <= #2 0;
            depth_flag   <= #2 0;
    
            ptr_ram_din_b <= #2 0;
            ptr_ram_wr_b  <= #2 0;
            ptr_ram_addr_b<= #2 0;
        end else begin
            // 正常操作逻辑
            ptr_ram_addr_b[9:0] <= #2 head[9:0];
            case (sig)
                2'b00: begin
                    ptr_ram_wr <= #2 0;  // 无操作
                end
                2'b01: begin
                    // 读取操作
                    head <= #2 ptr_ram_dout_b;  // 更新头指针
                    depth_cell <= #2 depth_cell - 1;  // 减少队列深度
                    if (head[15]) begin
                        depth_frame <= #2 depth_frame - 1;  // 更新帧深度
                        depth_flag <= #2 (depth_frame > 1) ? 1 : 0;  // 更新深度标志
                    end
                end
                2'b10: begin
                    // 写入操作
                    if (depth_cell[9:0]) begin
                        ptr_ram_wr <= #2 1;
                        ptr_ram_addr[9:0] <= #2 tail[9:0];
                        ptr_ram_din[127:0] <= #2 q_din[127:0];
                        tail <= #2 q_din;
                    end else begin
                        ptr_ram_wr <= #2 1;
                        ptr_ram_addr[9:0] <= #2 q_din[9:0];
                        ptr_ram_din[127:0] <= #2 q_din[127:0];
                        tail <= #2 q_din;
                        head <= #2 q_din;
                    end    
                    depth_cell <= #2 depth_cell + 1;
                    if (q_din[15]) begin        
                        depth_flag <= #2 1;
                        depth_frame <= #2 depth_frame + 1;
                    end
                end
                2'b11: begin
                    // 读写操作
                    if (depth_cell[9:0]) begin
                        ptr_ram_wr <= #2 1;
                        ptr_ram_addr[9:0] <= #2 tail[9:0];
                        ptr_ram_din[127:0] <= #2 q_din[127:0];
                        tail <= #2 q_din;
                        if (q_din[15]) begin        
                            depth_flag <= #2 1;
                            depth_frame <= #2 depth_frame + 1;
                        end
                    
                        head <= #2 ptr_ram_dout_b;
                        depth_cell <= #2 depth_cell - 1;
                        if (head[15]) begin
                            depth_frame <= #2 depth_frame - 1;
                            depth_flag <= #2 (depth_frame > 1) ? 1 : 0;
                        end
                    end else begin
                        ptr_ram_wr <= #2 0;
                        head <= #2 q_din;
                    end
                end
            endcase
        end
    
    // 双端口 SRAM 模块实例化
    dpsram_w128_d512 u_ptr_ram (
        .clka(clk),             
        .wea(ptr_ram_wr),     
        .addra(ptr_ram_addr[8:0]), 
        .dina(ptr_ram_din),   
        .douta(ptr_ram_dout),
        .ena(1),
        .clkb(clk),
        .web(ptr_ram_wr_b),
        .addrb(ptr_ram_addr_b),
        .dinb(ptr_ram_din_b),
        .doutb(ptr_ram_dout_b),
        .enb(1)
    );      
endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// Free Packet Descriptor Queue (FPDQ) 模块
module multi_user_fpdq(
        input          clk,             // 时钟信号
        input          rstn,            // 复位信号（低电平有效）
    
        input  [15:0]  ptr_din,         // 输入指针数据
        input          FQ_wr,           // 写入请求信号
        input          FQ_rd,           // 读取请求信号
        output [9:0]   ptr_dout_s,      // 输出的指针数据
        output         ptr_fifo_empty   // FIFO 空标志信号
    );
    
    // 寄存器定义
    reg  [2:0]  FQ_state;             // FPDQ 状态寄存器
    reg  [9:0]  addr_cnt;             // 地址计数器
    reg  [9:0]  ptr_fifo_din;         // FIFO 输入数据寄存器
    reg         ptr_fifo_wr;          // FIFO 写入使能信号
    
    // 状态机和控制逻辑
    always @(posedge clk or negedge rstn)
        if (!rstn) begin
            // 异步复位，初始化寄存器
            FQ_state   <= #2 0;
            addr_cnt   <= #2 0;
            ptr_fifo_wr<= #2 0;
        end else begin
            ptr_fifo_wr <= #2 0;  // 默认不写入
            case (FQ_state)
                0: FQ_state <= #2 1;  // 初始状态，进入状态 1
                1: begin
                    ptr_fifo_din <= #2 0;
                    FQ_state <= #2 2;  // 状态 1，进入状态 2
                    end
                2: FQ_state <= #2 3;  // 状态 2，进入状态 3
                3: FQ_state <= #2 4;  // 状态 3，进入状态 4
                4: begin              
                    // 状态 4，初始化地址计数器并填充 FIFO
                    ptr_fifo_din <= #2 addr_cnt;  // 将地址计数器值赋值给 FIFO 输入
                    if (addr_cnt < 10'h1ff)  // 如果计数器未到最大值
                        addr_cnt <= #2 addr_cnt + 1;  // 地址计数器递增
                    if (ptr_fifo_din < 10'h1ff)
                        ptr_fifo_wr <= #2 1;  // 使能 FIFO 写入
                    else begin
                        FQ_state <= #2 5;  // 状态机进入状态 5
                        ptr_fifo_wr <= #2 0;  // 禁止 FIFO 写入
                    end
                end
                5: begin
                    ptr_fifo_din <= #2 ptr_din[9:0];  // 默认将输入指针的低 10 位赋值给 FIFO 输入
                    // 状态 5，根据写入请求控制 FIFO 写入
                    if (FQ_wr) 
                        ptr_fifo_wr <= #2 1;  // 如果有写入请求，使能 FIFO 写入
                end
            endcase
        end
    
    // 实例化一个深度为 512，宽度为 10 位的同步 FIFO
    sfifo_ft_w10_d512 u_ptr_fifo(
        .clk(clk),
        .rst(!rstn),
        .din(ptr_fifo_din[9:0]),
        .wr_en(ptr_fifo_wr),
        .rd_en(FQ_rd),
        .dout(ptr_dout_s[9:0]),
        .empty(ptr_fifo_empty),
        .full(),
        .data_count()  
    );
    
endmodule
