`timescale 1ns / 1ps

module tb_admission_cell_ptr();

    // 输入信号
    reg                clk;                    // 时钟信号
    reg                rstn;                   // 低电平复位信号
    reg       [127:0]  data_in;                // 输入数据
    reg                data_wr;                // 输入数据写使能
    reg       [15:0]   i_cell_ptr_fifo_din;    // 输入单元指针 FIFO 的输入数据
    reg                i_cell_ptr_fifo_wr;     // 输入单元指针 FIFO 的写使能
    wire                FQ_empty;               // free queue (FQ) 的空状态信号
    wire       [9:0]    ptr_dout_s;             // free queue (FQ) 的输出指针
    wire                qc_ptr_full;            // queue collector (qc) 指针满状态信号
    wire       [3:0]    bitmap;                 // 位图，用于包丢弃检查
    
    wire                pd_FQ_empty;            // free PD queue (FPDQ) 的空状态信号
    wire       [9:0]    pd_ptr_dout_s;          // free PD queue (FPDQ) 的输出指针
    wire                pd_qc_ptr_full;         // PD queue collector (pd_qc) 指针满状态信号

    // 输出信号
    wire               i_cell_bp;              // 输入单元的背压信号
    wire      [11:0]   sram_addr_a;              // SRAM 地址
    wire      [127:0]  sram_din_a;               // SRAM 数据输入
    wire               sram_wr_a;                // SRAM 写使能
    wire               FQ_rd;                  // free queue (FQ) 的读使能
    wire               pd_FQ_rd;               // free PD queue (FPDQ) 的读使能
    wire      [3:0]    qc_wr_ptr_wr_en;        // queue collector (qc) 写指针写使能
    wire      [15:0]   qc_wr_ptr_din;          // queue collector (qc) 写指针数据输入
    wire      [15:0]   qc_wr_preptr_din;          // queue collector (qc) 写指针数据输入
    wire      [3:0]    pd_qc_wr_ptr_wr_en;     // PD queue collector (pd_qc) 写指针写使能
    wire      [127:0]  pd_qc_wr_ptr_din;       // PD queue collector (pd_qc) 写指针数据输入
    wire               in;                     // 指示数据包接收
    wire      [3:0]    in_port;                // 传入数据包的端口号
    wire      [10:0]   pkt_len_in;             // 传入数据包的长度

    admission uut1 (
        .clk(clk),
        .rstn(rstn),
        
        .i_cell_bp(i_cell_bp),
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
        
        .pd_FQ_rd(pd_FQ_rd),
        .pd_FQ_empty(pd_FQ_empty),
        .pd_ptr_dout_s(pd_ptr_dout_s),
        
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

wire [15:0] FQ_din_head, FQ_din_tail;
wire FQ_wr;
wire cell_mem_rd;
wire [15:0] cell_mem_addr;
wire [31:0] cell_mem_dout;

    cell_pointer_memory_control uut2 (
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
    
wire [3:0] pd_ptr_rdy;    
wire [3:0] pd_ptr_ack;
wire [15:0] pd_FQ_din;
    pd_memory_control uut3 (
        .clk(clk),              
        .rstn(rstn),             
        
        .pd_FQ_rd(pd_FQ_rd),           
        .pd_FQ_empty(pd_FQ_empty),        
        .pd_ptr_dout_s(pd_ptr_dout_s),      
          
        .pd_qc_wr_ptr_wr_en(pd_qc_wr_ptr_wr_en), 
        .pd_qc_wr_ptr_din(pd_qc_wr_ptr_din),   
        .pd_qc_ptr_full(pd_qc_ptr_full),     
       
        .pd_FQ_wr(pd_FQ_wr),           
        .pd_FQ_din(pd_FQ_din),
                 
        .pd_ptr_rdy(pd_ptr_rdy),         
        .pd_ptr_ack(pd_ptr_ack),         
        .pd_ptr_dout(pd_ptr_dout),

        .pd_FQ_wr_hd(pd_FQ_wr_hd),
        .pd_FQ_din_hd(pd_FQ_din_hd),
        .pd_ptr_ack_hd(pd_ptr_ack_hd)

    );
wire [11:0] sram_addr_b;
wire [127:0] sram_dout_b;
wire [511:0] pd_ptr_dout;
    cell_read_v2 cr (
        .clk(clk),
        .rstn(rstn),
        .FQ_wr(FQ_wr),
        .FQ_din_head(FQ_din_head),
        .FQ_din_tail(FQ_din_tail),

        .cell_mem_rd(cell_mem_rd),
        .cell_mem_dout(cell_mem_dout),
        .cell_mem_addr(cell_mem_addr),


        .pd_FQ_wr(pd_FQ_wr),
        .pd_FQ_din(pd_FQ_din),
        .pd_ptr_rdy(pd_ptr_rdy),
        .pd_ptr_ack(pd_ptr_ack),
        .pd_ptr_dout(pd_ptr_dout),

        .data_sram_addr_b(sram_addr_b),
        .data_sram_dout_b(sram_dout_b),

        .out(out),
        .out_port(out_port),
        .pkt_len_out(pkt_len_out),

        .cell_rd_pd_buzy(cell_rd_pd_buzy),
        .cell_rd_cell_buzy(cell_rd_cell_buzy)
    );


wire FQ_wr_hd;
wire [15:0] FQ_din_head_hd;
wire [15:0] FQ_din_tail_hd;
wire pd_FQ_wr_hd;
wire [15:0] pd_FQ_din_hd;
wire [3:0] pd_ptr_ack_hd;
wire cell_rd_pd_buzy, cell_rd_cell_buzy;


headdrop_v2 hd(
    .clk(clk),
    .rstn(rstn),
    .FQ_wr(FQ_wr_hd),
    .FQ_din_head(FQ_din_head_hd),
    .FQ_din_tail(FQ_din_tail_hd),
    .pd_FQ_wr(pd_FQ_wr_hd),
    .pd_FQ_din(pd_FQ_din_hd),
    .pd_ptr_rdy(pd_ptr_rdy),
    .pd_ptr_ack(pd_ptr_ack_hd),
    .pd_ptr_dout(pd_ptr_dout),
    
    .cell_rd_ack(pd_ptr_ack),
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

wire [3:0] out_port;
wire [10:0] pkt_len_out;
wire [10:0] headdrop_pkt_len_out;
wire headdrop_out;
wire [3:0] headdrop_out_port;



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



    //============== (0) ==================
    //main      
    initial begin
        #6213;
        
        input_a_frame(16'b0000_0010_00_000100, 0000);
        input_a_frame(16'b0000_0100_00_000100, 0011);
        input_a_frame(16'b0000_0100_00_000100, 1010);

    end

    //============== (1) ==================
    //clock generating
    real         CYCLE = 10  ;
    always begin
        clk = 0 ; #(CYCLE/2) ;
        clk = 1 ; #(CYCLE/2) ;
    end
    
    //============== (2) ==================
    //reset generating
    initial begin
        rstn        = 1'b1 ;
        #18 rstn     = 1'b0 ;
        #18 rstn     = 1'b1 ;
        
        #25500
        #18 rstn     = 1'b0 ;
        #18 rstn     = 1'b1 ;
        #300
        $finish;
    end


    //============== (3) ==================
    //初始化输入信号
    initial begin                    
        data_in                 = 128'h0;            
        i_cell_ptr_fifo_din     = 16'h0;         
                  
        i_cell_ptr_fifo_wr      = 0;           
        data_wr                 = 0;
                        
//        pd_FQ_empty             = 0;          
//        pd_ptr_dout_s           = 0;              
//        pd_qc_ptr_full          = 0;          
//        pd_FQ_empty             = 0;             
//        pd_ptr_dout_s           = 10'h0;           
//        pd_qc_ptr_full          = 0; 

    end

   
    task input_a_cell(
        input   [511:0]     data
    ); 
        begin
            data_wr = 1;
            data_in = data[127:0];
            #5;
            data_wr = 0;
            #5;
            data_wr = 1;
            data_in = data[255:128];
            #5;
            data_wr = 0;
            #5;
            data_wr = 1;
            data_in = data[383:256];
            #5;
            data_wr = 0;
            #5;
            data_wr = 1;
            data_in = data[511:384];
            #5;
            data_wr = 0;
            #5;
            data_in = 0;
            
        end
    endtask;

    task input_a_frame(
        input   [15:0]      ptr,
        input   [3:0]       mask
    ); 
        begin
            fork
                // 并行部分：设置 i_cell_ptr_fifo_wr 信号
                begin
                    i_cell_ptr_fifo_wr  = 1;
                    i_cell_ptr_fifo_din = ptr;
                    #5;
                    i_cell_ptr_fifo_wr  = 0;
                end
                // 并行部分：第一次调用 input_a_cell
                begin
                    input_a_cell({{32{4'hc ^ mask}}, {32{4'hd^ mask}}, {32{4'he^ mask}}, {32{4'hf^ mask}}});
                end
            join
            input_a_cell({{32{4'h9^ mask}}, {32{4'h0^ mask}}, {32{4'ha^ mask}}, {32{4'hb^ mask}}});
            input_a_cell({{32{4'h5^ mask}}, {32{4'h6^ mask}}, {32{4'h7^ mask}}, {32{4'h8^ mask}}});
            input_a_cell({{32{4'h1^ mask}}, {32{4'h2^ mask}}, {32{4'h3^ mask}}, {32{4'h4^ mask}}});
            // # 100;
        end
    endtask;


endmodule