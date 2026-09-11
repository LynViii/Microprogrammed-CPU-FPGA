`timescale 1ns / 1ps

module CU(
    input clk,
    input reset,
    input [31:0] cs,
    input [7:0] ir,
    input flag,
    output reg [7:0] cu
);

always @(posedge clk or negedge reset) begin
    if (!reset) begin
        cu <= 0;
    end else begin
        if (cs[0]) cu <= 0;
        if (cs[2]) cu <= cu + 1'b1;
        if (cs[1]) begin
            case (ir)
                8'h01: cu <= 8'h50; // STORE X
                8'h02: cu <= 8'h54; // LOAD X
                8'h03: cu <= 8'h27; // ADD X
                8'h04: cu <= 8'h2E; // SUB X
                8'h05: begin        // JMPGEZ X
                    if (!flag)
                        cu <= 8'h5B;
                    else
                        cu <= 8'h5C;
                end
                8'h06: cu <= 8'h5F; // JMP X
                8'h07: cu <= 8'h62; // HALT
                8'h08: cu <= 8'h35; // MUL X
                8'h0A: cu <= 8'h06; // AND X
                8'h0B: cu <= 8'h0D; // OR X
                8'h0C: cu <= 8'h14; // NOT
                8'h0D: cu <= 8'h41; // SHR
                8'h0E: cu <= 8'h3C; // SHL
                8'h0F: cu <= 8'h4B; // SAR
                8'h10: cu <= 8'h46; // SAL
                8'h11: cu <= 8'h19; // XOR X
                8'h12: cu <= 8'h20; // NXOR X
            endcase
        end
    end
end

endmodule
