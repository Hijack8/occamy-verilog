`timescale 1ns / 1ps

module pd_memory_control #(
    parameter RST = 3'b000,
    parameter IDLE  = 3'b001,
    parameter FQ_WR = 3'b010,
    parameter FQ_RD = 3'b011,
    parameter QC_WR = 3'b100,
    parameter QC_RD = 3'b101

)(
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
    output      [511:0]     pd_ptr_dout,

    input pd_FQ_wr_hd,
    input [15:0] pd_FQ_din_hd,
    input [3:0] pd_ptr_ack_hd
    
);
   
    // Ready signals for each port
    assign pd_ptr_rdy = {port_can_read[3], port_can_read[2], port_can_read[1], port_can_read[0]};

    // Data output for the port
    // reg [127:0]		qc_rd_ptr_dout [3:0];
    // assign pd_ptr_dout = {qc_rd_ptr_dout[3], qc_rd_ptr_dout[2], qc_rd_ptr_dout[1], qc_rd_ptr_dout[0]};
    assign pd_ptr_dout = {port_list_head[3], port_list_head[2], port_list_head[1], port_list_head[0]};
    
    // Queue full status output
    // ps: 写满标志恒为0 [ 不知道原因，但是之前的代码就这么写的 ]
    always@(posedge clk) begin
        // pd_qc_ptr_full<= #2 ({  pd_qc_ptr_full3, pd_qc_ptr_full2, pd_qc_ptr_full1, pd_qc_ptr_full0}  == 4'b0) ? 0: 1;
        pd_qc_ptr_full <=#2 0;
    end

    reg [9:0]   pd_FQ_head;
    reg [9:0]   pd_FQ_tail;
    assign pd_FQ_empty = (pd_FQ_head == pd_FQ_tail)?1:0;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            pd_FQ_head                     <= #2 0;
            pd_FQ_tail                     <= #2 511;
        end
     end
     
    assign pd_ptr_dout_s = pd_FQ_head[8:0];
    
     
    reg [2:0]   fq_rd_state;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            fq_rd_state                 <= #2 0;
        end else begin
            case(fq_rd_state)
                0:  begin
                    if(main_state != RST && pd_FQ_rd && !pd_FQ_empty) begin
                        
                        ram_addr_b          <= #2 pd_FQ_head;
                        ram_out_enable_b    <= #2 1;
                        fq_rd_state         <= #2 1;
                    end
                end
                1:  begin
                    
                   #2 pd_FQ_head          <=  ram_out_data_b[24:16];
                   ram_out_enable_b    <= #2 0;
                   fq_rd_state         <= #2 0;
                end
            endcase
        end
    end

    reg [2:0]   fq_wr_state;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            fq_wr_state                 <= #2 0;
        end else begin
            case(fq_wr_state)
                0:  begin
                    if(main_state != RST && pd_FQ_wr) begin
                        ram_addr_a          <= #2 pd_FQ_tail;
                        ram_in_data_a       <= #2 {pd_FQ_din,7'b0,pd_FQ_tail};
                        ram_in_enable_a     <= #2 1;
                        
//                                                        tail
//                        0       1       2       3       4
//                        {1,0} {2,1}    {3,2}    {4,3}   {Y,4}
                        
//                        {next pointer, pointer to cell data memory}
                        
                        pd_FQ_tail             <= #2 pd_FQ_din[9:0];
                        fq_wr_state         <= #2 1;
                    end
                end
                1:  begin
                    ram_in_enable_a     <= #2 0;
                    fq_wr_state         <= #2 0;
                end
            endcase
        end
    end


// headdrop 模块 free queue write
    reg [2:0] fq_hd_wr_state;
    reg [8:0] ram_addr_a_hd;
    reg [127:0] ram_in_data_a_hd;
    reg ram_in_enable_a_hd;
    always@(posedge clk or negedge rstn) begin 
        if(!rstn) begin 
            fq_hd_wr_state<=#2 0;
            ram_addr_a_hd<=#2 0;
            ram_in_data_a_hd<=#2 0;
            ram_in_enable_a_hd<=#2 0;
        end
        else begin 
            case(fq_hd_wr_state)
            0:  begin
                    if(main_state != RST && pd_FQ_wr_hd) begin
                        ram_addr_a_hd          <= #2 pd_FQ_tail;
                        ram_in_data_a_hd       <= #2 {pd_FQ_din_hd,7'b0,pd_FQ_tail};
                        ram_in_enable_a_hd     <= #2 1;
                        pd_FQ_tail             <= #2 pd_FQ_din_hd[9:0];
                        fq_wr_state         <= #2 1;
                    end
                end
                1:  begin
                    ram_in_enable_a_hd     <= #2 0;
                    fq_wr_state         <= #2 0;
                end
            endcase 
        end
    end


    reg [127:0]   port_list_head  [3:0];
    reg [127:0]   port_list_tail  [3:0];
    
    reg [9:0]   port_frame_num  [3:0];
    reg         port_can_read   [3:0];
    
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            port_frame_num[0]           <= #2 0;
            port_frame_num[1]           <= #2 0;
            port_frame_num[2]           <= #2 0;
            port_frame_num[3]           <= #2 0;
        end else begin
            port_can_read[0]            <= #2 (port_frame_num[0]>=1)?1:0;
            port_can_read[1]            <= #2 (port_frame_num[1]>=1)?1:0;
            port_can_read[2]            <= #2 (port_frame_num[2]>=1)?1:0;
            port_can_read[3]            <= #2 (port_frame_num[3]>=1)?1:0;
        end
     end


    // Add a pointer into one of the port's linked list's tail;
    // use ram's port A
    // from Admission control - write into qc                                        
    //      input       [ 3:0]  qc_wr_ptr_wr_en     Write enable for each queue channel
    //      input       [15:0]  qc_wr_ptr_din       Data input for the write pointer   
    //      output reg  [ 3:0]  qc_ptr_full         Queue full status output           
                                                                                
    reg [2:0]   qc_wr_state;
    wire [2:0]  port_in_number;
    assign port_in_number  = (pd_qc_wr_ptr_wr_en[3] == 1)?3:
                             (pd_qc_wr_ptr_wr_en[2] == 1)?2:
                             (pd_qc_wr_ptr_wr_en[1] == 1)?1:
                             0;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            qc_wr_state         <= #2 0;
            ram_in_enable_b<=#2 0;
            ram_in_data_b <=#2 0;
            port_list_head[0] <=#2 128'b1;
            port_list_head[1] <=#2 128'b1;
            port_list_head[2] <=#2 128'b1;
            port_list_head[3] <=#2 128'b1;
            port_list_tail[0] <=#2 128'b1;
            port_list_tail[1] <=#2 128'b1;
            port_list_tail[2] <=#2 128'b1;
            port_list_tail[3] <=#2 128'b1;

        end else begin // 先不考虑多播
            case(qc_wr_state)
                0:  begin
                    if(main_state != RST && pd_qc_wr_ptr_wr_en) begin
                        if(port_frame_num[port_in_number] == 0) begin 
                            port_list_head[port_in_number] <=#2 pd_qc_wr_ptr_din;
                            port_list_tail[port_in_number] <=#2 pd_qc_wr_ptr_din;

                        end
                        else if(port_frame_num[port_in_number] == 1) begin 
                            port_list_head[port_in_number] <=#2 {port_list_head[port_in_number][127:32], 
                                                                pd_qc_wr_ptr_din[15:0], 
                                                                port_list_head[port_in_number][15:0]};

                            ram_addr_b                      <= #2 port_list_tail[port_in_number][8:0];
                            ram_in_data_b                   <= #2 {port_list_tail[port_in_number][127:32], 
                                                                   pd_qc_wr_ptr_din[15:0],
                                                                   port_list_tail[port_in_number][15:0]};
                            ram_in_enable_b                 <= #2 1;    
                            port_list_tail[port_in_number] <=#2 pd_qc_wr_ptr_din;
                        end
                        else begin 
                            ram_addr_b                      <= #2 port_list_tail[port_in_number][8:0];
                            ram_in_data_b                   <= #2 {port_list_tail[port_in_number][127:32], 
                                                                   pd_qc_wr_ptr_din[15:0],
                                                                   port_list_tail[port_in_number][15:0]};
                            ram_in_enable_b                 <= #2 1;    
                            port_list_tail[port_in_number]  <= #2 pd_qc_wr_ptr_din; 
                        
                        end 

                        port_frame_num[port_in_number] <= #2 port_frame_num[port_in_number] + 1;
                        qc_wr_state                     <= #2 1;
                    end
                end
                1:  begin
                    ram_in_enable_b     <= #2 0;
                    qc_wr_state         <= #2 0;
                end
                2:  begin
                    qc_wr_state         <= #2 1;
                end
            endcase
            
        end
    end  
    
    
    // read pointer from one port's linked list's head;
    // from Cell read operations - read from qc                                       
    //      output      [3:0]   ptr_rdy         Ready signals for each pointer      
    //      input       [3:0]   ptr_ack         Acknowledge signals for each pointer
    //      output      [63:0]  ptr_dout        Data output for the pointers        

// 合并cell read的读取和headdrop的读取， 保证cell read的读取有绝对优先权

    reg     [2:0]   qc_rd_state;
    wire    [2:0]   port_out_number;
    wire [2:0] port_out_number_hd;
    assign port_out_number = ((pd_ptr_ack[3]&pd_ptr_rdy[3]) == 1)?3:
                             ((pd_ptr_ack[2]&pd_ptr_rdy[2]) == 1)?2:
                             ((pd_ptr_ack[1]&pd_ptr_rdy[1]) == 1)?1:
                             0;
    assign port_out_number_hd = ((pd_ptr_ack_hd[3]&pd_ptr_rdy[3]) == 1) ? 3: 
                                ((pd_ptr_ack_hd[2]&pd_ptr_rdy[2]) == 1) ? 2: 
                                ((pd_ptr_ack_hd[1]&pd_ptr_rdy[1]) == 1) ? 1:
                                0;
    reg [2:0] port_out_tmp; 
    reg [127:0] last_head;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            qc_rd_state                 <= #2 0;
            ram_out_enable_a <=#2 0;
            last_head<=#2 0;
            port_out_tmp<=#2 0;
        end else begin
            case(qc_rd_state)
                0:  begin
                    if(main_state != RST) begin
                        if(pd_ptr_ack) begin 
                            ram_addr_a<=#2 port_list_head[port_out_number][24:16];
                            ram_out_enable_a<=#2 1;
                            port_out_tmp <=#2 port_out_number;
                            qc_rd_state<=#2 1;
                        end
                        else if(pd_ptr_ack_hd) begin 
                            ram_addr_a<=#2 port_list_head[port_out_number_hd][24:16];
                            ram_out_enable_a<=#2 1;
                            port_out_tmp <=#2 port_out_number_hd;
                            qc_rd_state<=#2 2;
                        end
                    end
                end
                1: begin 
                    ram_out_enable_a<=#2 0;
                    #2 port_list_head[port_out_tmp] <=#2 ram_out_data_a;
                    qc_rd_state<=#2 2; 
                end
                2: begin 
                    port_frame_num[port_out_tmp] <=#2 port_frame_num[port_out_tmp] - 1;
                    qc_rd_state<=#2 0;
                end
                3: begin 
                    if(pd_ptr_ack) begin 
                        ram_addr_a<=#2 port_list_head[port_out_number][24:16];
                        ram_out_enable_a<=#2 1;
                        port_out_tmp <=#2 port_out_number;
                        qc_rd_state<=#2 1; 
                    end
                    else begin 
                        ram_out_enable_a<=#2 0;
                        #2 port_list_head[port_out_tmp] <=#2 ram_out_data_a;
                        qc_rd_state<=#2 4;
                        last_head<=#2 port_list_head[port_out_tmp];
                    end
                end
                4: begin 
                    if(pd_ptr_ack) begin 
                        //此时cell read可能读取到旧值，需要依据旧值来更新
                        ram_addr_a <=#2 port_out_number == port_out_tmp ? last_head : port_list_head[port_out_number][24:16];
                        ram_out_enable_a<=#2 1;
                        port_out_tmp<=#2 port_out_number;
                        qc_rd_state<=#2 1;
                    end
                    else begin 
                        port_frame_num[port_out_tmp] <=#2 port_frame_num[port_out_tmp] - 1;
                        qc_rd_state<=#2 0;
                    end
                end
            endcase
        end
    end
    

    

    
    
    reg     [8:0]   rst_index;
    reg     [2:0]   main_state;
    wire    [5:0]   main_sig;
    assign main_sig = {pd_FQ_rd, pd_FQ_wr, pd_qc_wr_ptr_wr_en};
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            pd_qc_ptr_full                     <= #2 0;
            main_state                      <= #2 RST;
            rst_index                       <= #2 0;
            
            port_list_tail[0]               <= #2 0;
            port_list_tail[1]               <= #2 0;
            port_list_tail[2]               <= #2 0;
            port_list_tail[3]               <= #2 0;
            port_list_head[0]               <= #2 0;
            port_list_head[1]               <= #2 0;
            port_list_head[2]               <= #2 0;
            port_list_head[3]               <= #2 0;
        end else begin
            case(main_state)
                // Reset state:
                //  In the reset state, the pointer list stored in ptr_list_memory 
                //  is set in the order of 0->1->2->...->n.
                //  Pointer: 16bits-Next Ptr + 16bits-Current Ptr
                RST: begin
                    if(rst_index == 511) begin
                        rst_index           <= #2 0;
                        ram_in_data_a       <= #2 {96'b0, 23'b0,rst_index[8:0]};
                        ram_addr_a          <= #2 rst_index;
                        ram_in_enable_a     <= #2 1;
                        
                        main_state          <= #2 IDLE;

                    end else begin
                        rst_index           <= #2 rst_index + 1;
                        ram_in_data_a       <= #2 {96'b0, 7'b0, rst_index[8:0]+1, 7'b0, rst_index[8:0]};            
                        ram_addr_a          <= #2 rst_index;
                        ram_in_enable_a     <= #2 1;
                        
                        main_state          <= #2 RST;
                    end
                end
                
                IDLE: begin
                    ram_in_enable_a         <= #2 0;
                    casez(main_sig)
                        6'b10????: begin
                            main_state <= #2 FQ_RD;
                        end
                        6'b01????: begin
                            main_state <= #2 FQ_WR;
                        end
                        6'b11????: begin
                            
                        end
                        6'b00????: begin
                            main_state <= #2 QC_WR;
                        end                 
                    endcase
                    
                end
                default: begin
                    main_state              <= #2 IDLE;
                end
            endcase
        end
    end

    reg [8:0]   ram_addr_a;
    reg [8:0]   ram_addr_b;

    reg         ram_in_enable_a;
    reg [127:0]  ram_in_data_a;
    
    reg         ram_in_enable_b;
    reg [127:0]  ram_in_data_b;
    
    reg         ram_out_enable_a;
    wire [127:0]  ram_out_data_a;
                    
    reg         ram_out_enable_b;
    wire [127:0]  ram_out_data_b; 

    always@(posedge clk or negedge rstn) begin 
        if(!rstn) begin 
            ram_addr_a <=#2 0;
            ram_addr_b <=#2 0;
            ram_in_enable_a<=#2 0;
            ram_in_enable_b<=#2 0;
            ram_in_data_a<=#2 0;
            ram_in_data_b<=#2 0;
            ram_out_enable_a<=#2 0;
            ram_out_enable_b<=#2 0;
        end
    end
    
    wire [8:0] ram_addr_a_s;
    wire [127:0] ram_in_data_a_s;
    wire ram_in_enable_a_s;
    assign ram_addr_a_s = (ram_in_enable_a | ram_out_enable_a) ? ram_addr_a : (ram_in_enable_a_hd ? ram_addr_a_hd : ram_addr_a);
    assign ram_in_data_a_s = (ram_in_enable_a | ram_out_enable_a) ? ram_in_data_a : (ram_in_enable_a_hd ? ram_in_data_a_hd : ram_in_data_a);
    assign ram_in_enable_a_s = ram_in_enable_a | ram_in_enable_a_hd;

    dpsram_w128_d512 ptr_list_memory(
      .clka(clk),
      .clkb(clk),
      			
      .addra(ram_addr_a_s),
      .addrb(ram_addr_b),
      	
      .wea(ram_in_enable_a_s),
      .dina(ram_in_data_a_s),
      	
      .web(ram_in_enable_b),
      .dinb(ram_in_data_b),
      
      .ena(1),
      .douta(ram_out_data_a),
      
      .enb(1),
      .doutb(ram_out_data_b)
    );

endmodule