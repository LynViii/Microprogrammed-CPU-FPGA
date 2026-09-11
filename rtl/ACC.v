`timescale 1ns / 1ps

module ACC(
    input clk,
    input reset,
    input [31:0] cs,
    input [15:0] alu_acc,
    output reg [15:0] acc,
    output reg flag
);

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        acc <= 0;
        flag <= 0;
    end else begin
        if (cs[10])
            acc <= 0;
        if (cs[18]) begin
            acc <= alu_acc;
            flag <= alu_acc[15];
        end
    end
end

endmodule
