`timescale 1ns / 1ps

module cpu54_board #(
    parameter IO_SWITCH_DATA = 32'h00008000,
    parameter CPU_STEP_DIVISOR = 26'd50000000
)(
    input wire clk_in,
    input wire reset,
    output wire [31:0] display_data
);
    reg [25:0] step_counter;
    reg cpu_clk_en;
    wire [31:0] inst;
    wire [31:0] pc;
    wire mem_we;
    wire [1:0] mem_store_size;
    wire [1:0] mem_load_size;
    wire mem_load_unsigned;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;
    wire [31:0] word0;
    wire [31:0] word1;

    always @(posedge clk_in) begin
        if (reset) begin
            step_counter <= 26'd0;
            cpu_clk_en <= 1'b0;
        end else if (step_counter == (CPU_STEP_DIVISOR - 1'b1)) begin
            step_counter <= 26'd0;
            cpu_clk_en <= 1'b1;
        end else begin
            step_counter <= step_counter + 1'b1;
            cpu_clk_en <= 1'b0;
        end
    end

    sccpu sccpu (
        .clk_in(clk_in),
        .reset(reset),
        .clk_en(cpu_clk_en),
        .pc(pc),
        .inst(inst),
        .mem_rdata(mem_rdata),
        .mem_we(mem_we),
        .mem_store_size(mem_store_size),
        .mem_load_size(mem_load_size),
        .mem_load_unsigned(mem_load_unsigned),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata)
    );

    scinstmem imem (
        .addr(pc),
        .inst(inst)
    );

    scdatamem #(
        .DEPTH(512),
        .IO_SWITCH_ADDR(32'h10010010)
    ) dmem (
        .clk(clk_in),
        .mem_we(cpu_clk_en && mem_we),
        .store_size(mem_store_size),
        .load_size(mem_load_size),
        .load_unsigned(mem_load_unsigned),
        .addr(mem_addr),
        .wdata(mem_wdata),
        .io_switch_data(IO_SWITCH_DATA),
        .rdata(mem_rdata),
        .word0(word0),
        .word1(word1)
    );

    assign display_data = pc;
endmodule
