`timescale 1ns / 1ps

module IR(
    input clk,
    input reset,
    input [31:0] cs,
    input [15:0] mbr,
    output reg [7:0] ir
);

always @(posedge clk or negedge reset) begin
    if (!reset)
        ir <= 0;
    else if (cs[5])
        ir <= mbr[15:8];
end

endmodule
