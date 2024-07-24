`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/22 14:22:33
// Design Name: 
// Module Name: statistics
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


module statistics(
    input clk,
    input rstn,
    input in,
    input out,
    input [3:0] in_port,
    input [3:0] out_port,
    input[10:0] pkt_len_in,
    input[10:0] pkt_len_out,
    output[3:0] bitmap
    );
    
    parameter alpha_shift = 0;
    parameter buffer_size = 32768;// 32KB
    
    wire [1:0] sig;
    reg [31:0] qlen[3:0];
    assign sig = {in, out};
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            qlen[0]<=#2 0;
            qlen[1]<=#2 0;
            qlen[2]<=#2 0;
            qlen[3]<=#2 0;
        end
        else begin
            case(sig)
            2'b01: begin
                qlen[out_port]<=#2 qlen[out_port] - pkt_len_out; 
            end
            2'b10: begin
                qlen[in_port] <=#2 qlen[in_port] + pkt_len_in;
            end
            2'b11: begin
                if(in_port == out_port) qlen[in_port] <= #2 qlen[in_port] + pkt_len_in - pkt_len_out;
                else begin
                    qlen[in_port] <=#2 qlen[in_port] + pkt_len_in;
                    qlen[out_port] <=#2 qlen[out_port] - pkt_len_out;
                end
            end
            endcase
        end
    end
    
    wire [31:0] T;
    assign T = ((buffer_size) - qlen[0] - qlen[1] - qlen[2] - qlen[3]) >> alpha_shift;
    assign bitmap = {qlen[3] < T, qlen[2] < T, qlen[1] < T, qlen[0] < T};
endmodule
