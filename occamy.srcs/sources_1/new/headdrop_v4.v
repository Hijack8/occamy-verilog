`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/10 16:29:22
// Design Name: 
// Module Name: headdrop_v4
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


module headdrop_v4(
    input clk,
    input rstn,

    output reg FQ_wr,
    output [15:0] FQ_din_head_o,
    output [15:0] FQ_din_tail_o,

    input [3:0] pd_ptr_rdy,
    output reg [3:0] pd_ptr_ack,
    input [511:0] pd_ptr_dout,

    input cell_rd_pd_buzy,
    input cell_rd_cell_buzy,

    output reg headdrop_out,
    output [3:0] headdrop_out_port_o,
    output [10:0] headdrop_pkt_len_out_o,

    input [3:0] bitmap 
);

wire [3:0] headdrop_rdy;
assign headdrop_rdy = (~bitmap & pd_ptr_rdy);
wire rdy;
assign rdy = (headdrop_rdy[0] | headdrop_rdy[1] | headdrop_rdy[2] | headdrop_rdy[3]);

reg [15:0] FQ_din_head, FQ_din_head_delay, FQ_din_head_delay2;
reg [15:0] FQ_din_tail, FQ_din_tail_delay, FQ_din_tail_delay2;
reg [3:0] headdrop_out_port, headdrop_out_port_delay;
reg [10:0] headdrop_pkt_len_out, headdrop_pkt_len_out_delay;

assign headdrop_out_port_o = headdrop_out_port_delay;
assign headdrop_pkt_len_out_o = headdrop_pkt_len_out_delay;

assign FQ_din_head_o = free_fail ? FQ_din_head_delay2 : FQ_din_head_delay;
assign FQ_din_tail_o = free_fail ? FQ_din_tail_delay2 : FQ_din_tail_delay;

wire [127:0] pd_head[3:0];
assign {pd_head[3], pd_head[2], pd_head[1], pd_head[0]} = pd_ptr_dout;

reg [1:0] RR;

always@(posedge clk or negedge rstn) begin 
    if(!rstn) begin 
        RR<=#2 0; 
        FQ_din_head<=#2 0; 
        FQ_din_tail<=#2 0;
        headdrop_out_port<=#2 0; 
        headdrop_pkt_len_out<=#2 0;
        pd_ptr_ack<=#2 0;
    end 
    else begin 
        if(rdy && !(FQ_wr && cell_rd_cell_buzy && (pd_ptr_ack != 0))) begin 
            case(RR)
            0: casex(headdrop_rdy) 
            4'bxxx1: begin RR<=#2 1; FQ_din_head<=#2 pd_head[0][80:65]; FQ_din_tail<=#2 pd_head[0][64:49]; pd_ptr_ack<=#2 4'b0001; headdrop_out_port<=#2 0; headdrop_pkt_len_out<=#2 pd_head[0][48:38]; end
            4'bxx10: begin RR<=#2 2; FQ_din_head<=#2 pd_head[1][80:65]; FQ_din_tail<=#2 pd_head[1][64:49]; pd_ptr_ack<=#2 4'b0010; headdrop_out_port<=#2 1; headdrop_pkt_len_out<=#2 pd_head[1][48:38]; end
            4'bx100: begin RR<=#2 3; FQ_din_head<=#2 pd_head[2][80:65]; FQ_din_tail<=#2 pd_head[2][64:49]; pd_ptr_ack<=#2 4'b0100; headdrop_out_port<=#2 2; headdrop_pkt_len_out<=#2 pd_head[2][48:38]; end
            4'b1000: begin RR<=#2 0; FQ_din_head<=#2 pd_head[3][80:65]; FQ_din_tail<=#2 pd_head[3][64:49]; pd_ptr_ack<=#2 4'b1000; headdrop_out_port<=#2 3; headdrop_pkt_len_out<=#2 pd_head[3][48:38]; end
            endcase
            1: casex({headdrop_rdy[0], headdrop_rdy[3:1]}) 
            4'bxxx1: begin RR<=#2 2; FQ_din_head<=#2 pd_head[1][80:65]; FQ_din_tail<=#2 pd_head[1][64:49]; pd_ptr_ack<=#2 4'b0010; headdrop_out_port<=#2 1; headdrop_pkt_len_out<=#2 pd_head[1][48:38]; end
            4'bxx10: begin RR<=#2 3; FQ_din_head<=#2 pd_head[2][80:65]; FQ_din_tail<=#2 pd_head[2][64:49]; pd_ptr_ack<=#2 4'b0100; headdrop_out_port<=#2 2; headdrop_pkt_len_out<=#2 pd_head[2][48:38]; end
            4'bx100: begin RR<=#2 0; FQ_din_head<=#2 pd_head[3][80:65]; FQ_din_tail<=#2 pd_head[3][64:49]; pd_ptr_ack<=#2 4'b1000; headdrop_out_port<=#2 3; headdrop_pkt_len_out<=#2 pd_head[3][48:38]; end
            4'b1000: begin RR<=#2 1; FQ_din_head<=#2 pd_head[0][80:65]; FQ_din_tail<=#2 pd_head[0][64:49]; pd_ptr_ack<=#2 4'b0001; headdrop_out_port<=#2 0; headdrop_pkt_len_out<=#2 pd_head[0][48:38]; end
            endcase
            2: casex({headdrop_rdy[1:0], headdrop_rdy[3:2]}) 
            4'bxxx1: begin RR<=#2 3; FQ_din_head<=#2 pd_head[2][80:65]; FQ_din_tail<=#2 pd_head[2][64:49]; pd_ptr_ack<=#2 4'b0100; headdrop_out_port<=#2 2; headdrop_pkt_len_out<=#2 pd_head[2][48:38]; end
            4'bxx10: begin RR<=#2 0; FQ_din_head<=#2 pd_head[3][80:65]; FQ_din_tail<=#2 pd_head[3][64:49]; pd_ptr_ack<=#2 4'b1000; headdrop_out_port<=#2 3; headdrop_pkt_len_out<=#2 pd_head[3][48:38]; end
            4'bx100: begin RR<=#2 1; FQ_din_head<=#2 pd_head[0][80:65]; FQ_din_tail<=#2 pd_head[0][64:49]; pd_ptr_ack<=#2 4'b0001; headdrop_out_port<=#2 0; headdrop_pkt_len_out<=#2 pd_head[0][48:38]; end
            4'b1000: begin RR<=#2 2; FQ_din_head<=#2 pd_head[1][80:65]; FQ_din_tail<=#2 pd_head[1][64:49]; pd_ptr_ack<=#2 4'b0010; headdrop_out_port<=#2 1; headdrop_pkt_len_out<=#2 pd_head[1][48:38]; end
            endcase
            3: casex({headdrop_rdy[2:0], headdrop_rdy[3]}) 
            4'bxxx1: begin RR<=#2 0; FQ_din_head<=#2 pd_head[3][80:65]; FQ_din_tail<=#2 pd_head[3][64:49]; pd_ptr_ack<=#2 4'b1000; headdrop_out_port<=#2 3; headdrop_pkt_len_out<=#2 pd_head[3][48:38]; end
            4'bxx10: begin RR<=#2 1; FQ_din_head<=#2 pd_head[0][80:65]; FQ_din_tail<=#2 pd_head[0][64:49]; pd_ptr_ack<=#2 4'b0001; headdrop_out_port<=#2 0; headdrop_pkt_len_out<=#2 pd_head[0][48:38]; end
            4'bx100: begin RR<=#2 2; FQ_din_head<=#2 pd_head[1][80:65]; FQ_din_tail<=#2 pd_head[1][64:49]; pd_ptr_ack<=#2 4'b0010; headdrop_out_port<=#2 1; headdrop_pkt_len_out<=#2 pd_head[1][48:38]; end
            4'b1000: begin RR<=#2 3; FQ_din_head<=#2 pd_head[2][80:65]; FQ_din_tail<=#2 pd_head[2][64:49]; pd_ptr_ack<=#2 4'b0100; headdrop_out_port<=#2 2; headdrop_pkt_len_out<=#2 pd_head[2][48:38]; end
            endcase
            endcase 
        end
        else pd_ptr_ack<=#2 0;
    end
end


reg [3:0] free_state;
reg free_fail;
reg delay;
always@(posedge clk or negedge rstn) begin 
    if(!rstn) begin 
        free_state<=#2 0; 
        free_fail<=#2 0;
        delay <=#2 0; 
        FQ_wr<=#2 0;
        headdrop_out<=#2 0;
    end
    else begin 
        case(free_state)
        0: begin 
            free_fail<=#2 0;
            if(pd_ptr_ack != 0 && !cell_rd_pd_buzy) begin 
                FQ_wr<=#2 1; 
                headdrop_out<=#2 1;
                free_state <=#2 1;
            end
            else begin 
                FQ_wr<=#2 0; 
                headdrop_out<=#2 0;
            end
        end
        1: begin 
            if(cell_rd_cell_buzy) begin 
                free_fail<=#2 1;
                if(pd_ptr_ack != 0 && !cell_rd_pd_buzy) begin 
                    headdrop_out<=#2 1;
                    free_state<=#2 2; 
                end
                else begin 
                    free_state<=#2 0;
                end
            end
            else begin 
                if(pd_ptr_ack != 0 && !cell_rd_pd_buzy) begin 
                end
                else begin 
                    FQ_wr<=#2 0;
                    headdrop_out<=#2 0;
                end
                free_state<=#2 0;
            end
        end
        2: begin 
            headdrop_out<=#2 0;
            free_fail<=#2 1; 
            FQ_wr<=#2 1;
            free_state<=#2 3;
        end
        3: begin 
            free_fail<=#2 0;
            if(pd_ptr_ack != 0 && !cell_rd_pd_buzy) begin 
                headdrop_out<=#2 1;
                FQ_wr<=#2 1; 
            end
            else begin 
                FQ_wr<=#2 0;
            end
            free_state<=#2 0;
        end
        endcase
    end
end

always@(posedge clk or negedge rstn) begin 
    if(!rstn) begin 
        FQ_din_head_delay<=#2 0;
        FQ_din_tail_delay<=#2 0;
    end
    else begin 
        FQ_din_head_delay<=#2 FQ_din_head;
        FQ_din_tail_delay<=#2 FQ_din_tail;

        FQ_din_head_delay2<=#2 FQ_din_head_delay;
        FQ_din_tail_delay2<=#2 FQ_din_tail_delay;
    end
end



endmodule
