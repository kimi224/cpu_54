`timescale 1ns / 1ps

module scdatamem #(
    parameter DEPTH = 2048,
    parameter BASE_ADDR = 32'h10010000,
    parameter IO_SWITCH_ADDR = BASE_ADDR + 32'h00010000
)(
    input wire clk,
    input wire mem_we,
    input wire [1:0] store_size,
    input wire [1:0] load_size,
    input wire load_unsigned,
    input wire [31:0] addr,
    input wire [31:0] wdata,
    input wire [31:0] io_switch_data,
    output reg [31:0] rdata,
    output wire [31:0] word0,
    output wire [31:0] word1
);
    function integer clog2;
        input integer value;
        integer temp;
        begin
            temp = value - 1;
            clog2 = 0;
            while (temp > 0) begin
                temp = temp >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam ADDR_W = clog2(DEPTH);
    (* ram_style = "distributed" *) reg [31:0] ram [0:DEPTH-1];
    integer i;
    wire [ADDR_W-1:0] word_index = addr[ADDR_W+1:2];
    wire ram_sel = (addr[31:ADDR_W+2] == BASE_ADDR[31:ADDR_W+2]);
    wire io_sel = (addr == IO_SWITCH_ADDR);
    wire [31:0] raw_word = io_sel ? io_switch_data : (ram_sel ? ram[word_index] : 32'h00000000);
    reg [31:0] next_word;
    reg [7:0] selected_byte;
    reg [15:0] selected_half;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            ram[i] = 32'h00000000;
        end
    end

    always @(*) begin
        next_word = raw_word;
        case (store_size)
            2'd1: begin
                case (addr[1:0])
                    2'd0: next_word = {raw_word[31:8], wdata[7:0]};
                    2'd1: next_word = {raw_word[31:16], wdata[7:0], raw_word[7:0]};
                    2'd2: next_word = {raw_word[31:24], wdata[7:0], raw_word[15:0]};
                    default: next_word = {wdata[7:0], raw_word[23:0]};
                endcase
            end
            2'd2: begin
                if (addr[1] == 1'b0) begin
                    next_word = {raw_word[31:16], wdata[15:0]};
                end else begin
                    next_word = {wdata[15:0], raw_word[15:0]};
                end
            end
            default: begin
                next_word = wdata;
            end
        endcase
    end

    always @(posedge clk) begin
        if (mem_we && ram_sel && !io_sel) begin
            ram[word_index] <= next_word;
        end
    end

    always @(*) begin
        case (addr[1:0])
            2'd0: selected_byte = raw_word[7:0];
            2'd1: selected_byte = raw_word[15:8];
            2'd2: selected_byte = raw_word[23:16];
            default: selected_byte = raw_word[31:24];
        endcase

        selected_half = addr[1] ? raw_word[31:16] : raw_word[15:0];

        case (load_size)
            2'd1: rdata = load_unsigned ? {24'h000000, selected_byte} : {{24{selected_byte[7]}}, selected_byte};
            2'd2: rdata = load_unsigned ? {16'h0000, selected_half} : {{16{selected_half[15]}}, selected_half};
            default: rdata = raw_word;
        endcase
    end

    assign word0 = ram[0];
    assign word1 = ram[1];
endmodule
