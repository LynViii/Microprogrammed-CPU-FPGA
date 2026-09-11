`timescale 1ns / 1ps

module MBR(
    input clk,
    input reset,
    input [31:0] cs,
    input [15:0] ram,
    input [15:0] acc,
    input [15:0] mr,
    output reg [15:0] mbr
);

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        mbr <= 0;
    end else begin
        if (cs[8]) mbr <= ram;
        if (cs[16]) mbr <= acc;
        if (cs[20]) mbr <= mr;
    end
end

endmodule
