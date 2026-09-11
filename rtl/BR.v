`timescale 1ns / 1ps

module BR(
    input clk,
    input reset,
    input [31:0] cs,
    input [15:0] mbr,
    output reg [15:0] br
);

always @(posedge clk or negedge reset) begin
    if (!reset)
        br <= 0;
    else if (cs[9])
        br <= mbr;
end

endmodule
