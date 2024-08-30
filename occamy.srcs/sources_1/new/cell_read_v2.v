`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/20 09:46:06
// Design Name: 
// Module Name: cell_read_v2
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


module cell_read_v2(
    input clk,
    input rstn,

    // for cell memory 
    output reg FQ_wr, 
    output reg [15:0] FQ_din_head,
    output reg [15:0] FQ_din_tail,
    output reg cell_mem_rd,
    input [31:0] cell_mem_dout,
    output reg [15:0] cell_mem_addr,

    // for PD memory 
    input [3:0] pd_ptr_rdy,
    output reg [3:0] pd_ptr_ack,
    input [511:0] pd_ptr_dout,

    // for data
    output [11:0] data_sram_addr_b,
    input [127:0] data_sram_dout_b,
    output reg data_valid,

    output reg out,
    output reg [3:0] out_port,
    output reg [10:0] pkt_len_out,

    output reg cell_rd_pd_buzy,
    output reg cell_rd_cell_buzy
    );


    wire [127:0] pd_head[3:0];
    assign {pd_head[3], pd_head[2], pd_head[1], pd_head[0]} = pd_ptr_dout;


    reg [3:0] state;

    reg [15:0] pkt_cell_head, pkt_cell_tail;
    reg [8:0] cell_addr;


    reg [1:0] RR;

    wire rdy;
    assign rdy = pd_ptr_rdy[0] | pd_ptr_rdy[1] | pd_ptr_rdy[2] | pd_ptr_rdy[3];


    reg [5:0] cell_num;
    reg [1:0] cnt;
    // for debug 
    // wire [15:0] cell_head_debug, cell_tail_debug;
    // wire [10:0] pkt_len_debug;
    // wire [5:0] cell_num_debug;
    // wire [15:0] next_debug, cur_debug;
    // assign {cell_head_debug, cell_tail_debug, pkt_len_debug, cell_num_debug, next_debug, cur_debug} = pd_head[1][80:0];

    // wire [15:0] cell_head_debug2, cell_tail_debug2;
    // wire [10:0] pkt_len_debug2;
    // wire [5:0] cell_num_debug2;
    // wire [15:0] next_debug2, cur_debug2;
    // assign {cell_head_debug2, cell_tail_debug2, pkt_len_debug2, cell_num_debug2, next_debug2, cur_debug2} = pd_head[2][80:0];


    assign data_sram_addr_b = {cell_addr[8:0], cnt[1:0]};


    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            state <=#2 0;
            pkt_cell_head<=#2 0;
            pkt_cell_tail<=#2 0;
            RR<=#2 0;
            cell_num<=#2 0;
            cnt <=#2 0;
            cell_addr<=#2 0;
            FQ_din_head<=#2 0;
            FQ_din_tail<=#2 0;
            pd_ptr_ack<=#2 0;
            cell_mem_addr<=#2 0;
            cell_mem_rd<=#2 0;
            data_valid <=#2 0;

            out<=#2 0;
            out_port<=#2 0;
            pkt_len_out<=#2 0;

            cell_rd_pd_buzy<=#2 0;
            cell_rd_cell_buzy<=#2 0;
        end

        else begin
            case(state)
            0: begin
                FQ_wr<=#2 0;
                cell_rd_cell_buzy<=#2 0;
                data_valid<=#2 0;
                out<=#2 0;
                // TODO
                if(rdy) begin 
                case(RR) 
                    0: casex(pd_ptr_rdy)
                    4'bxxx1: begin pd_ptr_ack[0]<=#2 1; FQ_din_head<=#2 pd_head[0][80:65]; FQ_din_tail<=#2 pd_head[0][64:49]; cell_mem_addr<=#2 pd_head[0][80:65]; cell_num<=#2 pd_head[0][37:32]; pkt_len_out <=#2 pd_head[0][48:38]; out_port<=#2 0; end
                    4'bxx10: begin pd_ptr_ack[1]<=#2 1; FQ_din_head<=#2 pd_head[1][80:65]; FQ_din_tail<=#2 pd_head[1][64:49]; cell_mem_addr<=#2 pd_head[1][80:65]; cell_num<=#2 pd_head[1][37:32]; pkt_len_out <=#2 pd_head[1][48:38]; out_port<=#2 1; end
                    4'bx100: begin pd_ptr_ack[2]<=#2 1; FQ_din_head<=#2 pd_head[2][80:65]; FQ_din_tail<=#2 pd_head[2][64:49]; cell_mem_addr<=#2 pd_head[2][80:65]; cell_num<=#2 pd_head[2][37:32]; pkt_len_out <=#2 pd_head[2][48:38]; out_port<=#2 2; end
                    4'b1000: begin pd_ptr_ack[3]<=#2 1; FQ_din_head<=#2 pd_head[3][80:65]; FQ_din_tail<=#2 pd_head[3][64:49]; cell_mem_addr<=#2 pd_head[3][80:65]; cell_num<=#2 pd_head[3][37:32]; pkt_len_out <=#2 pd_head[3][48:38]; out_port<=#2 3; end
                    endcase
                    1: casex({pd_ptr_rdy[0], pd_ptr_rdy[3:1]}) 
                    4'bxxx1: begin pd_ptr_ack[1]<=#2 1; FQ_din_head<=#2 pd_head[1][80:65]; FQ_din_tail<=#2 pd_head[1][64:49]; cell_mem_addr<=#2 pd_head[1][80:65]; cell_num<=#2 pd_head[1][37:32]; pkt_len_out <=#2 pd_head[1][48:38]; out_port<=#2 1; end
                    4'bxx10: begin pd_ptr_ack[2]<=#2 1; FQ_din_head<=#2 pd_head[2][80:65]; FQ_din_tail<=#2 pd_head[2][64:49]; cell_mem_addr<=#2 pd_head[2][80:65]; cell_num<=#2 pd_head[2][37:32]; pkt_len_out <=#2 pd_head[2][48:38]; out_port<=#2 2; end
                    4'bx100: begin pd_ptr_ack[3]<=#2 1; FQ_din_head<=#2 pd_head[3][80:65]; FQ_din_tail<=#2 pd_head[3][64:49]; cell_mem_addr<=#2 pd_head[3][80:65]; cell_num<=#2 pd_head[3][37:32]; pkt_len_out <=#2 pd_head[3][48:38]; out_port<=#2 3; end
                    4'b1000: begin pd_ptr_ack[0]<=#2 1; FQ_din_head<=#2 pd_head[0][80:65]; FQ_din_tail<=#2 pd_head[0][64:49]; cell_mem_addr<=#2 pd_head[0][80:65]; cell_num<=#2 pd_head[0][37:32]; pkt_len_out <=#2 pd_head[0][48:38]; out_port<=#2 0; end
                    endcase
                    2: casex({pd_ptr_rdy[1:0], pd_ptr_rdy[3:2]})
                    4'bxxx1: begin pd_ptr_ack[2]<=#2 1; FQ_din_head<=#2 pd_head[2][80:65]; FQ_din_tail<=#2 pd_head[2][64:49]; cell_mem_addr<=#2 pd_head[2][80:65]; cell_num<=#2 pd_head[2][37:32]; pkt_len_out <=#2 pd_head[2][48:38]; out_port<=#2 2; end
                    4'bxx10: begin pd_ptr_ack[3]<=#2 1; FQ_din_head<=#2 pd_head[3][80:65]; FQ_din_tail<=#2 pd_head[3][64:49]; cell_mem_addr<=#2 pd_head[3][80:65]; cell_num<=#2 pd_head[3][37:32]; pkt_len_out <=#2 pd_head[3][48:38]; out_port<=#2 3; end
                    4'bx100: begin pd_ptr_ack[0]<=#2 1; FQ_din_head<=#2 pd_head[0][80:65]; FQ_din_tail<=#2 pd_head[0][64:49]; cell_mem_addr<=#2 pd_head[0][80:65]; cell_num<=#2 pd_head[0][37:32]; pkt_len_out <=#2 pd_head[0][48:38]; out_port<=#2 0; end
                    4'b1000: begin pd_ptr_ack[1]<=#2 1; FQ_din_head<=#2 pd_head[1][80:65]; FQ_din_tail<=#2 pd_head[1][64:49]; cell_mem_addr<=#2 pd_head[1][80:65]; cell_num<=#2 pd_head[1][37:32]; pkt_len_out <=#2 pd_head[1][48:38]; out_port<=#2 1; end
                    endcase
                    3: casex({pd_ptr_rdy[2:0], pd_ptr_rdy[3]})
                    4'bxxx1: begin pd_ptr_ack[3]<=#2 1; FQ_din_head<=#2 pd_head[3][80:65]; FQ_din_tail<=#2 pd_head[3][64:49]; cell_mem_addr<=#2 pd_head[3][80:65]; cell_num<=#2 pd_head[3][37:32]; pkt_len_out <=#2 pd_head[3][48:38]; out_port<=#2 3; end
                    4'bxx10: begin pd_ptr_ack[0]<=#2 1; FQ_din_head<=#2 pd_head[0][80:65]; FQ_din_tail<=#2 pd_head[0][64:49]; cell_mem_addr<=#2 pd_head[0][80:65]; cell_num<=#2 pd_head[0][37:32]; pkt_len_out <=#2 pd_head[0][48:38]; out_port<=#2 0; end
                    4'bx100: begin pd_ptr_ack[1]<=#2 1; FQ_din_head<=#2 pd_head[1][80:65]; FQ_din_tail<=#2 pd_head[1][64:49]; cell_mem_addr<=#2 pd_head[1][80:65]; cell_num<=#2 pd_head[1][37:32]; pkt_len_out <=#2 pd_head[1][48:38]; out_port<=#2 1; end
                    4'b1000: begin pd_ptr_ack[2]<=#2 1; FQ_din_head<=#2 pd_head[2][80:65]; FQ_din_tail<=#2 pd_head[2][64:49]; cell_mem_addr<=#2 pd_head[2][80:65]; cell_num<=#2 pd_head[2][37:32]; pkt_len_out <=#2 pd_head[2][48:38]; out_port<=#2 2; end
                    endcase
                endcase 
                    RR<=#2 RR+1;
                    cell_mem_rd<=#2 1;
                    cell_rd_pd_buzy<=#2 1;
                    state<=#2 1;
                end
                else cell_rd_pd_buzy<=#2 0;
            end 
            1: begin 
                cell_mem_rd<=#2 0;
                cell_rd_cell_buzy<=#2 1;
                pd_ptr_ack<=#2 0;

                state<=#2 2;
            end
            2: begin
                cell_rd_cell_buzy<=#2 0;
                cell_rd_pd_buzy<=#2 0;
                cell_num<=#2 cell_num - 1;
                #2 cell_addr<= cell_mem_dout[8:0];
                cnt<=#2 0;
                state<=#2 3;
            end
            3: begin
                cnt<=#2 1;
                data_valid<=#2 1;
                if(cell_num == 0) begin 
                    state<=#2 6;
                end 
                else begin 
                    cell_mem_addr<=#2 cell_mem_dout[24:16];
                    cell_mem_rd<=#2 1;
                    cell_rd_cell_buzy<=#2 1;
                    state<=#2 4;
                end
            end
            4: begin
                cnt<=#2 2;
                cell_mem_rd<=#2 0;
                cell_rd_cell_buzy<=#2 0;
                state<=#2 5;
            end
            5: begin
                cnt<=#2 3;
                #2 cell_addr<=#2 cell_mem_dout;
                state<=#2 2;
            end
            6: begin 
                cnt<=#2 2;
                state<=#2 7;
            end
            7: begin 
                cnt<=#2 3;
                // free 
                FQ_wr<=#2 1;
                cell_rd_pd_buzy<=#2 1;
                cell_rd_cell_buzy<=#2 1;
                out<=#2 1;
                
                state<=#2 0;
            end


            endcase
        end
    end



endmodule







