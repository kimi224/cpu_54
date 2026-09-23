`timescale 1ns / 1ps

module postsim_tb;
    parameter RESULT_FILE = "tmp/postsim_xsim/postsim_result.txt";

    reg clk_in;
    reg reset;
    wire [31:0] pc;
    wire [31:0] inst;
    wire [31:0] mem0;
    wire [31:0] mem1;
    integer outfile;
    integer print_count;

    postsim_top uut (
        .clk_in(clk_in),
        .reset(reset),
        .pc(pc),
        .inst(inst),
        .mem0(mem0),
        .mem1(mem1)
    );

    initial begin
        outfile = $fopen(RESULT_FILE, "w");
        clk_in = 1'b0;
        reset = 1'b1;
        print_count = 0;
        #120;
        reset = 1'b0;
    end

    always #25 clk_in = ~clk_in;

    always @(posedge clk_in) begin
        if (!reset) begin
            #1;
            $fdisplay(outfile, "pc: %h", pc);
            $fdisplay(outfile, "instr: %h", inst);
            $fdisplay(outfile, "mem0: %h", mem0);
            $fdisplay(outfile, "mem1: %h", mem1);
            print_count = print_count + 1;
            if (print_count == 1054) begin
                $fclose(outfile);
                $finish;
            end
        end
    end
endmodule
