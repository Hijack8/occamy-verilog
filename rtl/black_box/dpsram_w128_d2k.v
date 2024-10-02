// dpsram_w128_d2k_stub.v

(* black_box *)

module dpsram_w128_d2k (
    input               clka,
    input               wea,
    input   [10:0]      addra,
    input   [127:0]     dina,
    output  [127:0]     douta,
    input               clkb,
    input               web,
    input   [10:0]      addrb,
    input   [127:0]     dinb,
    output  [127:0]     doutb,
    input               ena,
    input               enb
);
endmodule
