`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/23 20:42:52
// Design Name: 
// Module Name: sram_tb
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


module sram_tb;

reg clk, ptr_ram_wr;
reg[8:0] ptr_ram_addr;
reg[15:0] ptr_ram_din;
wire[15:0] ptr_ram_dout;


sram_w16_d512 u_ptr_ram (
  .clka(clk), 			
  .wea(ptr_ram_wr),     
  .addra(ptr_ram_addr[8:0]), 
  .dina(ptr_ram_din),   
  .douta(ptr_ram_dout),
  .ena(1)
);	

always #5 clk = ~clk;
initial begin
    clk = 0;
    ptr_ram_wr = 0;
    ptr_ram_addr = 0;
    ptr_ram_din = 0;
    
    #100;
    ptr_ram_wr = 1;
    ptr_ram_addr = 1;
    ptr_ram_din = 111;
    
    #100;
    ptr_ram_addr = 2;
    ptr_ram_din = 222;
    
    #100;
    ptr_ram_wr = 0;
    ptr_ram_addr = 1;
    
    
    #100;
    ptr_ram_addr = 2;
end


endmodule
