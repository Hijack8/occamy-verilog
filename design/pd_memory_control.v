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
    output      [511:0]     pd_ptr_dout
    
);
   
    // Ready signals for each port
    assign pd_ptr_rdy = {port_can_read[3], port_can_read[2], port_can_read[1], port_can_read[0]};

    // Acknowledge signals for each port
    wire            pd_ptr_ack0, pd_ptr_ack1, pd_ptr_ack2, pd_ptr_ack3;
    assign {pd_ptr_ack3, pd_ptr_ack2, pd_ptr_ack1, pd_ptr_ack0} = pd_ptr_ack;
    
    // Data output for the port
    reg [15:0]		qc_rd_ptr_dout [3:0];
    assign pd_ptr_dout = {qc_rd_ptr_dout[3], qc_rd_ptr_dout[2], qc_rd_ptr_dout[1], qc_rd_ptr_dout[0]};
    
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
     
    assign pd_ptr_dout_s = FQ_head[8:0];
    
     
    reg [2:0]   fq_rd_state;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            fq_rd_state                 <= #2 0;
        end else begin
            case(fq_rd_state)
                0:  begin
                    if(main_state != RST && FQ_rd && !FQ_empty) begin
                        
                        ram_addr_b          <= #2 FQ_head;
                        ram_out_enable_b    <= #2 1;
                        fq_rd_state         <= #2 1;
                    end
                end
                1:  begin
                    
                   #2 FQ_head          <=  ram_out_data_b[24:16];
                   ram_out_enable_b    <= #2 0;
                   fq_rd_state         <= #2 0;
                end
//                2:  begin
//                   #2 FQ_head          <=  ram_out_data_b[9:0];
//                   #2 ram_addr_b          <=  ram_out_data_b[25:16];
//                   fq_rd_state         <= #2 3;
//                end
//                3:  begin
//                   #2 FQ_head          <=  ram_out_data_b[9:0];
//                   #2 ram_addr_b          <=  ram_out_data_b[25:16];
//                   fq_rd_state         <= #2 4;

//                end  
//                4:  begin
//                   #2 FQ_head             <=  ram_out_data_b[25:16];
//                   #2 ram_out_enable_b    <=  0;
//                   fq_rd_state          <= #2 0;
//                end               
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
                    if(main_state != RST && FQ_wr) begin
                        ram_addr_a          <= #2 FQ_tail;
                        ram_in_data_a       <= #2 {FQ_din,7'b0,FQ_tail};
                        ram_in_enable_a     <= #2 1;
                        
//                                                        tail
//                        0       1       2       3       4
//                        {1,0} {2,1}    {3,2}    {4,3}   {Y,4}
                        
//                        {next pointer, pointer to cell data memory}
                        
                        FQ_tail             <= #2 FQ_din[9:0];
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


    reg [15:0]   port_list_head  [3:0];
    reg [15:0]   port_list_tail  [3:0];
    
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
    assign port_in_number  = (qc_wr_ptr_wr_en[3] == 1)?3:
                             (qc_wr_ptr_wr_en[2] == 1)?2:
                             (qc_wr_ptr_wr_en[1] == 1)?1:
                             0;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            qc_wr_state         <= #2 0;
        end else begin // 先不考虑多播
            case(qc_wr_state)
                0:  begin
                    if(main_state != RST && qc_wr_ptr_wr_en) begin
                    
                        ram_addr_a                      <= #2 port_list_tail[port_in_number][8:0];
                        ram_in_data_a                   <= #2 {qc_wr_ptr_din,port_list_tail[port_in_number]};
                        ram_in_enable_a                 <= #2 1;    
                        port_list_tail[port_in_number]  <= #2 qc_wr_ptr_din; 
                        
                        qc_wr_state                     <= #2 1;
                        
                        if(qc_wr_ptr_din[15]) begin
                            port_frame_num[port_in_number] <= #2 port_frame_num[port_in_number] + 1;
                        end
                    end
                end
                1:  begin
                    ram_in_enable_a     <= #2 0;
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

    reg     [2:0]   qc_rd_state;
    wire    [2:0]   port_out_number;
    assign port_out_number = ((ptr_ack[3]&ptr_rdy[3]) == 1)?3:
                             ((ptr_ack[2]&ptr_rdy[2]) == 1)?2:
                             ((ptr_ack[1]&ptr_rdy[1]) == 1)?1:
                             0;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            qc_rd_state                 <= #2 0;
        end else begin
            case(qc_rd_state)
                0:  begin
                    if(main_state != RST && (ptr_ack&ptr_rdy)) begin
                        ram_addr_b                      <= #2 port_list_head[port_out_number][8:0];
                        qc_rd_ptr_dout[port_out_number] <= #2 port_list_head[port_out_number];
                        ram_out_enable_b                <= #2 1;
                        qc_rd_state                     <= #2 1;
                    end
                end
                1:  begin
                    ram_out_enable_b                    <= #2 0;
                    qc_rd_state                         <= #2 2;
                end
                2:  begin
                    port_list_head[port_out_number]     <= #2 ram_out_data_b[31:16];
                    qc_rd_state                         <= #2 0;
                end
            endcase
        end
    end
    
    
    
    reg     [8:0]   rst_index;
    reg     [2:0]   main_state;
    wire    [5:0]   main_sig;
    assign main_sig = {FQ_rd, FQ_wr, qc_wr_ptr_wr_en};
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            qc_ptr_full                     <= #2 0;
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
                        ram_in_data_a       <= #2 {23'b0,rst_index[8:0]};
                        ram_addr_a          <= #2 rst_index;
                        ram_in_enable_a     <= #2 1;
                        
                        main_state          <= #2 IDLE;

                    end else begin
                        rst_index           <= #2 rst_index + 1;
                        ram_in_data_a       <= #2 {7'b0, rst_index[8:0]+1, 7'b0, rst_index[8:0]};            
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
    reg [31:0]  ram_in_data_a;
    
    reg         ram_in_enable_b;
    reg [31:0]  ram_in_data_b;
    
    reg         ram_out_enable_a;
    wire [31:0]  ram_out_data_a;
                    
    reg         ram_out_enable_b;
    wire [31:0]  ram_out_data_b; 
    
    dpsram_w128_d512 ptr_list_memory(
      .clka(clk),
      .clkb(clk),
      			
      .addra(ram_addr_a),
      .addrb(ram_addr_b),
      	
      .wea(ram_in_enable_a),
      .dina(ram_in_data_a),
      	
      .web(ram_in_enable_b),
      .dinb(ram_in_data_b),
      
      .ena(1),
      .douta(ram_out_data_a),
      
      .enb(1),
      .doutb(ram_out_data_b)
    );

endmodule
