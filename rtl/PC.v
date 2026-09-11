`timescale 1ns / 1ps

module PC(
    input clk,
    input reset,
    input [31:0] cs,
    input [15:0] mbr,
    output reg [7:0] pc
);

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        pc <= 0;
    end else begin
        if (cs[12]) pc <= 0;
        if (cs[13]) pc <= pc + 1'b1;
        if (cs[3]) pc <= mbr[7:0];
    end
end

endmodule
