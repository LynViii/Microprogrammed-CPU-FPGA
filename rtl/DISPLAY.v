`timescale 1ns / 1ps

module DISPLAY(
    input clk,
    input [15:0] acc,
    input [15:0] mr,
    output reg [7:0] seg_en,
    output reg [7:0] seg_ca
);

reg [18:0] regN = 0;
reg [3:0] hex_in = 0;

always @(posedge clk)
    regN <= regN + 1'b1;

always @(posedge clk) begin
    case (regN[18:16])
        3'b000: begin seg_en <= 8'b11111110; hex_in <= acc[3:0]; end
        3'b001: begin seg_en <= 8'b11111101; hex_in <= acc[7:4]; end
        3'b010: begin seg_en <= 8'b11111011; hex_in <= acc[11:8]; end
        3'b011: begin seg_en <= 8'b11110111; hex_in <= acc[15:12]; end
        3'b100: begin seg_en <= 8'b11101111; hex_in <= mr[3:0]; end
        3'b101: begin seg_en <= 8'b11011111; hex_in <= mr[7:4]; end
        3'b110: begin seg_en <= 8'b10111111; hex_in <= mr[11:8]; end
        default: begin seg_en <= 8'b01111111; hex_in <= mr[15:12]; end
    endcase
end

always @(posedge clk) begin
    case (hex_in)
        4'h0: seg_ca <= 8'b11000000;
        4'h1: seg_ca <= 8'b11111001;
        4'h2: seg_ca <= 8'b10100100;
        4'h3: seg_ca <= 8'b10110000;
        4'h4: seg_ca <= 8'b10011001;
        4'h5: seg_ca <= 8'b10010010;
        4'h6: seg_ca <= 8'b10000010;
        4'h7: seg_ca <= 8'b11111000;
        4'h8: seg_ca <= 8'b10000000;
        4'h9: seg_ca <= 8'b10010000;
        4'hA: seg_ca <= 8'b10001000;
        4'hB: seg_ca <= 8'b10000011;
        4'hC: seg_ca <= 8'b11000110;
        4'hD: seg_ca <= 8'b10100001;
        4'hE: seg_ca <= 8'b10000110;
        4'hF: seg_ca <= 8'b10001110;
        default: seg_ca <= 8'b11111111;
    endcase
end

endmodule
