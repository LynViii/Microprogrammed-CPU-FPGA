`timescale 1ns / 1ps

module TOP(
    input clk,
    input reset,
    output [7:0] seg_en,
    output [7:0] seg_ca
);

wire flag;
wire [7:0] ir2cu;
wire [7:0] ram_addr;
wire [7:0] pc2mar;
wire [7:0] rom_addr;
wire [15:0] mbr;
wire [15:0] ram2mbr;
wire [15:0] br2alu;
wire [15:0] alu2acc;
wire [15:0] alu2mr;
wire [15:0] acc;
wire [15:0] mr;
wire [31:0] cs;

ALU alu1(
    .clk(clk), .reset(reset), .cs(cs),
    .br(br2alu), .acc(acc),
    .alu_acc(alu2acc), .alu_mr(alu2mr)
);

BR br1(
    .clk(clk), .reset(reset), .cs(cs),
    .mbr(mbr), .br(br2alu)
);

ACC acc1(
    .clk(clk), .reset(reset), .cs(cs),
    .alu_acc(alu2acc), .acc(acc), .flag(flag)
);

MR mr1(
    .clk(clk), .reset(reset), .cs(cs),
    .alu_mr(alu2mr), .mr(mr)
);

MAR mar1(
    .clk(clk), .reset(reset), .cs(cs),
    .pc(pc2mar), .mbr(mbr), .mar(ram_addr)
);

MBR mbr1(
    .clk(clk), .reset(reset), .cs(cs),
    .acc(acc), .mr(mr), .ram(ram2mbr), .mbr(mbr)
);

PC pc1(
    .clk(clk), .reset(reset), .cs(cs),
    .mbr(mbr), .pc(pc2mar)
);

IR ir1(
    .clk(clk), .reset(reset), .cs(cs),
    .mbr(mbr), .ir(ir2cu)
);

CU cu1(
    .clk(clk), .reset(reset), .flag(flag),
    .cs(cs), .ir(ir2cu), .cu(rom_addr)
);

blk_ram ram1(
    .clka(clk),
    .wea(cs[7]),
    .addra(ram_addr),
    .dina(mbr),
    .douta(ram2mbr)
);

blk_rom rom1(
    .clka(clk),
    .addra(rom_addr),
    .douta(cs)
);

DISPLAY display1(
    .clk(clk), .acc(acc), .mr(mr),
    .seg_en(seg_en), .seg_ca(seg_ca)
);

endmodule
