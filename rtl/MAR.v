`timescale 1ns / 1ps

module MAR(
    input clk,
    input reset,
    input [31:0] cs,
    input [7:0] pc,
    input [15:0] mbr,
    output reg [7:0] mar
);

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        mar <= 0;
    end else begin
        if (cs[4]) mar <= mbr[7:0];
        if (cs[14]) mar <= pc;
    end
end

endmodule
