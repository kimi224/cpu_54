from pathlib import Path
import xlsxwriter

root = Path(__file__).resolve().parents[1]
path = root / "CPU54_操作时间表.xlsx"

rows = [
    (1, "sll", "移位", "PC->IMEM; 读 rs/rt/rd/shamt", "rt << shamt", "rd <- result", "PC+4", "T0 单周期"),
    (2, "srl", "移位", "PC->IMEM; 读 rs/rt/rd/shamt", "rt >> shamt", "rd <- result", "PC+4", "T0 单周期"),
    (3, "sra", "移位", "PC->IMEM; 读 rs/rt/rd/shamt", "signed(rt) >>> shamt", "rd <- result", "PC+4", "T0 单周期"),
    (4, "sllv", "移位", "PC->IMEM; 读 rs/rt/rd", "rt << rs[4:0]", "rd <- result", "PC+4", "T0 单周期"),
    (5, "srlv", "移位", "PC->IMEM; 读 rs/rt/rd", "rt >> rs[4:0]", "rd <- result", "PC+4", "T0 单周期"),
    (6, "srav", "移位", "PC->IMEM; 读 rs/rt/rd", "signed(rt) >>> rs[4:0]", "rd <- result", "PC+4", "T0 单周期"),
    (7, "add", "R型算术", "PC->IMEM; 读 rs/rt/rd", "rs + rt", "rd <- result", "PC+4", "T0 单周期"),
    (8, "addu", "R型算术", "PC->IMEM; 读 rs/rt/rd", "rs + rt", "rd <- result", "PC+4", "T0 单周期"),
    (9, "sub", "R型算术", "PC->IMEM; 读 rs/rt/rd", "rs - rt", "rd <- result", "PC+4", "T0 单周期"),
    (10, "subu", "R型算术", "PC->IMEM; 读 rs/rt/rd", "rs - rt", "rd <- result", "PC+4", "T0 单周期"),
    (11, "and", "逻辑", "PC->IMEM; 读 rs/rt/rd", "rs & rt", "rd <- result", "PC+4", "T0 单周期"),
    (12, "or", "逻辑", "PC->IMEM; 读 rs/rt/rd", "rs | rt", "rd <- result", "PC+4", "T0 单周期"),
    (13, "xor", "逻辑", "PC->IMEM; 读 rs/rt/rd", "rs ^ rt", "rd <- result", "PC+4", "T0 单周期"),
    (14, "nor", "逻辑", "PC->IMEM; 读 rs/rt/rd", "~(rs | rt)", "rd <- result", "PC+4", "T0 单周期"),
    (15, "slt", "比较", "PC->IMEM; 读 rs/rt/rd", "signed(rs) < signed(rt)", "rd <- 0/1", "PC+4", "T0 单周期"),
    (16, "sltu", "比较", "PC->IMEM; 读 rs/rt/rd", "rs < rt", "rd <- 0/1", "PC+4", "T0 单周期"),
    (17, "addi", "立即数", "PC->IMEM; 读 rs/rt; sign_ext", "rs + sign_ext(imm)", "rt <- result", "PC+4", "T0 单周期"),
    (18, "addiu", "立即数", "PC->IMEM; 读 rs/rt; sign_ext", "rs + sign_ext(imm)", "rt <- result", "PC+4", "T0 单周期"),
    (19, "slti", "立即数比较", "PC->IMEM; 读 rs/rt; sign_ext", "signed(rs) < signed(imm)", "rt <- 0/1", "PC+4", "T0 单周期"),
    (20, "sltiu", "立即数比较", "PC->IMEM; 读 rs/rt; sign_ext", "rs < sign_ext(imm)", "rt <- 0/1", "PC+4", "T0 单周期"),
    (21, "andi", "立即数逻辑", "PC->IMEM; 读 rs/rt; zero_ext", "rs & zero_ext(imm)", "rt <- result", "PC+4", "T0 单周期"),
    (22, "ori", "立即数逻辑", "PC->IMEM; 读 rs/rt; zero_ext", "rs | zero_ext(imm)", "rt <- result", "PC+4", "T0 单周期"),
    (23, "xori", "立即数逻辑", "PC->IMEM; 读 rs/rt; zero_ext", "rs ^ zero_ext(imm)", "rt <- result", "PC+4", "T0 单周期"),
    (24, "lui", "立即数", "PC->IMEM; 读 imm16", "{imm16,16'b0}", "rt <- result", "PC+4", "T0 单周期"),
    (25, "beq", "分支", "PC->IMEM; 读 rs/rt; 计算 PC+4", "比较 rs == rt", "无寄存器写回", "相等: branch_target; 否则 PC+4", "T0 单周期"),
    (26, "bne", "分支", "PC->IMEM; 读 rs/rt; 计算 PC+4", "比较 rs != rt", "无寄存器写回", "不等: branch_target; 否则 PC+4", "T0 单周期"),
    (27, "bgez", "分支", "PC->IMEM; 读 rs; 计算 PC+4", "检查 rs[31]==0", "无寄存器写回", "满足: branch_target; 否则 PC+4", "T0 单周期"),
    (28, "j", "跳转", "PC->IMEM; 计算 PC+4", "拼接 jump_target", "无寄存器写回", "jump_target", "T0 单周期"),
    (29, "jal", "跳转链接", "PC->IMEM; 计算 PC+4", "拼接 jump_target", "r31 <- PC+4", "jump_target", "T0 单周期"),
    (30, "jr", "跳转寄存器", "PC->IMEM; 读 rs", "rs -> next_pc", "无寄存器写回", "rs", "T0 单周期"),
    (31, "jalr", "跳转链接", "PC->IMEM; 读 rs; 计算 PC+4", "rs -> next_pc", "rd/r31 <- PC+4", "rs", "T0 单周期"),
    (32, "lw", "访存读", "PC->IMEM; 读 rs/rt", "addr=rs+sign_ext(imm); DMEM读字", "rt <- mem_rdata", "PC+4", "T0 单周期"),
    (33, "lh", "访存读", "PC->IMEM; 读 rs/rt", "addr=rs+imm; DMEM读半字", "rt <- sign_ext(half)", "PC+4", "T0 单周期"),
    (34, "lhu", "访存读", "PC->IMEM; 读 rs/rt", "addr=rs+imm; DMEM读半字", "rt <- zero_ext(half)", "PC+4", "T0 单周期"),
    (35, "lb", "访存读", "PC->IMEM; 读 rs/rt", "addr=rs+imm; DMEM读字节", "rt <- sign_ext(byte)", "PC+4", "T0 单周期"),
    (36, "lbu", "访存读", "PC->IMEM; 读 rs/rt", "addr=rs+imm; DMEM读字节", "rt <- zero_ext(byte)", "PC+4", "T0 单周期"),
    (37, "sw", "访存写", "PC->IMEM; 读 rs/rt", "addr=rs+sign_ext(imm)", "DMEM[addr] <- rt", "PC+4", "T0 单周期"),
    (38, "sh", "访存写", "PC->IMEM; 读 rs/rt", "addr=rs+sign_ext(imm)", "DMEM[addr] <- rt[15:0]", "PC+4", "T0 单周期"),
    (39, "sb", "访存写", "PC->IMEM; 读 rs/rt", "addr=rs+sign_ext(imm)", "DMEM[addr] <- rt[7:0]", "PC+4", "T0 单周期"),
    (40, "mult", "乘法", "PC->IMEM; 读 rs/rt", "signed 32x32 multiply", "HI/LO <- 64-bit product", "PC+4", "T0 单周期"),
    (41, "multu", "乘法", "PC->IMEM; 读 rs/rt", "unsigned 32x32 multiply", "HI/LO <- 64-bit product", "PC+4", "T0 单周期"),
    (42, "div", "除法", "PC->IMEM; 读 rs/rt", "锁存绝对值，启动迭代", "T33: HI<-remainder; LO<-quotient", "T33 更新为 next_pc", "T0 + T1..T32 + T33"),
    (43, "divu", "除法", "PC->IMEM; 读 rs/rt", "锁存被除数/除数，启动迭代", "T33: HI<-remainder; LO<-quotient", "T33 更新为 next_pc", "T0 + T1..T32 + T33"),
    (44, "mfhi", "HI/LO", "PC->IMEM; 读 rd", "读取 HI", "rd <- HI", "PC+4", "T0 单周期"),
    (45, "mthi", "HI/LO", "PC->IMEM; 读 rs", "rs -> HI", "HI <- rs", "PC+4", "T0 单周期"),
    (46, "mflo", "HI/LO", "PC->IMEM; 读 rd", "读取 LO", "rd <- LO", "PC+4", "T0 单周期"),
    (47, "mtlo", "HI/LO", "PC->IMEM; 读 rs", "rs -> LO", "LO <- rs", "PC+4", "T0 单周期"),
    (48, "mfc0", "CP0", "PC->IMEM; 读 rd/rt", "读取 CP0 寄存器", "rt <- CP0(rd)", "PC+4", "T0 单周期"),
    (49, "mtc0", "CP0", "PC->IMEM; 读 rt/rd", "写 CP0 寄存器", "CP0(rd) <- rt", "PC+4", "T0 单周期"),
    (50, "clz", "特殊", "PC->IMEM; 读 rs/rd", "统计 rs 的前导零", "rd <- count", "PC+4", "T0 单周期"),
    (51, "syscall", "异常", "PC->IMEM; 读 opcode/funct", "识别 syscall 异常", "EPC <- PC; Cause <- 0x20", "EXC_ENTRY", "T0 单周期"),
    (52, "break", "异常", "PC->IMEM; 读 opcode/funct", "识别 break 异常", "EPC <- PC; Cause <- 0x24", "EXC_ENTRY", "T0 单周期"),
    (53, "teq", "异常", "PC->IMEM; 读 rs/rt", "rs == rt 时触发异常", "EPC <- PC; Cause <- 0x34", "EXC_ENTRY 或 PC+4", "T0 单周期"),
    (54, "eret", "异常返回", "PC->IMEM; 读 CP0 EPC", "EPC + 4", "无寄存器写回", "cp0_epc + 4", "T0 单周期"),
]

wb = xlsxwriter.Workbook(path)
ws = wb.add_worksheet("操作时间表")
ws.hide_gridlines(2)
title = wb.add_format({"font_name": "Calibri", "bold": True, "font_size": 16, "font_color": "#000000", "align": "center", "valign": "vcenter", "bottom": 2})
subtitle = wb.add_format({"font_name": "Calibri", "italic": True, "font_color": "#000000", "text_wrap": True})
header = wb.add_format({"font_name": "Calibri", "bold": True, "font_color": "#000000", "bottom": 1, "align": "center", "valign": "vcenter", "text_wrap": True})
body = wb.add_format({"font_name": "Calibri", "font_color": "#000000", "bottom": 1, "valign": "top", "text_wrap": True})
num = wb.add_format({"font_name": "Calibri", "font_color": "#000000", "bottom": 1, "align": "center", "valign": "top"})

ws.merge_range("A1:H1", "54 条指令 CPU 操作时间表", title)
ws.set_row(0, 28)
ws.merge_range("A2:H2", "普通指令在 T0 内完成；div/divu 在 T0 启动、T1-T32 迭代、T33 提交结果。", subtitle)
headers = ["序号", "指令", "类别", "取指/译码", "执行或访存", "写回/状态更新", "PC 选择", "周期说明"]
for col, h in enumerate(headers):
    ws.write(3, col, h, header)
for r, row in enumerate(rows, start=4):
    fmt = body
    ws.write_number(r, 0, row[0], num)
    for c, value in enumerate(row[1:], start=1):
        ws.write(r, c, value, fmt)

ws.set_column("A:A", 7)
ws.set_column("B:B", 12)
ws.set_column("C:C", 14)
ws.set_column("D:D", 29)
ws.set_column("E:E", 33)
ws.set_column("F:F", 32)
ws.set_column("G:G", 29)
ws.set_column("H:H", 18)
ws.freeze_panes(4, 1)
ws.autofilter(3, 0, 3 + len(rows), 7)

ctrl = wb.add_worksheet("控制信号逻辑表达式")
ctrl.hide_gridlines(2)
ctrl.merge_range("A1:D1", "CPU54 主要控制信号编码", title)
ctrl.write_row("A3", ["信号", "含义", "有效条件/取值", "备注"], header)
controls = [
    ("reg_we", "通用寄存器写使能", "R_ALU | I_ARITH | LOAD | JAL | JALR | MFHI | MFLO | MFC0 | CLZ", "除法不直接写通用寄存器"),
    ("mem_we", "数据 RAM 写使能", "opcode in {SB, SH, SW}", "下板时有效写入还受 clk_en 门控"),
    ("mem_store_size", "写数据宽度", "SB=byte, SH=half, SW=word", "对应 opcode 0x28/0x29/0x2B"),
    ("mem_load_size", "读数据宽度", "LB/LBU=byte, LH/LHU=half, LW=word", "对应 opcode 0x20/0x21/0x23/0x24/0x25"),
    ("mem_load_unsigned", "读数据是否零扩展", "LBU | LHU", "LB/LH 使用符号扩展"),
    ("reg_waddr", "寄存器写地址", "R 型/HI/LO/CLZ 取 rd；I 型/Load/MFC0 取 rt；JAL 取 r31", "JALR 的 rd=0 时写 r31"),
    ("next_pc", "下一条 PC", "PC+4 / branch_target / jump_target / rs_data / cp0_epc+4 / EXC_ENTRY", "由分支、跳转、异常条件选择"),
    ("div_busy", "除法器忙状态", "DIV/DIVU 启动后置 1，32 次迭代后清 0", "忙期间 PC 保持不变"),
    ("cp0_*_next", "CP0 下一状态", "MTC0 写入；异常写 EPC/Cause；ERET 读取 EPC", "posedge 时钟统一提交"),
]
for r, row in enumerate(controls, start=3):
    for c, value in enumerate(row):
        ctrl.write(r, c, value, body)
ctrl.set_column("A:A", 20)
ctrl.set_column("B:B", 24)
ctrl.set_column("C:C", 62)
ctrl.set_column("D:D", 32)
ctrl.freeze_panes(3, 0)
ctrl.autofilter(2, 0, 2 + len(controls), 3)

wb.close()
print(path)
