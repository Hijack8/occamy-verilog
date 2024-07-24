`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/24 16:48:41
// Design Name: 
// Module Name: admission
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


module admission(
    input clk,
    input rstn,
    input[127:0] data_in,
    input data_wr,
    input[15:0] i_cell_ptr_fifo_din,
    input i_cell_ptr_fifo_wr,
    
    output reg FQ_rd,
    input FQ_empty,
    input[9:0] ptr_dout_s,
    
    input FPDQ_empty,
    output reg FPDQ_rd,
    input[9:0] pd_ptr_dout_s,
    
    output[11:0] sram_addr,
    output[127:0] sram_din,
    output sram_wr,
    
    output reg[3:0] qc_wr_ptr_wr_en,
    output reg[15:0] qc_wr_ptr_din,
    input qc_ptr_full,

    output reg [3:0]  pd_qc_wr_ptr_wr_en,
    output reg [127:0] pd_qc_wr_ptr_din,
    input pd_qc_ptr_full,
    
    output reg in,
    output  reg [3:0] in_port,
    output reg [10:0] pkt_len_in,
    input[3:0] bitmap,
    
    output reg i_cell_bp
    );
reg 	[3:0]	qc_portmap;

reg i_cell_data_fifo_rd;
wire[127:0] i_cell_data_fifo_dout;
wire[8:0] i_cell_data_fifo_depth;
reg	 [5:0]		cell_number;
reg				i_cell_last;
reg				i_cell_first;

reg  [3:0]		wr_state;		
//wire [9:0]		ptr_dout_s;		
		
reg	 [1:0]		sram_cnt_a;	
reg	 [1:0]		sram_cnt_b;
reg				sram_rd;	
reg				sram_rd_dv;
reg  			i_cell_data_fifo_rd;	
wire [127:0]	i_cell_data_fifo_dout;	
wire [8:0]		i_cell_data_fifo_depth;		

reg				i_cell_ptr_fifo_rd;
wire [15:0]		i_cell_ptr_fifo_dout;
wire			i_cell_ptr_fifo_full;
wire			i_cell_ptr_fifo_empty;
reg  [15:0]		FQ_din;		
reg				FQ_wr;
reg  [9:0]		FQ_dout;
// ADD(PD)
reg [15:0]      FPDQ_din;
reg             FPDQ_wr;
reg [9:0]       FPDQ_dout;	

sfifo_ft_w128_d256 u_i_cell_fifo(
  .clk(clk), 
  .rst(!rstn), 
  .din(data_in[127:0]), 
  .wr_en(data_wr), 
  .rd_en(i_cell_data_fifo_rd), 
  .dout(i_cell_data_fifo_dout[127:0]), 
  .full(), 
  .empty(),
  .data_count(i_cell_data_fifo_depth[8:0])
);
always @(posedge clk) begin
	i_cell_bp<=#2 (i_cell_data_fifo_depth[8:0]>161) | i_cell_ptr_fifo_full;
end

sfifo_ft_w16_d32 u_ptr_fifo (
  .clk(clk), 					// input clk
  .rst(!rstn), 					// input rst
  .din(i_cell_ptr_fifo_din), 	// input [15 : 0] din
  .wr_en(i_cell_ptr_fifo_wr), 	// input wr_en
  .rd_en(i_cell_ptr_fifo_rd), 	// input rd_en
  .dout(i_cell_ptr_fifo_dout), 	// output [15 : 0] dout
  .full(i_cell_ptr_fifo_full), 	// output full
  .empty(i_cell_ptr_fifo_empty),// output empty
  .data_count() 				// output [5 : 0] data_count
);


   
reg first_flg;
wire [10:0] pkt_len;
reg drop;

// pkt_len = cell_number * 64 B
assign pkt_len = {cell_number, 6'd0};


always@(posedge clk or negedge rstn)
	if(!rstn)
		begin
		wr_state<=#2  0;
		FQ_rd<=#2  0;
//		MC_ram_wra<=#2  0;
		sram_cnt_a<=#2  0;
		i_cell_data_fifo_rd<=#2  0;
		i_cell_ptr_fifo_rd<=#2 0;
		qc_wr_ptr_wr_en<=#2  0;
		qc_wr_ptr_din<=#2  0;
		FQ_dout<=#2  0;
		qc_portmap<=#2 0;
		cell_number<=#2 0;
		i_cell_last<=#2 0;
		i_cell_first<=#2 0;
        first_flg<=#2 0;
        
        
        FPDQ_rd<=#2 0;
        FPDQ_dout<=#2  0;
        pd_qc_wr_ptr_wr_en<=#2  0;
        pd_qc_wr_ptr_din<=#2  0;
        
        
        in <= #2 0;
        in_port <= #2 0;
        pkt_len_in <= #2 0;
        drop <=#2 0;
        
		end
	else
		begin
//		MC_ram_wra<=#2  0;
		FQ_rd<=#2  0;
		qc_wr_ptr_wr_en<=#2  0;
		pd_qc_wr_ptr_wr_en<=#2 0;
		i_cell_ptr_fifo_rd<=#2  0;
		case(wr_state)
		0:begin
			sram_cnt_a<=#2  0;
			i_cell_last<=#2 0;
			i_cell_first<=#2 0;
			if(!i_cell_ptr_fifo_empty & !qc_ptr_full & !FQ_empty & !pd_qc_ptr_full & !FPDQ_empty)begin
				i_cell_data_fifo_rd<=#2  1;
				i_cell_ptr_fifo_rd<=#2  1;
                // need cell_number to write/ drop
				cell_number[5:0]<=#2 i_cell_ptr_fifo_dout[5:0];
				if(i_cell_ptr_fifo_dout[5:0]==6'b1) i_cell_last<=#2 1;
                if((i_cell_ptr_fifo_dout[11:8] & bitmap) == 4'b0) begin
                    // drop 
                    wr_state<=#2 5;
                    drop <=#2 1;
                end 
                else begin
                    // write 
				    FQ_rd<=#2  1;
				    FQ_dout<=#2  ptr_dout_s;
                    // get free pd ptr
                    FPDQ_rd<=#2 1;
                    FPDQ_dout<=#2 pd_ptr_dout_s;
				    i_cell_first<=#2  1;
                    first_flg<=#2 1;
				    qc_portmap<=#2 i_cell_ptr_fifo_dout[11:8];
                    wr_state<=#2 1;
                end
			end
		end
		1:begin			
			cell_number<=#2 cell_number-1;
			sram_cnt_a<=#2 1;
			qc_wr_ptr_din<=#2  {i_cell_last,i_cell_first,4'b0,FQ_dout};
            // pd ptr (now cell_number has not been reduced by 1 yet)
            pd_qc_wr_ptr_din<=#2 {101'b0, pkt_len, cell_number[5:0], FPDQ_dout};

            if(qc_portmap[0])begin 
                qc_wr_ptr_wr_en[0]<=#2  1;
                if(first_flg) begin
                    in_port<=#2 0;
                    in <=#2 1;
                    pd_qc_wr_ptr_wr_en[0]<=#2 1;
                    first_flg<=#2 0;
                end
            end
            if(qc_portmap[1])begin
                qc_wr_ptr_wr_en[1]<=#2  1;
                if(first_flg) begin
                    in_port<=#2 1;
                    in <=#2 1;
                    pd_qc_wr_ptr_wr_en[1]<=#2 1;
                    first_flg<=#2 0;
                end
            end
            if(qc_portmap[2]) begin
                qc_wr_ptr_wr_en[2]<=#2  1;
                if(first_flg) begin 
                    in_port<=#2 2;
                    in <=#2 1;
                    pd_qc_wr_ptr_wr_en[2]<=#2 1;
                    first_flg <=#2 0;
                end
            end
            if(qc_portmap[3]) begin
                qc_wr_ptr_wr_en[3]<=#2  1;
                if(first_flg) begin 
                    in_port<=#2 3;
                    in <=#2 1;
                    pd_qc_wr_ptr_wr_en[3]<=#2 1;
                    first_flg<=#2 0;
                end
            end
//			MC_ram_wra<=#2  1;
			wr_state<=#2  2;
			
			// update statistic
			pkt_len_in<=#2 pkt_len;
		  end
		2:begin
		    in<=#2 0;
			sram_cnt_a<=#2  2;
			wr_state<=#2  3;
		  end
		3:begin
			sram_cnt_a<=#2  3;
			wr_state<=#2  4;
		  end
		4:begin
			i_cell_first<=#2  0;
			if(cell_number) begin
				if(!FQ_empty)begin
					FQ_rd		<=#2  1;
					FQ_dout		<=#2  ptr_dout_s;
					sram_cnt_a	<=#2  0;	
					wr_state	<=#2  1;
					if(cell_number==1) i_cell_last<=#2 1;
					else i_cell_last<=#2 0;
					end
				end
			else begin
				i_cell_data_fifo_rd<=#2 0;
				wr_state	<=#2 0;
				end
			end
        5:begin
            sram_cnt_a <=#2 sram_cnt_a + 1;
            if(sram_cnt_a >= 3) begin 
                if(cell_number == 1) begin
                    wr_state <=#2 0;
                    i_cell_data_fifo_rd<=#2 0;
                end
                cell_number <=#2 cell_number - 1;
            end
        end 

		default:wr_state<=#2  0;
		endcase
		end


assign  sram_wr=(i_cell_data_fifo_rd & !drop);
assign	sram_addr={FQ_dout[9:0],sram_cnt_a[1:0]};
assign	sram_din=i_cell_data_fifo_dout[127:0];
    
endmodule
