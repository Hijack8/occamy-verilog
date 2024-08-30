`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/05 17:21:49
// Design Name: 
// Module Name: cell_linked_list_ios
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


module cell_pointer_memory_control #(
    parameter RST = 3'b000,
    parameter IDLE  = 3'b001,
    parameter FQ_WR = 3'b010,
    parameter FQ_RD = 3'b011,
    parameter QC_WR = 3'b100,
    parameter QC_RD = 3'b101,
    parameter ENDRST = 3'b110
)(

    input               clk,              // Clock input
    input               rstn,             // Asynchronous reset, active low

    // Admission control - read from free queue
    input               FQ_rd,            // Read signal for the queue
    output              FQ_empty,         // Queue empty status signal
    output      [9:0]   ptr_dout_s,       // Pointer data output (short)
    // Admission control - write into qc
    input          qc_wr_ptr_wr_en,  // Write enable for each queue channel
    input       [15:0]  qc_wr_ptr_din,    // Data input for the write pointer
    input       [15:0]  qc_wr_preptr_din, // queue collector (qc) 写指针(pre)数据输入
    output reg qc_ptr_full,
    
    // Cell read operations - write into queue
    input               FQ_wr,            // Write signal for the queue
    input       [15:0]  FQ_din_head,           // Data input for the queue
    input [15:0] FQ_din_tail,
    // Cell read operations - read from qc
    input cell_mem_rd, 
    output reg [31:0] cell_mem_dout,
    input [15:0] cell_mem_addr,

    input FQ_wr_hd,
    input [15:0] FQ_din_head_hd,
    input [15:0] FQ_din_tail_hd
);
   
always@(posedge clk) qc_ptr_full <= 0;


    reg [9:0]   FQ_head;
    reg [9:0]   FQ_tail;
    assign FQ_empty = (FQ_head == FQ_tail)?1:0;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            FQ_head                     <= #2 0;
            FQ_tail                     <= #2 511;
         end
     end


    assign ptr_dout_s = FQ_head[9:0];
    
    reg [2:0]   fq_rd_state;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            fq_rd_state                 <= #2 0;
            ram_out_enable_b<=#2 0;
            ram_addr_b_1 <=#2 0;
        end else begin
            case(fq_rd_state)
                0:  begin
                    if(main_state != RST && FQ_rd && !FQ_empty) begin
                        ram_addr_b_1          <= #2 FQ_head;
                        ram_out_enable_b    <= #2 1;
                        fq_rd_state         <= #2 1;
                    end
                end
                1:  begin
                   #2 FQ_head          <=  ram_out_data_b[24:16];
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
            ram_addr_a_1 <=#2 0;
            ram_in_enable_a <=#2 0;
            ram_in_data_a <=#2 0;
        end else begin
            case(fq_wr_state)
                0:  begin
                    if(main_state != RST && FQ_wr) begin
                        ram_addr_a_1          <= #2 FQ_tail;
                        ram_in_data_a       <= #2 {FQ_din_head,7'b0,FQ_tail};
                        ram_in_enable_a     <= #2 1;
                                     
                        FQ_tail             <= #2 FQ_din_tail[9:0];
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

    // Add a pointer into one of the port's linked list's tail;
    // use ram's port A
    // from Admission control - write into qc                                        
    //      input       [ 3:0]  qc_wr_ptr_wr_en     Write enable for each queue channel
    //      input       [15:0]  qc_wr_ptr_din       Data input for the write pointer
    //      inpu        [15:0]   qc_wr_preptr_din
    //      output reg  [ 3:0]  qc_ptr_full         Queue full status output           
                                                                                
    reg [2:0]   qc_wr_state;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            qc_wr_state         <= #2 0;
            ram_in_enable_b<=#2 0;
            ram_addr_b_2<=#2 0;
            ram_in_data_b<=#2 0;
        end else begin // 先不考虑多播
            case(qc_wr_state)
                0:  begin
                    if(main_state != RST && qc_wr_ptr_wr_en) begin    
                        ram_addr_b_2          <= #2 qc_wr_preptr_din[8:0];
                        ram_in_data_b       <= #2 {qc_wr_ptr_din, qc_wr_preptr_din};
                        if(!qc_wr_ptr_din[14])
                            ram_in_enable_b         <= #2 1;
                        else
                            ram_in_enable_b         <= #2 0;
                            
                        qc_wr_state     <= #2 1;
                            
                    end
                end
                1:  begin
                    ram_in_enable_b     <= #2 0;
                    qc_wr_state         <= #2 0;
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

    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            qc_rd_state                 <= #2 0;
            cell_mem_dout<=#2 0;
            ram_out_enable_a<=#2 0;
            ram_addr_a_2 <=#2 0;
        end else begin
            case(qc_rd_state)
                0:  begin
                    if(main_state != RST && cell_mem_rd) begin
                        ram_addr_a_2                      <= #2 cell_mem_addr; 
                        ram_out_enable_a                <= #2 1;
                        qc_rd_state                     <= #2 1;
                    end
                    // else ram_out_enable_a <=#2 0;
                end
                1:  begin
                    #1 cell_mem_dout <= ram_out_data_a;
                    qc_rd_state                         <= #2 0;
                    ram_out_enable_a <=#2 0;
                end
            endcase
        end
    end
    
    
    
    reg     [8:0]   rst_index;
    reg     [2:0]   main_state;
    wire    [5:0]   main_sig;
    assign main_sig = {FQ_rd, FQ_wr, qc_wr_ptr_wr_en, 3'b0};
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            main_state                      <= #2 RST;
            rst_index                       <= #2 0;


        end else begin
            case(main_state)
                // Reset state:
                //  In the reset state, the pointer list stored in ptr_list_memory 
                //  is set in the order of 0->1->2->...->n.
                //  Pointer: 16bits-Next Ptr + 16bits-Current Ptr
                //
                //      head                            tail
                //      0       1       2       3       4
                //      {1,0} {2,1}    {3,2}    {4,3}   {Y,4}  
                //          
                //      {next pointer, pointer to cell data memory}
                RST: begin
                    if(rst_index == 511) begin
                        rst_index           <= #2 0;
                        ram_in_data_a_rst       <= #2 {23'b0,rst_index[8:0]};
                        ram_addr_a_rst          <= #2 rst_index;
                        ram_in_enable_a_rst     <= #2 1;
                        
                        main_state          <= #2 ENDRST;
                    end else begin
                        rst_index           <= #2 rst_index + 1;
                        ram_in_data_a_rst       <= #2 {7'b0, rst_index[8:0]+1, 7'b0, rst_index[8:0]};            
                        ram_addr_a_rst          <= #2 rst_index;
                        ram_in_enable_a_rst     <= #2 1;
                        
                        main_state          <= #2 RST;
                    end
                end
                
                ENDRST: begin
                    ram_in_enable_a_rst     <= #2 0;
                    main_state          <= #2 IDLE;
                end
                
                IDLE: begin
//                    casez(main_sig)
//                        6'b10????: begin
//                            main_state <= #2 FQ_RD;
//                        end
//                        6'b01????: begin
//                            main_state <= #2 FQ_WR;
//                        end
//                        6'b11????: begin
                            
//                        end
//                        6'b00????: begin
//                            main_state <= #2 QC_WR;
//                        end                 
//                    endcase              
                end
                default: begin
                    main_state              <= #2 IDLE;
                end
            endcase
        end
    end

    reg [2:0] fq_hd_wr_state;
    reg [8:0] ram_addr_a_hd;
    reg [31:0] ram_in_data_a_hd;
    reg ram_in_enable_a_hd;
    always@(posedge clk or negedge rstn) begin 
        if(!rstn) begin 
            fq_hd_wr_state<=#2 0;
            ram_in_enable_a_hd<=#2 0;
            ram_addr_a_hd<=#2 0;
            ram_in_data_a_hd<=#2 0;
        end
        else begin 
            case(fq_hd_wr_state)
            0:  begin
                    if(main_state != RST && FQ_wr_hd) begin
                        ram_addr_a_hd          <= #2 FQ_tail;
                        ram_in_data_a_hd       <= #2 {FQ_din_head_hd,7'b0,FQ_tail};
                        ram_in_enable_a_hd     <= #2 1;
                                     
                        FQ_tail             <= #2 FQ_din_tail_hd[9:0];
                        fq_hd_wr_state         <= #2 1;
                    end
                end
                1:  begin
                    ram_in_enable_a_hd     <= #2 0;
                    fq_hd_wr_state         <= #2 0;
                end
            endcase 
        end
    end


    
    
    reg [8:0]   ram_addr_a_1;
    reg [8:0]   ram_addr_a_2;
    reg [8:0]   ram_addr_a_rst;
    reg [8:0]   ram_addr_b_1;
    reg [8:0]   ram_addr_b_2;

    reg         ram_in_enable_a;
    reg         ram_in_enable_a_rst;
    reg [31:0]  ram_in_data_a;
    reg [31:0]  ram_in_data_a_rst;
    
    reg         ram_in_enable_b;
    reg [31:0]  ram_in_data_b;
    
    reg         ram_out_enable_a;
    wire [31:0]  ram_out_data_a;
                    
    reg         ram_out_enable_b;
    wire [31:0]  ram_out_data_b; 

    wire [8:0] ram_addr_a_s;
    wire [8:0] ram_addr_b_s;
    wire [31:0] ram_in_data_a_s;
    wire ram_in_enable_a_s;
    assign ram_addr_a_s = (ram_in_enable_a_rst) ? ram_addr_a_rst : 
                          ram_in_enable_a ? ram_addr_a_1 :
                          ram_out_enable_a ? ram_addr_a_2 : 
                          ram_in_enable_a_hd ? ram_addr_a_hd : 
                          ram_addr_a_1;
    
    assign ram_in_data_a_s = (ram_in_enable_a_rst) ? ram_in_data_a_rst :
                            ram_in_enable_a ? ram_in_data_a : 
                            ram_in_enable_a_hd ? ram_in_data_a_hd :
                            ram_in_data_a;
    
    assign ram_addr_b_s = ram_out_enable_b ? ram_addr_b_1 : 
                          ram_addr_b_2;

    assign ram_in_enable_a_s = ram_in_enable_a | ram_in_enable_a_hd | ram_in_enable_a_rst;
    
    dpsram_w32_d512 ptr_list_memory(
      .clka(clk),
      .clkb(clk),
      			
      .addra(ram_addr_a_s),
      .addrb(ram_addr_b_s),
      	
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