// dpsram_w128_d2k_stub.v

(* black_box *)

module dpsram_w32_d512 (
    input               clka,
    input               wea,
    input   [8:0]      addra,
    input   [31:0]     dina,
    output  [31:0]     douta,
    input               clkb,
    input               web,
    input   [8:0]      addrb,
    input   [31:0]     dinb,
    output  [31:0]     doutb,
    input               ena,
    input               enb
);
endmodule
