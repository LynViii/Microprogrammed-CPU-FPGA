`timescale 1ns / 1ps

module MR(
    input clk,
    input reset,
    input [31:0] cs,
    input [15:0] alu_mr,
    output reg [15:0] mr
);

always @(posedge clk or negedge reset) begin
    if (!reset)
        mr <= 0;
    else if (cs[19])
        mr <= alu_mr;
end

endmodule
