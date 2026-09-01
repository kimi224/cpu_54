from pathlib import Path
from math import atan2, cos, sin
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "datapath_diagrams" / "cpu54_total_datapath.png"
W, H = 3300, 1700
img = Image.new("RGB", (W, H), "white")
d = ImageDraw.Draw(img)

FONT = "C:/Windows/Fonts/calibri.ttf"
BOLD = "C:/Windows/Fonts/calibrib.ttf"
f_title = ImageFont.truetype(BOLD, 42)
f_block = ImageFont.truetype(FONT, 25)
f_block_bold = ImageFont.truetype(BOLD, 25)
f_label = ImageFont.truetype(FONT, 20)
f_small = ImageFont.truetype(FONT, 18)

def centered(rect, text, font=f_block):
    x1, y1, x2, y2 = rect
    bb = d.multiline_textbbox((0, 0), text, font=font, align="center", spacing=4)
    d.multiline_text(((x1+x2-(bb[2]-bb[0]))/2, (y1+y2-(bb[3]-bb[1]))/2), text,
                     font=font, fill="black", align="center", spacing=4)

def block(rect, text, fill="#F1F1F1", font=f_block):
    d.rounded_rectangle(rect, radius=8, outline="black", fill=fill, width=3)
    centered(rect, text, font)

def label(x, y, text, anchor="mm", font=f_label):
    bb = d.textbbox((x, y), text, font=font, anchor=anchor)
    d.rectangle((bb[0]-5, bb[1]-3, bb[2]+5, bb[3]+3), fill="white")
    d.text((x, y), text, font=font, fill="black", anchor=anchor)

def arrow(points, text=None, text_at=None, color="black", width=3):
    d.line(points, fill=color, width=width, joint="curve")
    x1, y1 = points[-2]
    x2, y2 = points[-1]
    a = atan2(y2-y1, x2-x1)
    s = 14
    p2 = (x2-s*cos(a-0.48), y2-s*sin(a-0.48))
    p3 = (x2-s*cos(a+0.48), y2-s*sin(a+0.48))
    d.polygon([(x2,y2),p2,p3], fill=color)
    if text:
        label(*(text_at or ((x1+x2)//2, (y1+y2)//2-24)), text)

d.text((W//2, 38), "CPU54 complete data path and control-related paths", font=f_title, fill="black", anchor="mm")

# Main datapath blocks.
block((90, 660, 310, 800), "PC\n32-bit register")
block((420, 500, 720, 950), "IMEM\nDistributed Memory\nGenerator ROM\naddr = PC[12:2]\ninst[31:0]", "#EDEDED")
block((850, 500, 1150, 950), "Instruction fields\nopcode / funct\nrs / rt / rd\nshamt / imm16 / imm26", "#EDEDED")
block((1270, 500, 1660, 950), "Register File\n32 x 32-bit\nread rs -> A\nread rt -> B\nwrite rd/rt/r31", "#EDEDED")
block((1780, 500, 2150, 950), "ALU / Comparator\nADD / SUB\nAND / OR / XOR / NOR\nSLT / SLTU\nSLL / SRL / SRA / CLZ", "#EDEDED")
block((2260, 500, 2580, 950), "Data Memory\naddress = A + offset\nLB/LBU, LH/LHU, LW\nSB, SH, SW", "#EDEDED")
block((2700, 500, 3150, 950), "Writeback MUX\nALU result\nload data\nPC + 4\nHI / LO / CP0", "#EDEDED")

# PC generation lane.
block((390, 130, 650, 285), "PC + 4", "#FFFFFF")
block((790, 130, 1080, 285), "Sign-ext imm\n<< 2", "#FFFFFF")
block((1180, 130, 1480, 285), "Branch adder\nPC + 4 + offset", "#FFFFFF")
block((1590, 130, 2030, 285), "Next-PC MUX\nPC+4 / branch / jump\njr / jalr / eret / exception", "#FFFFFF")
block((470, 1040, 760, 1190), "Jump target\n{PC+4[31:28], imm26, 2'b0}", "#FFFFFF")

# Immediate and operand preparation.
block((850, 1040, 1120, 1190), "Sign extender\nimm16 -> 32", "#FFFFFF")
block((1190, 1040, 1460, 1190), "Zero extender\nimm16 -> 32", "#FFFFFF")
block((1510, 1040, 1780, 1190), "Operand MUX\nB or extended imm", "#FFFFFF")

# HI/LO, multiply, divide and CP0.
block((1270, 1320, 1580, 1540), "Multiplier\nMULT / MULTU\n64-bit product", "#F7F7F7")
block((1700, 1320, 2030, 1540), "Iterative Divider\nDIV / DIVU\n32 iterations\ndiv_busy / div_count", "#F7F7F7")
block((2160, 1320, 2500, 1540), "HI / LO registers\nHI <- remainder/product\nLO <- quotient/product\nMFHI/MFLO, MTHI/MTLO", "#F7F7F7")
block((2630, 1320, 3100, 1540), "CP0 registers\nStatus / Cause / EPC / Reg8\nMFC0 / MTC0\nSYSCALL / BREAK / TEQ / ERET", "#F7F7F7")

# Main horizontal data flow.
arrow([(310,730),(420,730)], "PC[12:2]", (365,700))
arrow([(720,620),(850,620)], "inst[31:0]", (785,590))
arrow([(1150,700),(1270,700)], "rs/rt/rd", (1210,670))
arrow([(1660,650),(1780,650)], "A", (1720,620))
arrow([(1660,820),(1730,820),(1730,760),(1780,760)], "B / operand", (1700,845))
arrow([(2150,680),(2260,680)], "address", (2205,650))
arrow([(1660,875),(2200,875),(2200,820),(2260,820)], "store data", (1940,900))
arrow([(2580,700),(2700,700)], "load data", (2640,670))
arrow([(2920,500),(2920,390),(1660,390),(1660,285)], "next_pc", (2300,365))
arrow([(2920,950),(2920,1010),(1460,1010),(1460,950)], "RegWrite / write data", (2200,1040))

# PC lane.
arrow([(200,660),(200,208),(390,208)], "PC", (255,180))
arrow([(650,208),(1590,208)], "pc_plus4 / branch target", (1110,175))
arrow([(1480,208),(1590,208)], "branch target", (1530,245))
arrow([(2030,208),(2030,390),(1660,390)], "selected next_pc", (2065,350))
arrow([(760,1115),(1320,1115),(1320,285)], "jump target", (1040,1080))
arrow([(1660,600),(1540,600),(1540,370),(1590,370)], "jr / jalr target", (1500,450))
arrow([(2500,1400),(2500,390),(1590,390)], "eret: EPC + 4", (2540,800))
arrow([(2630,1400),(2580,1400),(2580,390),(1590,390)], "exception -> EXC_ENTRY", (2700,1200))

# Field/control and extension paths.
arrow([(1000,950),(1000,1040)], "imm16", (1035,995))
arrow([(1060,950),(1060,1000),(1325,1000),(1325,1040)], "imm16", (1190,975))
arrow([(1645,1040),(1645,990),(1740,990),(1740,820),(1660,820)], "selected operand", (1740,965))
arrow([(1080,950),(1080,1010),(980,1010),(980,1040)], "branch imm", (1030,985))
arrow([(1030,500),(1030,285),(790,285)], "imm16", (900,315))
arrow([(1100,500),(1100,390),(615,390),(615,1040)], "imm26", (900,415))
arrow([(1150,790),(1150,1280),(1270,1280),(1270,1400)], "rs / rt", (1200,1260))
arrow([(1150,840),(1150,1240),(1700,1240),(1700,1400)], "rs / rt", (1450,1220))

# HI/LO and CP0 connections.
arrow([(1450,950),(1450,1100),(1425,1100),(1425,1320)], "MULT", (1450,1190))
arrow([(1510,950),(1510,1220),(1860,1220),(1860,1320)], "DIV start", (1690,1250))
arrow([(1580,1430),(2160,1430)], "product", (1870,1400))
arrow([(2030,1430),(2160,1430)], "quotient / remainder", (2100,1470))
arrow([(2500,1450),(2700,1450)], "CP0 read/write", (2600,1415))
arrow([(2630,1360),(2460,1360),(2460,1050),(2920,1050),(2920,950)], "CP0 data", (2700,1080))
arrow([(2160,1360),(2050,1360),(2050,950),(2920,950)], "HI/LO read", (2100,1050))
arrow([(2160,1490),(2050,1490),(2050,950)], "HI/LO write", (1980,1540))

# Control annotations.
block((60, 1040, 400, 1230), "Control signals\nfrom opcode/funct:\nRegWrite / MemWrite\nLoad/Store size\nALUSrc / ALUOp / RegDst\nPC select / HI-LO / CP0\ndiv_busy", "#FAFAFA", f_small)
label(1680, 480, "ordinary instructions: one clock cycle", font=f_small)
label(1850, 1600, "DIV/DIVU: T0 start -> T1-T32 iterate -> T33 commit HI/LO and update PC", font=f_small)

# Light frame and legend.
d.rectangle((35, 75, W-35, H-45), outline="#777777", width=2)
d.text((W-100, H-22), "CPU54 datapath overview", font=f_small, fill="#444444", anchor="rs")
img.save(OUT, dpi=(180,180))
print(OUT)
