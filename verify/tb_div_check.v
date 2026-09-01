`timescale 1ns / 1ps

module tb_div_check;
    reg clk;
    reg reset;
    reg [31:0] inst;
    wire [31:0] pc;
    wire mem_we;
    wire [1:0] mem_store_size;
    wire [1:0] mem_load_size;
    wire mem_load_unsigned;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;

    sccpu cpu (
        .clk_in(clk),
        .reset(reset),
        .clk_en(1'b1),
        .pc(pc),
        .inst(inst),
        .mem_rdata(32'h00000000),
        .mem_we(mem_we),
        .mem_store_size(mem_store_size),
        .mem_load_size(mem_load_size),
        .mem_load_unsigned(mem_load_unsigned),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata)
    );

    always #5 clk = ~clk;

    always @(*) begin
        case ((pc - 32'h00400000) >> 2)
            32'd0:  inst = 32'h24010064; // addiu $1,$0,100
            32'd1:  inst = 32'h24020007; // addiu $2,$0,7
            32'd2:  inst = 32'h0022001a; // div $1,$2
            32'd3:  inst = 32'h00001812; // mflo $3
            32'd4:  inst = 32'h00002010; // mfhi $4
            32'd5:  inst = 32'h2405ff9c; // addiu $5,$0,-100
            32'd6:  inst = 32'h00a2001a; // div $5,$2
            32'd7:  inst = 32'h00003012; // mflo $6
            32'd8:  inst = 32'h00003810; // mfhi $7
            32'd9:  inst = 32'h2408ffff; // addiu $8,$0,-1
            32'd10: inst = 32'h24090002; // addiu $9,$0,2
            32'd11: inst = 32'h0109001b; // divu $8,$9
            32'd12: inst = 32'h00005012; // mflo $10
            32'd13: inst = 32'h00005810; // mfhi $11
            default: inst = 32'h00000000; // nop
        endcase
    end

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        #23;
        reset = 1'b0;
        #1500;

        if (cpu.cpu_ref.array_reg[3] !== 32'd14) begin
            $display("DIV CHECK FAILED: $3=%h", cpu.cpu_ref.array_reg[3]);
            $finish;
        end
        if (cpu.cpu_ref.array_reg[4] !== 32'd2) begin
            $display("DIV CHECK FAILED: $4=%h", cpu.cpu_ref.array_reg[4]);
            $finish;
        end
        if (cpu.cpu_ref.array_reg[6] !== 32'hfffffff2) begin
            $display("DIV CHECK FAILED: $6=%h", cpu.cpu_ref.array_reg[6]);
            $finish;
        end
        if (cpu.cpu_ref.array_reg[7] !== 32'hfffffffe) begin
            $display("DIV CHECK FAILED: $7=%h", cpu.cpu_ref.array_reg[7]);
            $finish;
        end
        if (cpu.cpu_ref.array_reg[10] !== 32'h7fffffff) begin
            $display("DIV CHECK FAILED: $10=%h", cpu.cpu_ref.array_reg[10]);
            $finish;
        end
        if (cpu.cpu_ref.array_reg[11] !== 32'h00000001) begin
            $display("DIV CHECK FAILED: $11=%h", cpu.cpu_ref.array_reg[11]);
            $finish;
        end

        $display("DIV CHECK PASSED");
        $finish;
    end
endmodule
