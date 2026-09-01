from pathlib import Path
from math import atan2, cos, sin
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
DP = ROOT / "datapath_diagrams"
FLOW = ROOT / "instruction_flow_diagrams"
DP.mkdir(exist_ok=True)
FLOW.mkdir(exist_ok=True)

FONT = "C:/Windows/Fonts/calibri.ttf"
BOLD = "C:/Windows/Fonts/calibrib.ttf"
font = ImageFont.truetype(FONT, 24)
small = ImageFont.truetype(FONT, 19)
title_font = ImageFont.truetype(BOLD, 31)
tiny = ImageFont.truetype(FONT, 17)

instructions = [
    ("sll", "shift", "rt << shamt", "rd"), ("srl", "shift", "rt >> shamt", "rd"),
    ("sra", "shift", "signed(rt) >>> shamt", "rd"), ("sllv", "shift", "rt << rs[4:0]", "rd"),
    ("srlv", "shift", "rt >> rs[4:0]", "rd"), ("srav", "shift", "signed(rt) >>> rs[4:0]", "rd"),
    ("add", "alu", "rs + rt", "rd"), ("addu", "alu", "rs + rt", "rd"),
    ("sub", "alu", "rs - rt", "rd"), ("subu", "alu", "rs - rt", "rd"),
    ("and", "logic", "rs & rt", "rd"), ("or", "logic", "rs | rt", "rd"),
    ("xor", "logic", "rs ^ rt", "rd"), ("nor", "logic", "~(rs | rt)", "rd"),
    ("slt", "compare", "signed(rs) < signed(rt)", "rd"), ("sltu", "compare", "rs < rt", "rd"),
    ("addi", "imm", "rs + sign_ext(imm)", "rt"), ("addiu", "imm", "rs + sign_ext(imm)", "rt"),
    ("slti", "imm", "signed(rs) < signed(imm)", "rt"), ("sltiu", "imm", "rs < sign_ext(imm)", "rt"),
    ("andi", "imm_logic", "rs & zero_ext(imm)", "rt"), ("ori", "imm_logic", "rs | zero_ext(imm)", "rt"),
    ("xori", "imm_logic", "rs ^ zero_ext(imm)", "rt"), ("lui", "lui", "{imm16, 16'b0}", "rt"),
    ("beq", "branch", "rs == rt; branch target", "PC"), ("bne", "branch", "rs != rt; branch target", "PC"),
    ("bgez", "branch", "rs[31] == 0; branch target", "PC"), ("j", "jump", "jump target", "PC"),
    ("jal", "jal", "jump target; save PC+4", "PC + r31"), ("jr", "jr", "rs -> PC", "PC"),
    ("jalr", "jalr", "rs -> PC; save PC+4", "PC + rd/r31"), ("lw", "load", "addr -> DMEM word", "rt"),
    ("lh", "load", "addr -> DMEM half -> sign_ext", "rt"), ("lhu", "load", "addr -> DMEM half -> zero_ext", "rt"),
    ("lb", "load", "addr -> DMEM byte -> sign_ext", "rt"), ("lbu", "load", "addr -> DMEM byte -> zero_ext", "rt"),
    ("sw", "store", "addr; DMEM <- rt", "DMEM"), ("sh", "store", "addr; DMEM <- rt[15:0]", "DMEM"),
    ("sb", "store", "addr; DMEM <- rt[7:0]", "DMEM"), ("mult", "mult", "signed rs * rt", "HI/LO"),
    ("multu", "mult", "unsigned rs * rt", "HI/LO"), ("div", "div", "signed quotient/remainder", "HI/LO"),
    ("divu", "div", "unsigned quotient/remainder", "HI/LO"), ("mfhi", "mfhi", "HI -> rd", "rd"),
    ("mthi", "mthi", "rs -> HI", "HI"), ("mflo", "mflo", "LO -> rd", "rd"),
    ("mtlo", "mtlo", "rs -> LO", "LO"), ("mfc0", "mfc0", "CP0(rd) -> rt", "rt"),
    ("mtc0", "mtc0", "rt -> CP0(rd)", "CP0"), ("clz", "count", "leading-zero count(rs)", "rd"),
    ("syscall", "exception", "save EPC/Cause", "EXC_ENTRY"), ("break", "exception", "save EPC/Cause", "EXC_ENTRY"),
    ("teq", "exception", "if rs == rt: save EPC/Cause", "EXC_ENTRY/PC+4"), ("eret", "eret", "CP0 EPC + 4", "PC"),
]

def text_center(draw, xy, value, f=font):
    bb = draw.multiline_textbbox((0, 0), value, font=f, align="center", spacing=3)
    draw.multiline_text((xy[0] - (bb[2]-bb[0])/2, xy[1] - (bb[3]-bb[1])/2), value, font=f, fill="black", align="center", spacing=3)

def box(draw, rect, value, fill="#F5F5F5", f=font):
    draw.rounded_rectangle(rect, radius=8, outline="black", fill=fill, width=2)
    text_center(draw, ((rect[0]+rect[2])//2, (rect[1]+rect[3])//2), value, f)

def arrow(draw, points, label=None, label_xy=None):
    draw.line(points, fill="black", width=3, joint="curve")
    x1, y1 = points[-2]
    x2, y2 = points[-1]
    angle = atan2(y2-y1, x2-x1)
    size = 13
    p2 = (x2-size*cos(angle-0.45), y2-size*sin(angle-0.45))
    p3 = (x2-size*cos(angle+0.45), y2-size*sin(angle+0.45))
    draw.polygon([(x2,y2), p2, p3], fill="black")
    if label:
        draw.text(label_xy or ((x1+x2)//2, (y1+y2)//2), label, font=small, fill="black", anchor="mm")

def datapath(name, kind, operation, dest):
    W, H = 1900, 900
    img = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(img)
    d.text((W//2, 35), f"{name.upper()} instruction datapath", font=title_font, fill="black", anchor="mm")
    box(d, (60, 345, 230, 465), "PC")
    box(d, (330, 300, 570, 510), "Instruction\nMemory")
    box(d, (670, 300, 910, 510), "Decode /\nControl")
    box(d, (670, 610, 950, 770), "Register File\nrs / rt / rd")
    unit_label = {
        "load": "Address ALU\nrs + imm", "store": "Address ALU\nrs + imm", "branch": "Comparator +\nbranch target",
        "jump": "Jump target", "jal": "Jump target", "jr": "Register target", "jalr": "Register target",
        "mult": "Multiplier\n64-bit", "div": "Divider\n32 iterations", "mfhi": "HI read", "mthi": "HI write",
        "mflo": "LO read", "mtlo": "LO write", "mfc0": "CP0 read", "mtc0": "CP0 write",
        "exception": "Exception\nlogic", "eret": "EPC + 4", "count": "CLZ unit",
    }.get(kind, f"ALU\n{operation}")
    box(d, (1050, 300, 1340, 510), unit_label)
    result_label = "Data Memory" if kind in {"load", "store"} else ("HI / LO" if kind in {"mult", "div", "mthi", "mtlo", "mfhi", "mflo"} else ("CP0" if kind in {"mfc0", "mtc0"} else f"Writeback\n{dest}"))
    box(d, (1490, 300, 1770, 510), result_label)
    box(d, (1030, 90, 1320, 190), "Next-PC MUX")
    box(d, (420, 90, 700, 190), "PC + 4")

    arrow(d, [(230,405),(330,405)], "pc[12:2]", (280,377))
    arrow(d, [(570,405),(670,405)], "inst", (620,377))
    arrow(d, [(790,510),(790,610)], "rs/rt", (835,560))
    arrow(d, [(950,690),(1000,690),(1000,470),(1050,470)], "operand", (1010,650))
    arrow(d, [(910,405),(1050,405)], "control / imm", (980,377))
    arrow(d, [(1340,405),(1490,405)], operation, (1415,377))
    if kind in {"load", "store"}:
        arrow(d, [(1490,450),(1400,450),(1400,690),(950,690)], "load/store data", (1220,710))
    elif kind not in {"jump", "branch", "jr", "jal", "jalr", "exception", "eret"}:
        arrow(d, [(1620,510),(1620,590),(810,590),(810,610)], "write enable", (1260,615))
    arrow(d, [(145,345),(145,140),(420,140)], "PC", (205,115))
    arrow(d, [(700,140),(1030,140)], "pc + 4", (865,110))
    arrow(d, [(1320,140),(1650,140),(1650,300)], "next_pc", (1460,110))
    if kind in {"branch", "jump", "jal", "jr", "jalr", "exception", "eret"}:
        arrow(d, [(1180,300),(1180,190)], "target", (1215,245))
    d.text((60, 835), f"Active path: {operation}    Destination: {dest}    Normal PC update: PC + 4", font=small, fill="black")
    img.save(DP / f"{name}.png", dpi=(180,180))

def flowchart(name, kind, operation, dest):
    W, H = 1300, 1050
    img = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(img)
    d.text((W//2, 35), f"{name.upper()} instruction flow", font=title_font, fill="black", anchor="mm")
    stages = [("T0: Fetch", "PC -> IMEM; IR <- instruction"), ("T0: Decode", "decode opcode/funct; read rs/rt/rd")]
    if kind in {"div"}:
        stages += [("T0: Start", operation + "; latch operands"), ("T1-T32: Iterate", "shift/subtract quotient bit; PC holds"), ("T33: Commit", "HI <- remainder; LO <- quotient")]
    else:
        stages += [("T0: Execute", operation)]
        if kind == "load": stages.append(("T0: Memory", "read selected byte/half/word; extend"))
        if kind == "store": stages.append(("T0: Memory", "write selected byte/half/word"))
        if kind not in {"branch", "jump", "jr", "jal", "jalr", "store", "exception", "eret", "mthi", "mtlo", "mtc0"}:
            stages.append(("T0: Writeback", f"{dest} <- result"))
        elif kind in {"jal", "jalr"}:
            stages.append(("T0: Link", "save PC+4 to r31/rd"))
        elif kind in {"mthi", "mtlo", "mtc0"}:
            stages.append(("T0: State update", f"write {dest}"))
        elif kind == "exception":
            stages.append(("T0: Exception", "EPC <- PC; Cause <- code"))
    stages.append(("T0 / T33: PC update", "PC <- selected next_pc"))
    x1, x2 = 180, 1120
    top = 95
    h = 115
    gap = 32
    for i, (head, body) in enumerate(stages):
        y1 = top + i*(h+gap)
        fill = "#F5F5F5" if "Iterate" not in head else "#FFF8E1"
        box(d, (x1,y1,x2,y1+h), head + "\n" + body, fill, font)
        if i:
            arrow(d, [(650,y1-gap),(650,y1)], None)
    if kind in {"branch"}:
        d.text((1140, top+2*(h+gap)+h//2), "condition true:\nbranch target\ncondition false:\nPC + 4", font=small, fill="black", anchor="lm")
    if kind in {"div"}:
        d.text((650, top+3*(h+gap)+h+12), "32-cycle restoring-division iteration", font=small, fill="black", anchor="ma")
    img.save(FLOW / f"{name}.png", dpi=(180,180))

for item in instructions:
    datapath(*item)
    flowchart(*item)

def total_datapath():
    W, H = 2300, 1250
    img = Image.new("RGB", (W,H), "white")
    d = ImageDraw.Draw(img)
    d.text((W//2, 35), "CPU54 complete single-cycle datapath", font=title_font, fill="black", anchor="mm")
    box(d,(60,470,250,600),"PC")
    box(d,(350,420,610,650),"IMEM\nDistributed ROM")
    box(d,(720,420,1010,650),"Decode / Control\nopcode / funct")
    box(d,(720,820,1040,1010),"Register File\nrs / rt read\nrd / rt write")
    box(d,(1140,420,1450,650),"ALU / Comparator\nadd/sub/logic/shift\nbranch target")
    box(d,(1580,420,1850,650),"Data Memory\nlb/lh/lw/lbu/lhu\nsb/sh/sw")
    box(d,(1950,420,2220,650),"Writeback MUX\nALU / MEM / PC+4\nHI/LO / CP0")
    box(d,(1120,100,1450,230),"Next-PC MUX\nPC+4 / branch / jump\njr / eret / exception")
    box(d,(1270,820,1500,1010),"Multiplier\n64-bit -> HI/LO")
    box(d,(1580,820,1850,1010),"Divider\n32 iterations\n-> HI/LO")
    box(d,(1930,820,2220,1010),"HI / LO / CP0\nMF/MF, MT/MT\nMFC0/MTC0")
    arrow(d,[(250,535),(350,535)],"pc[12:2]",(300,505))
    arrow(d,[(610,535),(720,535)],"inst",(665,505))
    arrow(d,[(850,650),(850,820)],"rs/rt",(900,740))
    arrow(d,[(1040,900),(1080,900),(1080,680),(1140,680),(1140,585)],"A/B",(1100,700))
    arrow(d,[(1010,535),(1140,535)],"imm / control",(1075,505))
    arrow(d,[(1450,535),(1580,535)],"address / store",(1515,505))
    arrow(d,[(1850,535),(1950,535)],"load data",(1900,505))
    arrow(d,[(1850,600),(1900,600),(1900,720),(880,720),(880,820)],"HI/LO/CP0 data",(1530,745))
    arrow(d,[(2220,600),(2220,720),(880,720),(880,820)],"write enable",(2150,745))
    arrow(d,[(220,470),(220,170),(1120,170)],"PC",(300,140))
    arrow(d,[(610,170),(1120,170)],"PC + 4",(850,140))
    arrow(d,[(1450,170),(2140,170),(2140,420)],"next_pc",(1780,140))
    arrow(d,[(1450,650),(1450,820)],"multiply input",(1485,735))
    arrow(d,[(1010,590),(1070,590),(1070,1080),(1715,1080),(1715,1010)],"divide input",(1360,1100))
    d.text((70,1150),"Normal instructions complete in T0. DIV/DIVU: T0 start, T1-T32 iterate, T33 commit HI/LO and update PC.",font=small,fill="black")
    img.save(DP/"cpu54_total_datapath.png",dpi=(180,180))

total_datapath()
print(f"datapath={len(list(DP.glob('*.png')))} flow={len(list(FLOW.glob('*.png')))}")
