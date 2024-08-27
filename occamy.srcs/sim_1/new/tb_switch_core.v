`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/27 10:43:19
// Design Name: 
// Module Name: tb_switch_core
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


module tb_switch_core();

reg clk, rstn;
reg [127:0] data_in;
reg data_wr;
reg [15:0] i_cell_ptr_fifo_din;
reg i_cell_ptr_fifo_wr;

wire data_valid;
wire [127:0] data_dout;

switch_core_v2 switch_core(
    .clk(clk),
    .rstn(rstn),

    .data_in(data_in),
    .data_wr(data_wr),
    .i_cell_ptr_fifo_din(i_cell_ptr_fifo_din),
    .i_cell_ptr_fifo_wr(i_cell_ptr_fifo_wr),

    .data_valid(data_valid),
    .data_dout(data_dout)
);

integer i;
    //============== (0) ==================
    //main      
    initial begin
        #6213;
        
        
        input_a_frame(16'b0000_0010_00_000100, 0000);
        input_a_frame(16'b0000_0100_00_000100, 0011);
        input_a_frame(16'b0000_0100_00_000100, 1010);

        for(i = 0; i < 100; i =i + 1) begin 
            input_a_frame(16'b0000_0010_00_000100, 0000);
        end
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
        
        // #25500
        // #18 rstn     = 1'b0 ;
        // #18 rstn     = 1'b1 ;
        // #300
        // $finish;
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
