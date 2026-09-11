`timescale 1ns / 1ps

module ALU(
    input clk,
    input reset,
    input [31:0] cs,
    input signed [15:0] br,
    input signed [15:0] acc,
    output signed [15:0] alu_acc,
    output signed [15:0] alu_mr
);

reg signed [31:0] result;
reg signed [15:0] br_reg;
reg signed [15:0] acc_reg;

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        result <= 0;
        br_reg <= 0;
        acc_reg <= 0;
    end else begin
        if (cs[17]) acc_reg <= acc;
        if (cs[15]) br_reg <= br;
        if (cs[11]) result[15:0] <= acc_reg + br_reg;
        if (cs[21]) result[15:0] <= acc_reg - br_reg;
        if (cs[22]) result <= acc_reg * br_reg;
        if (cs[23]) result[15:0] <= acc_reg >>> 1;
        if (cs[24]) result[15:0] <= acc_reg <<< 1;
        if (cs[25]) result[15:0] <= acc_reg >> 1;
        if (cs[26]) result[15:0] <= acc_reg << 1;
        if (cs[27]) result[15:0] <= acc_reg & br_reg;
        if (cs[28]) result[15:0] <= acc_reg | br_reg;
        if (cs[29]) result[15:0] <= acc_reg ^ br_reg;
        if (cs[30]) result[15:0] <= acc_reg ~^ br_reg;
        if (cs[31]) result[15:0] <= ~acc_reg;
    end
end

assign alu_acc = result[15:0];
assign alu_mr = result[31:16];

endmodule
