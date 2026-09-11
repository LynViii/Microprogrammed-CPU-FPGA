`timescale 1ns / 1ps

module cpu_sim;
    reg clk = 1'b0;
    reg reset = 1'b0;
    wire [7:0] seg_en;
    wire [7:0] seg_ca;

    TOP dut (
        .clk(clk),
        .reset(reset),
        .seg_en(seg_en),
        .seg_ca(seg_ca)
    );

    // Nexys A7-100T onboard clock: 100 MHz
    always #5 clk = ~clk;

    initial begin
        #30 reset = 1'b1;

        // Check that the bundled program reaches HALT (microaddress 0x62).
        repeat (5000) @(posedge clk);
        if (dut.rom_addr !== 8'h62) begin
            $fatal(1, "CPU did not reach HALT. CU=0x%02h PC=0x%02h", dut.rom_addr, dut.pc2mar);
        end

        $display("HALT reached. ACC=0x%04h MR=0x%04h", dut.acc, dut.mr);
        $finish;
    end
endmodule
