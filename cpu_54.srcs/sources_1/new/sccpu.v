`timescale 1ns / 1ps

module sccpu #(
    parameter PC_RESET = 32'h00400000,
    parameter EXC_ENTRY = 32'h00400004
)(
    input wire clk_in,
    input wire reset,
    input wire clk_en,
    output reg [31:0] pc,
    input wire [31:0] inst,
    input wire [31:0] mem_rdata,
    output reg mem_we,
    output reg [1:0] mem_store_size,
    output reg [1:0] mem_load_size,
    output reg mem_load_unsigned,
    output reg [31:0] mem_addr,
    output reg [31:0] mem_wdata
);
    wire [5:0] opcode = inst[31:26];
    wire [4:0] rs = inst[25:21];
    wire [4:0] rt = inst[20:16];
    wire [4:0] rd = inst[15:11];
    wire [4:0] shamt = inst[10:6];
    wire [5:0] funct = inst[5:0];
    wire [15:0] imm16 = inst[15:0];
    wire [25:0] imm26 = inst[25:0];

    wire [31:0] rs_data;
    wire [31:0] rt_data;
    wire [31:0] sign_ext_imm = {{16{imm16[15]}}, imm16};
    wire [31:0] zero_ext_imm = {16'h0000, imm16};
    wire [31:0] pc_plus4 = pc + 32'h00000004;
    wire [31:0] branch_target = pc_plus4 + (sign_ext_imm << 2);
    wire [31:0] jump_target = {pc_plus4[31:28], imm26, 2'b00};

    reg reg_we;
    reg [4:0] reg_waddr;
    reg [31:0] reg_wdata;
    reg [31:0] next_pc;
    reg [31:0] hi;
    reg [31:0] lo;
    reg [31:0] hi_next;
    reg [31:0] lo_next;
    reg div_busy;
    reg div_signed;
    reg div_neg_q;
    reg div_neg_r;
    reg [5:0] div_count;
    reg [31:0] div_divisor;
    reg [31:0] div_dividend;
    reg [31:0] div_quotient;
    reg [31:0] div_remainder;
    reg [31:0] div_rem_shift;
    reg [31:0] div_quot_next;
    reg [31:0] div_rem_next;
    reg [31:0] cp0_status;
    reg [31:0] cp0_cause;
    reg [31:0] cp0_epc;
    reg [31:0] cp0_reg8;
    reg [31:0] cp0_status_next;
    reg [31:0] cp0_cause_next;
    reg [31:0] cp0_epc_next;
    reg [31:0] cp0_reg8_next;
    reg take_exception;
    reg [7:0] exception_code;
    integer i;

    wire is_div_inst = (opcode == 6'h00) && ((funct == 6'h1a) || (funct == 6'h1b));
    wire is_div_signed = (opcode == 6'h00) && (funct == 6'h1a);
    wire [31:0] div_rs_abs = (is_div_signed && rs_data[31]) ? (~rs_data + 32'd1) : rs_data;
    wire [31:0] div_rt_abs = (is_div_signed && rt_data[31]) ? (~rt_data + 32'd1) : rt_data;
    wire is_mult_signed = (opcode == 6'h00) && (funct == 6'h18);
    wire mult_neg = is_mult_signed && (rs_data[31] ^ rt_data[31]);
    wire [31:0] mult_a_mag = (is_mult_signed && rs_data[31]) ? (~rs_data + 32'd1) : rs_data;
    wire [31:0] mult_b_mag = (is_mult_signed && rt_data[31]) ? (~rt_data + 32'd1) : rt_data;
    (* use_dsp = "yes" *) wire [31:0] mult_pp0 = mult_a_mag[15:0] * mult_b_mag[15:0];
    (* use_dsp = "yes" *) wire [31:0] mult_pp1 = mult_a_mag[31:16] * mult_b_mag[15:0];
    (* use_dsp = "yes" *) wire [31:0] mult_pp2 = mult_a_mag[15:0] * mult_b_mag[31:16];
    (* use_dsp = "yes" *) wire [31:0] mult_pp3 = mult_a_mag[31:16] * mult_b_mag[31:16];
    wire [63:0] mult_unsigned_result = {32'h00000000, mult_pp0}
                                      + {16'h0000, mult_pp1, 16'h0000}
                                      + {16'h0000, mult_pp2, 16'h0000}
                                      + {mult_pp3, 32'h00000000};
    wire [63:0] mult_result = mult_neg ? (~mult_unsigned_result + 64'd1) : mult_unsigned_result;

    regfile cpu_ref (
        .clk(clk_in),
        .reset(reset),
        .clk_en(clk_en),
        .we(reg_we),
        .waddr(reg_waddr),
        .wdata(reg_wdata),
        .raddr1(rs),
        .raddr2(rt),
        .rdata1(rs_data),
        .rdata2(rt_data)
    );

    function [31:0] cp0_read;
        input [4:0] addr;
        begin
            case (addr)
                5'd8: cp0_read = cp0_reg8;
                5'd12: cp0_read = cp0_status;
                5'd13: cp0_read = cp0_cause;
                5'd14: cp0_read = cp0_epc;
                default: cp0_read = 32'h00000000;
            endcase
        end
    endfunction

    function [31:0] count_leading_zeros;
        input [31:0] value;
        reg found;
        begin
            count_leading_zeros = 32'd0;
            found = 1'b0;
            for (i = 31; i >= 0; i = i - 1) begin
                if (!found && value[i]) begin
                    found = 1'b1;
                end else if (!found) begin
                    count_leading_zeros = count_leading_zeros + 32'd1;
                end
            end
        end
    endfunction

    initial begin
        pc = PC_RESET;
        hi = 32'h00000000;
        lo = 32'h00000000;
        div_busy = 1'b0;
        div_signed = 1'b0;
        div_neg_q = 1'b0;
        div_neg_r = 1'b0;
        div_count = 6'd0;
        div_divisor = 32'h00000000;
        div_dividend = 32'h00000000;
        div_quotient = 32'h00000000;
        div_remainder = 32'h00000000;
        cp0_status = 32'h00000000;
        cp0_cause = 32'h00000000;
        cp0_epc = 32'h00000000;
        cp0_reg8 = 32'h00000000;
    end

    always @(*) begin
        reg_we = 1'b0;
        reg_waddr = rt;
        reg_wdata = 32'h00000000;
        mem_we = 1'b0;
        mem_store_size = 2'd0;
        mem_load_size = 2'd0;
        mem_load_unsigned = 1'b0;
        mem_addr = rs_data + sign_ext_imm;
        mem_wdata = rt_data;
        next_pc = pc_plus4;
        hi_next = hi;
        lo_next = lo;
        cp0_status_next = cp0_status;
        cp0_cause_next = cp0_cause;
        cp0_epc_next = cp0_epc;
        cp0_reg8_next = cp0_reg8;
        take_exception = 1'b0;
        exception_code = 8'h00;

        case (opcode)
            6'h00: begin
                reg_waddr = rd;
                case (funct)
                    6'h00: begin reg_we = 1'b1; reg_wdata = rt_data << shamt; end
                    6'h02: begin reg_we = 1'b1; reg_wdata = rt_data >> shamt; end
                    6'h03: begin reg_we = 1'b1; reg_wdata = $signed(rt_data) >>> shamt; end
                    6'h04: begin reg_we = 1'b1; reg_wdata = rt_data << rs_data[4:0]; end
                    6'h06: begin reg_we = 1'b1; reg_wdata = rt_data >> rs_data[4:0]; end
                    6'h07: begin reg_we = 1'b1; reg_wdata = $signed(rt_data) >>> rs_data[4:0]; end
                    6'h08: begin next_pc = rs_data; end
                    6'h09: begin reg_we = 1'b1; reg_waddr = (rd == 5'd0) ? 5'd31 : rd; reg_wdata = pc_plus4; next_pc = rs_data; end
                    6'h0c: begin take_exception = 1'b1; exception_code = 8'h20; end
                    6'h0d: begin take_exception = 1'b1; exception_code = 8'h24; end
                    6'h10: begin reg_we = 1'b1; reg_wdata = hi; end
                    6'h11: begin hi_next = rs_data; end
                    6'h12: begin reg_we = 1'b1; reg_wdata = lo; end
                    6'h13: begin lo_next = rs_data; end
                    6'h18: begin hi_next = mult_result[63:32]; lo_next = mult_result[31:0]; end
                    6'h19: begin hi_next = mult_result[63:32]; lo_next = mult_result[31:0]; end
                    6'h1a, 6'h1b: begin end
                    6'h20, 6'h21: begin reg_we = 1'b1; reg_wdata = rs_data + rt_data; end
                    6'h22, 6'h23: begin reg_we = 1'b1; reg_wdata = rs_data - rt_data; end
                    6'h24: begin reg_we = 1'b1; reg_wdata = rs_data & rt_data; end
                    6'h25: begin reg_we = 1'b1; reg_wdata = rs_data | rt_data; end
                    6'h26: begin reg_we = 1'b1; reg_wdata = rs_data ^ rt_data; end
                    6'h27: begin reg_we = 1'b1; reg_wdata = ~(rs_data | rt_data); end
                    6'h2a: begin reg_we = 1'b1; reg_wdata = ($signed(rs_data) < $signed(rt_data)) ? 32'h00000001 : 32'h00000000; end
                    6'h2b: begin reg_we = 1'b1; reg_wdata = (rs_data < rt_data) ? 32'h00000001 : 32'h00000000; end
                    6'h34: begin if (rs_data == rt_data) begin take_exception = 1'b1; exception_code = 8'h34; end end
                    default: begin end
                endcase
            end
            6'h01: begin
                if ((rt == 5'h01) && (rs_data[31] == 1'b0)) begin
                    next_pc = branch_target;
                end
            end
            6'h02: begin next_pc = jump_target; end
            6'h03: begin reg_we = 1'b1; reg_waddr = 5'd31; reg_wdata = pc_plus4; next_pc = jump_target; end
            6'h04: begin if (rs_data == rt_data) next_pc = branch_target; end
            6'h05: begin if (rs_data != rt_data) next_pc = branch_target; end
            6'h08, 6'h09: begin reg_we = 1'b1; reg_wdata = rs_data + sign_ext_imm; end
            6'h0a: begin reg_we = 1'b1; reg_wdata = ($signed(rs_data) < $signed(sign_ext_imm)) ? 32'h00000001 : 32'h00000000; end
            6'h0b: begin reg_we = 1'b1; reg_wdata = (rs_data < sign_ext_imm) ? 32'h00000001 : 32'h00000000; end
            6'h0c: begin reg_we = 1'b1; reg_wdata = rs_data & zero_ext_imm; end
            6'h0d: begin reg_we = 1'b1; reg_wdata = rs_data | zero_ext_imm; end
            6'h0e: begin reg_we = 1'b1; reg_wdata = rs_data ^ zero_ext_imm; end
            6'h0f: begin reg_we = 1'b1; reg_wdata = {imm16, 16'h0000}; end
            6'h10: begin
                if (rs == 5'h00) begin
                    reg_we = 1'b1;
                    reg_wdata = cp0_read(rd);
                end else if (rs == 5'h04) begin
                    case (rd)
                        5'd8: cp0_reg8_next = rt_data;
                        5'd12: cp0_status_next = rt_data;
                        5'd13: cp0_cause_next = rt_data;
                        5'd14: cp0_epc_next = rt_data;
                        default: begin end
                    endcase
                end else if ((rs == 5'h10) && (funct == 6'h18)) begin
                    next_pc = cp0_epc + 32'h00000004;
                end
            end
            6'h20: begin reg_we = 1'b1; mem_load_size = 2'd1; reg_wdata = mem_rdata; end
            6'h21: begin reg_we = 1'b1; mem_load_size = 2'd2; reg_wdata = mem_rdata; end
            6'h23: begin reg_we = 1'b1; mem_load_size = 2'd0; reg_wdata = mem_rdata; end
            6'h24: begin reg_we = 1'b1; mem_load_size = 2'd1; mem_load_unsigned = 1'b1; reg_wdata = mem_rdata; end
            6'h25: begin reg_we = 1'b1; mem_load_size = 2'd2; mem_load_unsigned = 1'b1; reg_wdata = mem_rdata; end
            6'h28: begin mem_we = 1'b1; mem_store_size = 2'd1; end
            6'h29: begin mem_we = 1'b1; mem_store_size = 2'd2; end
            6'h2b: begin mem_we = 1'b1; mem_store_size = 2'd0; end
            6'h1c: begin
                if (funct == 6'h20) begin
                    reg_we = 1'b1;
                    reg_waddr = rd;
                    reg_wdata = count_leading_zeros(rs_data);
                end
            end
            default: begin end
        endcase

        if (take_exception) begin
            cp0_epc_next = pc;
            cp0_cause_next = {24'h000000, exception_code};
            next_pc = EXC_ENTRY;
        end
    end

    always @(posedge clk_in) begin
        if (reset) begin
            pc <= PC_RESET;
            hi <= 32'h00000000;
            lo <= 32'h00000000;
            div_busy <= 1'b0;
            div_signed <= 1'b0;
            div_neg_q <= 1'b0;
            div_neg_r <= 1'b0;
            div_count <= 6'd0;
            div_divisor <= 32'h00000000;
            div_dividend <= 32'h00000000;
            div_quotient <= 32'h00000000;
            div_remainder <= 32'h00000000;
            cp0_status <= 32'h00000000;
            cp0_cause <= 32'h00000000;
            cp0_epc <= 32'h00000000;
            cp0_reg8 <= 32'h00000000;
        end else if (clk_en) begin
            if (div_busy) begin
                div_rem_shift = {div_remainder[30:0], div_dividend[31]};
                if (div_rem_shift >= div_divisor) begin
                    div_rem_next = div_rem_shift - div_divisor;
                    div_quot_next = {div_quotient[30:0], 1'b1};
                end else begin
                    div_rem_next = div_rem_shift;
                    div_quot_next = {div_quotient[30:0], 1'b0};
                end

                div_dividend <= {div_dividend[30:0], 1'b0};
                div_remainder <= div_rem_next;
                div_quotient <= div_quot_next;
                div_count <= div_count + 6'd1;

                if (div_count == 6'd31) begin
                    div_busy <= 1'b0;
                    hi <= div_neg_r ? (~div_rem_next + 32'd1) : div_rem_next;
                    lo <= div_neg_q ? (~div_quot_next + 32'd1) : div_quot_next;
                    pc <= next_pc;
                end
            end else if (is_div_inst && (rt_data != 32'h00000000)) begin
                div_busy <= 1'b1;
                div_signed <= is_div_signed;
                div_neg_q <= is_div_signed && (rs_data[31] ^ rt_data[31]);
                div_neg_r <= is_div_signed && rs_data[31];
                div_count <= 6'd0;
                div_divisor <= div_rt_abs;
                div_dividend <= div_rs_abs;
                div_quotient <= 32'h00000000;
                div_remainder <= 32'h00000000;
            end else begin
                pc <= next_pc;
                hi <= hi_next;
                lo <= lo_next;
                cp0_status <= cp0_status_next;
                cp0_cause <= cp0_cause_next;
                cp0_epc <= cp0_epc_next;
                cp0_reg8 <= cp0_reg8_next;
            end
        end
    end
endmodule
