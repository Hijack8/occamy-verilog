`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/29 18:36:07
// Design Name: 
// Module Name: headdrop_v3
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


module headdrop_v3 (
    input clk,
    input rstn,

    output reg FQ_wr,
    output reg [15:0] FQ_din_head,
    output reg [15:0] FQ_din_tail,

    input [3:0] pd_ptr_rdy,
    output reg [3:0] pd_ptr_ack,
    input [511:0] pd_ptr_dout,

    // ====================> begin arbiter
    input cell_rd_pd_buzy,
    input cell_rd_cell_buzy,

    // ====================> end arbiter
    output reg headdrop_out,
    output reg [3:0] headdrop_out_port,
    output reg [10:0] headdrop_pkt_len_out,

    input [3:0] bitmap
);

    reg  [3:0] state;
    reg  [1:0] RR;
    wire [3:0] headdrop_rdy;
    assign headdrop_rdy = (~bitmap & pd_ptr_rdy);
    wire rdy;
    assign rdy = (headdrop_rdy[0] | headdrop_rdy[1] | headdrop_rdy[2] | headdrop_rdy[3]);

    wire [127:0] pd_head[3:0];
    assign {pd_head[3], pd_head[2], pd_head[1], pd_head[0]} = pd_ptr_dout;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            FQ_wr                <= #2 0;
            FQ_din_head          <= #2 0;
            FQ_din_tail          <= #2 0;
            pd_ptr_ack           <= #2 0;
            headdrop_out         <= #2 0;
            headdrop_out_port    <= #2 0;
            headdrop_pkt_len_out <= #2 0;

            state                <= #2 0;
            RR                   <= #2 0;
        end else begin
            case (state)
                0: begin
                    if (rdy) begin
                        case (RR)
                            0:
// ====================> begin headdrop_scheduler
                            casex (headdrop_rdy)
                                4'bxxx1: begin
                                    FQ_din_head          <= #2 pd_head[0][80:65];
                                    FQ_din_tail          <= #2 pd_head[0][64:49];
                                    pd_ptr_ack[0]        <= #2 1;
                                    headdrop_out_port    <= #2 0;
                                    headdrop_pkt_len_out <= #2 pd_head[0][48:38];
                                end
                                4'bxx10: begin
                                    FQ_din_head          <= #2 pd_head[1][80:65];
                                    FQ_din_tail          <= #2 pd_head[1][64:49];
                                    pd_ptr_ack[1]        <= #2 1;
                                    headdrop_out_port    <= #2 1;
                                    headdrop_pkt_len_out <= #2 pd_head[1][48:38];
                                end
                                4'bx100: begin
                                    FQ_din_head          <= #2 pd_head[2][80:65];
                                    FQ_din_tail          <= #2 pd_head[2][64:49];
                                    pd_ptr_ack[2]        <= #2 1;
                                    headdrop_out_port    <= #2 2;
                                    headdrop_pkt_len_out <= #2 pd_head[2][48:38];
                                end
                                4'b1000: begin
                                    FQ_din_head          <= #2 pd_head[3][80:65];
                                    FQ_din_tail          <= #2 pd_head[3][64:49];
                                    pd_ptr_ack[3]        <= #2 1;
                                    headdrop_out_port    <= #2 3;
                                    headdrop_pkt_len_out <= #2 pd_head[3][48:38];
                                end
                            endcase
                            1:
                            casex ({
                                headdrop_rdy[0], headdrop_rdy[3:1]
                            })
                                4'bxxx1: begin
                                    FQ_din_head          <= #2 pd_head[1][80:65];
                                    FQ_din_tail          <= #2 pd_head[1][64:49];
                                    pd_ptr_ack[1]        <= #2 1;
                                    headdrop_out_port    <= #2 1;
                                    headdrop_pkt_len_out <= #2 pd_head[1][48:38];
                                end
                                4'bxx10: begin
                                    FQ_din_head          <= #2 pd_head[2][80:65];
                                    FQ_din_tail          <= #2 pd_head[2][64:49];
                                    pd_ptr_ack[2]        <= #2 1;
                                    headdrop_out_port    <= #2 2;
                                    headdrop_pkt_len_out <= #2 pd_head[2][48:38];
                                end
                                4'bx100: begin
                                    FQ_din_head          <= #2 pd_head[3][80:65];
                                    FQ_din_tail          <= #2 pd_head[3][64:49];
                                    pd_ptr_ack[3]        <= #2 1;
                                    headdrop_out_port    <= #2 3;
                                    headdrop_pkt_len_out <= #2 pd_head[3][48:38];
                                end
                                4'b1000: begin
                                    FQ_din_head          <= #2 pd_head[0][80:65];
                                    FQ_din_tail          <= #2 pd_head[0][64:49];
                                    pd_ptr_ack[0]        <= #2 1;
                                    headdrop_out_port    <= #2 0;
                                    headdrop_pkt_len_out <= #2 pd_head[0][48:38];
                                end
                            endcase
                            2:
                            casex ({
                                headdrop_rdy[1:0], headdrop_rdy[3:2]
                            })
                                4'bxxx1: begin
                                    FQ_din_head          <= #2 pd_head[2][80:65];
                                    FQ_din_tail          <= #2 pd_head[2][64:49];
                                    pd_ptr_ack[2]        <= #2 1;
                                    headdrop_out_port    <= #2 2;
                                    headdrop_pkt_len_out <= #2 pd_head[2][48:38];
                                end
                                4'bxx10: begin
                                    FQ_din_head          <= #2 pd_head[3][80:65];
                                    FQ_din_tail          <= #2 pd_head[3][64:49];
                                    pd_ptr_ack[3]        <= #2 1;
                                    headdrop_out_port    <= #2 3;
                                    headdrop_pkt_len_out <= #2 pd_head[3][48:38];
                                end
                                4'bx100: begin
                                    FQ_din_head          <= #2 pd_head[0][80:65];
                                    FQ_din_tail          <= #2 pd_head[0][64:49];
                                    pd_ptr_ack[0]        <= #2 1;
                                    headdrop_out_port    <= #2 0;
                                    headdrop_pkt_len_out <= #2 pd_head[0][48:38];
                                end
                                4'b1000: begin
                                    FQ_din_head          <= #2 pd_head[1][80:65];
                                    FQ_din_tail          <= #2 pd_head[1][64:49];
                                    pd_ptr_ack[1]        <= #2 1;
                                    headdrop_out_port    <= #2 1;
                                    headdrop_pkt_len_out <= #2 pd_head[1][48:38];
                                end
                            endcase
                            3:
                            casex ({
                                headdrop_rdy[2:0], headdrop_rdy[3]
                            })
                                4'bxxx1: begin
                                    FQ_din_head          <= #2 pd_head[3][80:65];
                                    FQ_din_tail          <= #2 pd_head[3][64:49];
                                    pd_ptr_ack[3]        <= #2 1;
                                    headdrop_out_port    <= #2 3;
                                    headdrop_pkt_len_out <= #2 pd_head[3][48:38];
                                end
                                4'bxx10: begin
                                    FQ_din_head          <= #2 pd_head[0][80:65];
                                    FQ_din_tail          <= #2 pd_head[0][64:49];
                                    pd_ptr_ack[0]        <= #2 1;
                                    headdrop_out_port    <= #2 0;
                                    headdrop_pkt_len_out <= #2 pd_head[0][48:38];
                                end
                                4'bx100: begin
                                    FQ_din_head          <= #2 pd_head[1][80:65];
                                    FQ_din_tail          <= #2 pd_head[1][64:49];
                                    pd_ptr_ack[1]        <= #2 1;
                                    headdrop_out_port    <= #2 1;
                                    headdrop_pkt_len_out <= #2 pd_head[1][48:38];
                                end
                                4'b1000: begin
                                    FQ_din_head          <= #2 pd_head[2][80:65];
                                    FQ_din_tail          <= #2 pd_head[2][64:49];
                                    pd_ptr_ack[2]        <= #2 1;
                                    headdrop_out_port    <= #2 2;
                                    headdrop_pkt_len_out <= #2 pd_head[2][48:38];
                                end
                            endcase
                        endcase
                        RR    <= #2 RR + 1;
// ====================> end headdrop_scheduler
                        state <= #2 1;
                    end
                end
                1: begin
                    pd_ptr_ack <= #2 0;
                    // ====================> begin arbiter
                    if (cell_rd_pd_buzy) begin
                        state <= #2 0;
                    end else begin
                        FQ_wr        <= #2 1;
                        headdrop_out <= #2 1;
                        state        <= #2 2;
                    end
                    // ====================> end arbiter
                end
                2: begin
                    headdrop_out <= #2 0;begin 
                    // ====================> begin arbiter
                    if (!cell_rd_cell_buzy) begin
                        FQ_wr <= #2 0;
                        if (rdy) begin

                            // ====================> end arbiter
                            // ====================> begin headdrop_scheduler
                            case (RR)
                                0:
                                casex (headdrop_rdy)
                                    4'bxxx1: begin
                                        FQ_din_head          <= #2 pd_head[0][80:65];
                                        FQ_din_tail          <= #2 pd_head[0][64:49];
                                        pd_ptr_ack[0]        <= #2 1;
                                        headdrop_out_port    <= #2 0;
                                        headdrop_pkt_len_out <= #2 pd_head[0][48:38];
                                    end
                                    4'bxx10: begin
                                        FQ_din_head          <= #2 pd_head[1][80:65];
                                        FQ_din_tail          <= #2 pd_head[1][64:49];
                                        pd_ptr_ack[1]        <= #2 1;
                                        headdrop_out_port    <= #2 1;
                                        headdrop_pkt_len_out <= #2 pd_head[1][48:38];
                                    end
                                    4'bx100: begin
                                        FQ_din_head          <= #2 pd_head[2][80:65];
                                        FQ_din_tail          <= #2 pd_head[2][64:49];
                                        pd_ptr_ack[2]        <= #2 1;
                                        headdrop_out_port    <= #2 2;
                                        headdrop_pkt_len_out <= #2 pd_head[2][48:38];
                                    end
                                    4'b1000: begin
                                        FQ_din_head          <= #2 pd_head[3][80:65];
                                        FQ_din_tail          <= #2 pd_head[3][64:49];
                                        pd_ptr_ack[3]        <= #2 1;
                                        headdrop_out_port    <= #2 3;
                                        headdrop_pkt_len_out <= #2 pd_head[3][48:38];
                                    end
                                endcase
                                1:
                                casex ({
                                    headdrop_rdy[0], headdrop_rdy[3:1]
                                })
                                    4'bxxx1: begin
                                        FQ_din_head          <= #2 pd_head[1][80:65];
                                        FQ_din_tail          <= #2 pd_head[1][64:49];
                                        pd_ptr_ack[1]        <= #2 1;
                                        headdrop_out_port    <= #2 1;
                                        headdrop_pkt_len_out <= #2 pd_head[1][48:38];
                                    end
                                    4'bxx10: begin
                                        FQ_din_head          <= #2 pd_head[2][80:65];
                                        FQ_din_tail          <= #2 pd_head[2][64:49];
                                        pd_ptr_ack[2]        <= #2 1;
                                        headdrop_out_port    <= #2 2;
                                        headdrop_pkt_len_out <= #2 pd_head[2][48:38];
                                    end
                                    4'bx100: begin
                                        FQ_din_head          <= #2 pd_head[3][80:65];
                                        FQ_din_tail          <= #2 pd_head[3][64:49];
                                        pd_ptr_ack[3]        <= #2 1;
                                        headdrop_out_port    <= #2 3;
                                        headdrop_pkt_len_out <= #2 pd_head[3][48:38];
                                    end
                                    4'b1000: begin
                                        FQ_din_head          <= #2 pd_head[0][80:65];
                                        FQ_din_tail          <= #2 pd_head[0][64:49];
                                        pd_ptr_ack[0]        <= #2 1;
                                        headdrop_out_port    <= #2 0;
                                        headdrop_pkt_len_out <= #2 pd_head[0][48:38];
                                    end
                                endcase
                                2:
                                casex ({
                                    headdrop_rdy[1:0], headdrop_rdy[3:2]
                                })
                                    4'bxxx1: begin
                                        FQ_din_head          <= #2 pd_head[2][80:65];
                                        FQ_din_tail          <= #2 pd_head[2][64:49];
                                        pd_ptr_ack[2]        <= #2 1;
                                        headdrop_out_port    <= #2 2;
                                        headdrop_pkt_len_out <= #2 pd_head[2][48:38];
                                    end
                                    4'bxx10: begin
                                        FQ_din_head          <= #2 pd_head[3][80:65];
                                        FQ_din_tail          <= #2 pd_head[3][64:49];
                                        pd_ptr_ack[3]        <= #2 1;
                                        headdrop_out_port    <= #2 3;
                                        headdrop_pkt_len_out <= #2 pd_head[3][48:38];
                                    end
                                    4'bx100: begin
                                        FQ_din_head          <= #2 pd_head[0][80:65];
                                        FQ_din_tail          <= #2 pd_head[0][64:49];
                                        pd_ptr_ack[0]        <= #2 1;
                                        headdrop_out_port    <= #2 0;
                                        headdrop_pkt_len_out <= #2 pd_head[0][48:38];
                                    end
                                    4'b1000: begin
                                        FQ_din_head          <= #2 pd_head[1][80:65];
                                        FQ_din_tail          <= #2 pd_head[1][64:49];
                                        pd_ptr_ack[1]        <= #2 1;
                                        headdrop_out_port    <= #2 1;
                                        headdrop_pkt_len_out <= #2 pd_head[1][48:38];
                                    end
                                endcase
                                3:
                                casex ({
                                    headdrop_rdy[2:0], headdrop_rdy[3]
                                })
                                    4'bxxx1: begin
                                        FQ_din_head          <= #2 pd_head[3][80:65];
                                        FQ_din_tail          <= #2 pd_head[3][64:49];
                                        pd_ptr_ack[3]        <= #2 1;
                                        headdrop_out_port    <= #2 3;
                                        headdrop_pkt_len_out <= #2 pd_head[3][48:38];
                                    end
                                    4'bxx10: begin
                                        FQ_din_head          <= #2 pd_head[0][80:65];
                                        FQ_din_tail          <= #2 pd_head[0][64:49];
                                        pd_ptr_ack[0]        <= #2 1;
                                        headdrop_out_port    <= #2 0;
                                        headdrop_pkt_len_out <= #2 pd_head[0][48:38];
                                    end
                                    4'bx100: begin
                                        FQ_din_head          <= #2 pd_head[1][80:65];
                                        FQ_din_tail          <= #2 pd_head[1][64:49];
                                        pd_ptr_ack[1]        <= #2 1;
                                        headdrop_out_port    <= #2 1;
                                        headdrop_pkt_len_out <= #2 pd_head[1][48:38];
                                    end
                                    4'b1000: begin
                                        FQ_din_head          <= #2 pd_head[2][80:65];
                                        FQ_din_tail          <= #2 pd_head[2][64:49];
                                        pd_ptr_ack[2]        <= #2 1;
                                        headdrop_out_port    <= #2 2;
                                        headdrop_pkt_len_out <= #2 pd_head[2][48:38];
                                    end
                                endcase
                            endcase
                            RR    <= #2 RR + 1;
                            // ====================> end headdrop_scheduler
                            state <= #2 1;
                    // ====================> end headdrop_scheduler
                    // ====================> begin arbiter 
                        end else begin
                            state <= #2 0;
                        end
                    end
                    // ====================> end arbiter
                end
            endcase
        end
    end

endmodule
