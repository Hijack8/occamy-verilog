`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/26 09:44:01
// Design Name: 
// Module Name: cell_link
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


module cell_link(
    input clk,
    input rstn,
    input wr_en,
    input rd_en,
    input[8:0] cell_ptr,
    input[31:0] free_head,
    output reg sram_wr,
    output reg [8:0] sram_addr,
    output reg [31:0] sram_din,
    input[31:0] sram_dout,
    output reg[31:0] new_free_head
    );
reg[31:0] head;
reg[31:0] tail;
reg[1:0] wr_state;
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        head<=#2 0;
        tail<=#2 0;
        wr_state<=#2 0;
        new_free_head<=#2 0;
    end else begin 
    case(wr_state)
    0: begin
        if(wr_en) begin
            sram_addr<=#2 free_head[24:16];
            wr_state<=#2 1;
            
        end
    end
    1: begin
        if(head == 0 && tail == 0) begin
            // update link list
            head<=#2 free_head[24:16];
//            tail<=#2 free_head[24:16];
            // update free_head
            new_free_head<=#2 sram_dout;                
        end 
        else begin
//            tail<=#2 free_head[24:16];
        end
        sram_wr<=#2 1;
        sram_addr<=#2 free_head[24:16];
        sram_din<=#2 {7'b0, sram_addr, 16'b0};
        wr_state<=#2 2;
    end
    2: begin
        sram_addr<=#2 tail;
        sram_din<=#2 {7'b0, tail, 7'b0, sram_addr};
        wr_state<=#2 3;
    end
    3: begin
        sram_wr<=#2 0;
        wr_state<=#2 0;
    end
    endcase
    end
end
reg[1:0] rd_state;
always@(posedge clk or negedge rstn) begin
if(!rstn) begin
    rd_state<=#2 0;
end
else begin
    case(rd_state)
    0: begin
        if(rd_en) begin
            sram_din<=#2 head[8:0];
            rd_state<=#2 1;
        end
    end
    1: begin
        head<=#2 sram_dout;
        sram_wr<=#2 1;
        sram_din<=#2 {7'b0, head[8:0], 7'b0, free_head[24:16]};
        new_free_head<=#2 {7'b0, head[8:0], 7'b0, free_head[24:16]};
        rd_state<=#2 2;
    end
    2: begin
        sram_wr<=#2 0;
        rd_state<=#2 0;
    end
    endcase
end
end
endmodule
