`timescale 1ns / 1ps

module postsim_top #(
    parameter IO_SWITCH_DATA = 32'h00000000,
    parameter PC_RESET = 32'h00400000,
    parameter EXC_ENTRY = 32'h00400004
)(
    input wire clk_in,
    input wire reset,
    output wire [31:0] pc,
    output wire [31:0] inst,
    output wire [31:0] mem0,
    output wire [31:0] mem1
);
    wire mem_we;
    wire [1:0] mem_store_size;
    wire [1:0] mem_load_size;
    wire mem_load_unsigned;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;

    sccpu #(
        .PC_RESET(PC_RESET),
        .EXC_ENTRY(EXC_ENTRY)
    ) sccpu (
        .clk_in(clk_in),
        .reset(reset),
        .clk_en(1'b1),
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
        .DEPTH(512)
    ) dmem (
        .clk(clk_in),
        .mem_we(mem_we),
        .store_size(mem_store_size),
        .load_size(mem_load_size),
        .load_unsigned(mem_load_unsigned),
        .addr(mem_addr),
        .wdata(mem_wdata),
        .io_switch_data(IO_SWITCH_DATA),
        .rdata(mem_rdata),
        .word0(mem0),
        .word1(mem1)
    );
endmodule
