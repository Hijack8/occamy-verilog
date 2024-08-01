`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/29 19:54:53
// Design Name: 
// Module Name: headdrop
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


module headdrop(
    input clk,
    input rstn,
    
    input [3:0] ptr_rdy,
    output reg [3:0] headdrop_en,
    output FQ_wr,
    output [15:0] FQ_din,
    
    input [3:0] pd_ptr_rdy,
    output [3:0] pd_ptr_ack,
    output FPDQ_wr,
    output [127:0] FPDQ_din,

    input [63:0] cell_ptr_dout,
    input [511:0] pd_dout,

    input [3:0] fail,
    
    input [3:0] bitmap,
    output reg[1:0] out_port,
    output reg out,
    output reg [10:0] pkt_len_out
    );
    

reg[1:0] RR;
reg[3:0] state;
wire [3:0] rdy;
reg[5:0] cell_num_reg;
wire [5:0] cell_num;
assign rdy = (ptr_rdy & pd_ptr_rdy & ~bitmap);

wire[15:0] qc_rd_ptr_dout0, qc_rd_ptr_dout1, qc_rd_ptr_dout2, qc_rd_ptr_dout3;
wire[127:0] pd_qc_rd_ptr_dout0, pd_qc_rd_ptr_dout1, pd_qc_rd_ptr_dout2, pd_qc_rd_ptr_dout3;

assign {qc_rd_ptr_dout3, qc_rd_ptr_dout2, qc_rd_ptr_dout1, qc_rd_ptr_dout0} = cell_ptr_dout;
assign {pd_qc_rd_ptr_dout3, pd_qc_rd_ptr_dout2, pd_qc_rd_ptr_dout1, pd_qc_rd_ptr_dout0} = pd_dout;

reg [15:0] cell_ptr_buffer[10:0];
reg [5:0] cell_ptr_buffer_idx;
reg[3:0] map;

always @(posedge clk or negedge rstn) begin
if(!rstn) begin
    RR<=#2 0;
    state<=#2 0;
    cell_num_reg<=#2 0;
    
    pkt_len_out<=#2 0;
    out<=#2 0;
    out_port<=#2 0;

    cell_ptr_buffer_idx<=#2 0;

    map<=#2 0;
end
else begin
case(state)
0:begin
    // RR find a queue num 0
    if(rdy[0]) begin
        headdrop_en[0]<=#2 1;
        FPDQ_din<=#2 pd_qc_rd_ptr_dout0;
        cell_num_reg<=#2 pd_qc_rd_ptr_dout0[15:10];
        state<=#2 1; 
        out_port<=#2 0;
        pkt_len_out<=#2 pd_qc_rd_ptr_dout0[26:16];
        map<=#2 4'b0001;
    end
end
1: begin
    headdrop_en<=#2 0;
    if(fail[out_port]) begin
        cell_ptr_buffer_idx<=#2 0;
        state<=#2 0;
    end
    else begin 
        case(map)
        4'b0001: begin 
            cell_ptr_buffer[cell_ptr_buffer_idx]<=#2 qc_rd_ptr_dout0; 
        end
        4'b0010: begin 
            cell_ptr_buffer[cell_ptr_buffer_idx]<=#2 qc_rd_ptr_dout1;
        end
        4'b0100: begin 
            cell_ptr_buffer[cell_ptr_buffer_idx]<=#2 qc_rd_ptr_dout2;
        end
        4'b1000: begin 
            cell_ptr_buffer[cell_ptr_buffer_idx]<=#2 qc_rd_ptr_dout3;
        end 
        endcase
        cell_ptr_buffer_idx<=#2 (cell_ptr_buffer_idx + 1);
        cell_num_reg<=#2 cell_num_reg - 1;
        if(cell_num_reg == 1) begin
            state<=#2 2;
        end
    end 
end
2: begin
    // headdrop success
    // free ptr 
    FQ_din<=#2 cell_ptr_buffer[cell_ptr_buffer_idx - 1];
    FQ_wr<=#2 1;
    cell_ptr_buffer_idx<=#2 cell_ptr_buffer_idx - 1;
    if(cell_ptr_buffer_idx == 1) begin
        FPDQ_wr<=#2 1;
        state<=#2 0;
    end
end
endcase
end
end

assign cell_num = FPDQ_din[15:10];
    
endmodule
