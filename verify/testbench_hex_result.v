`timescale 1ns / 1ps
`include "hex_result_config.vh"

module testbench_hex_result;
    reg clk_in;
    reg reset;
    wire [31:0] inst;
    wire [31:0] pc;

    sccomp_dataflow #(
        .PC_RESET(32'h00400000),
        .EXC_ENTRY(32'h00400004)
    ) uut (
        .clk_in(clk_in),
        .reset(reset),
        .inst(inst),
        .pc(pc)
    );

    integer file_output;
    integer cycle_count;
    integer print_count;
    integer cycle_limit;
    reg [31:0] exec_pc;
    reg [31:0] exec_inst;

    function [31:0] mars_display_pc;
        input [31:0] value;
        begin
            if (value[31:20] == 12'h004) begin
                mars_display_pc = {20'h00000, value[11:0]};
            end else begin
                mars_display_pc = value;
            end
        end
    endfunction

    initial begin
        file_output = $fopen("hex_result_output.txt");
        clk_in = 1'b0;
        reset = 1'b1;
        cycle_count = 0;
        print_count = 0;
        exec_pc = 32'h00000000;
        exec_inst = 32'h00000000;
        cycle_limit = `HEX_RESULT_PRINT_LIMIT;
        #40;
        reset = 1'b0;
    end

    always #50 clk_in = ~clk_in;

    always @(posedge clk_in) begin
        if (!reset) begin
            exec_pc = pc;
            exec_inst = inst;
            #1;
            if (exec_pc != pc) begin
            $fdisplay(file_output, "pc: %h", mars_display_pc(exec_pc));
            $fdisplay(file_output, "instr: %h", exec_inst);
            $fdisplay(file_output, "regfile0: %h", uut.sccpu.cpu_ref.array_reg[0]);
            $fdisplay(file_output, "regfile1: %h", uut.sccpu.cpu_ref.array_reg[1]);
            $fdisplay(file_output, "regfile2: %h", uut.sccpu.cpu_ref.array_reg[2]);
            $fdisplay(file_output, "regfile3: %h", uut.sccpu.cpu_ref.array_reg[3]);
            $fdisplay(file_output, "regfile4: %h", uut.sccpu.cpu_ref.array_reg[4]);
            $fdisplay(file_output, "regfile5: %h", uut.sccpu.cpu_ref.array_reg[5]);
            $fdisplay(file_output, "regfile6: %h", uut.sccpu.cpu_ref.array_reg[6]);
            $fdisplay(file_output, "regfile7: %h", uut.sccpu.cpu_ref.array_reg[7]);
            $fdisplay(file_output, "regfile8: %h", uut.sccpu.cpu_ref.array_reg[8]);
            $fdisplay(file_output, "regfile9: %h", uut.sccpu.cpu_ref.array_reg[9]);
            $fdisplay(file_output, "regfile10: %h", uut.sccpu.cpu_ref.array_reg[10]);
            $fdisplay(file_output, "regfile11: %h", uut.sccpu.cpu_ref.array_reg[11]);
            $fdisplay(file_output, "regfile12: %h", uut.sccpu.cpu_ref.array_reg[12]);
            $fdisplay(file_output, "regfile13: %h", uut.sccpu.cpu_ref.array_reg[13]);
            $fdisplay(file_output, "regfile14: %h", uut.sccpu.cpu_ref.array_reg[14]);
            $fdisplay(file_output, "regfile15: %h", uut.sccpu.cpu_ref.array_reg[15]);
            $fdisplay(file_output, "regfile16: %h", uut.sccpu.cpu_ref.array_reg[16]);
            $fdisplay(file_output, "regfile17: %h", uut.sccpu.cpu_ref.array_reg[17]);
            $fdisplay(file_output, "regfile18: %h", uut.sccpu.cpu_ref.array_reg[18]);
            $fdisplay(file_output, "regfile19: %h", uut.sccpu.cpu_ref.array_reg[19]);
            $fdisplay(file_output, "regfile20: %h", uut.sccpu.cpu_ref.array_reg[20]);
            $fdisplay(file_output, "regfile21: %h", uut.sccpu.cpu_ref.array_reg[21]);
            $fdisplay(file_output, "regfile22: %h", uut.sccpu.cpu_ref.array_reg[22]);
            $fdisplay(file_output, "regfile23: %h", uut.sccpu.cpu_ref.array_reg[23]);
            $fdisplay(file_output, "regfile24: %h", uut.sccpu.cpu_ref.array_reg[24]);
            $fdisplay(file_output, "regfile25: %h", uut.sccpu.cpu_ref.array_reg[25]);
            $fdisplay(file_output, "regfile26: %h", uut.sccpu.cpu_ref.array_reg[26]);
            $fdisplay(file_output, "regfile27: %h", uut.sccpu.cpu_ref.array_reg[27]);
            $fdisplay(file_output, "regfile28: %h", uut.sccpu.cpu_ref.array_reg[28]);
            $fdisplay(file_output, "regfile29: %h", uut.sccpu.cpu_ref.array_reg[29]);
            $fdisplay(file_output, "regfile30: %h", uut.sccpu.cpu_ref.array_reg[30]);
            $fdisplay(file_output, "regfile31: %h", uut.sccpu.cpu_ref.array_reg[31]);
            print_count = print_count + 1;
            if (print_count == cycle_limit) begin
                $fclose(file_output);
                $finish;
            end
        end
            cycle_count = cycle_count + 1;
            if (cycle_count == 20000) begin
                $display("HEX RESULT CHECK TIMEOUT");
                $fclose(file_output);
                $finish;
            end
        end
    end
endmodule
