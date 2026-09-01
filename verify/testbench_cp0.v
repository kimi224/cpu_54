`timescale 1ns / 1ps

module testbench_cp0;
    reg clk_in;
    reg reset;
    wire [31:0] inst;
    wire [31:0] pc;
    integer cycle_count;

    sccomp_dataflow #(
        .PC_RESET(32'h00400000),
        .EXC_ENTRY(32'h00400008)
    ) uut (
        .clk_in(clk_in),
        .reset(reset),
        .inst(inst),
        .pc(pc)
    );

    initial begin
        clk_in = 1'b0;
        reset = 1'b1;
        cycle_count = 0;
        #40;
        reset = 1'b0;
    end

    always #50 clk_in = ~clk_in;

    always @(posedge clk_in) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;

            if (pc == 32'h00400070) begin
                $display("CP0 CHECK FAIL: reached wrong label r10=%h r11=%h r12=%h cause=%h epc=%h pc=%h inst=%h",
                    uut.sccpu.cpu_ref.array_reg[10],
                    uut.sccpu.cpu_ref.array_reg[11],
                    uut.sccpu.cpu_ref.array_reg[12],
                    uut.sccpu.cp0_cause,
                    uut.sccpu.cp0_epc,
                    pc,
                    inst);
                $finish;
            end

            if ((pc == 32'h00400068) && (cycle_count > 80)) begin
                if (uut.sccpu.cpu_ref.array_reg[10] !== 32'hffffffff) begin
                    $display("CP0 CHECK FAIL: break handler did not set $10");
                    $finish;
                end
                if (uut.sccpu.cpu_ref.array_reg[11] !== 32'hffffffff) begin
                    $display("CP0 CHECK FAIL: syscall handler did not set $11");
                    $finish;
                end
                if (uut.sccpu.cpu_ref.array_reg[12] !== 32'hffffffff) begin
                    $display("CP0 CHECK FAIL: teq handler did not set $12");
                    $finish;
                end
                if (uut.sccpu.cp0_status !== 32'h0000000f) begin
                    $display("CP0 CHECK FAIL: status=%h", uut.sccpu.cp0_status);
                    $finish;
                end
                if (uut.sccpu.cp0_cause !== 32'h00000034) begin
                    $display("CP0 CHECK FAIL: cause=%h", uut.sccpu.cp0_cause);
                    $finish;
                end
                if (uut.sccpu.cp0_epc !== 32'h00400050) begin
                    $display("CP0 CHECK FAIL: epc=%h", uut.sccpu.cp0_epc);
                    $finish;
                end

                $display("CP0 CHECK PASS: break/syscall/teq/eret handlers executed");
                $finish;
            end

            if (cycle_count == 400) begin
                $display("CP0 CHECK FAIL: timeout pc=%h inst=%h", pc, inst);
                $finish;
            end
        end
    end
endmodule
