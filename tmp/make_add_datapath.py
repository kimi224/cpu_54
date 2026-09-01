from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

out_dir = Path(__file__).resolve().parents[1] / "datapath_diagrams"
out_dir.mkdir(exist_ok=True)
out = out_dir / "add_rtype_datapath.png"

W, H = 1800, 850
img = Image.new("RGB", (W, H), "white")
draw = ImageDraw.Draw(img)

font_path = "C:/Windows/Fonts/arial.ttf"
bold_path = "C:/Windows/Fonts/arialbd.ttf"
font = ImageFont.truetype(font_path, 25)
small = ImageFont.truetype(font_path, 21)
title_font = ImageFont.truetype(bold_path, 34)

def box(xy, label, fill="#F7F7F7", width=2):
    draw.rounded_rectangle(xy, radius=8, outline="black", fill=fill, width=width)
    x1, y1, x2, y2 = xy
    bb = draw.multiline_textbbox((0, 0), label, font=font, align="center", spacing=4)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    draw.multiline_text(((x1+x2-tw)/2, (y1+y2-th)/2), label, font=font, fill="black", align="center", spacing=4)

def arrow(points, label=None, label_xy=None):
    draw.line(points, fill="black", width=3, joint="curve")
    x1, y1 = points[-2]
    x2, y2 = points[-1]
    import math
    ang = math.atan2(y2-y1, x2-x1)
    size = 13
    p1 = (x2, y2)
    p2 = (x2-size*math.cos(ang-0.45), y2-size*math.sin(ang-0.45))
    p3 = (x2-size*math.cos(ang+0.45), y2-size*math.sin(ang+0.45))
    draw.polygon([p1,p2,p3], fill="black")
    if label:
        draw.text(label_xy or ((x1+x2)//2, (y1+y2)//2-28), label, font=small, fill="black", anchor="mm")

draw.text((W//2, 35), "ADD (R-type) single-cycle datapath", font=title_font, fill="black", anchor="mm")

box((70, 330, 245, 455), "PC", "#EEEEEE")
box((350, 270, 600, 515), "Instruction\nMemory", "#EEEEEE")
box((735, 270, 1035, 515), "Register File\nrs -> A\nrt -> B", "#EEEEEE")
box((1180, 300, 1430, 485), "ALU\nA + B", "#EEEEEE")
box((1530, 330, 1740, 455), "Writeback\nrd", "#EEEEEE")
box((380, 100, 610, 190), "PC + 4", "#FFFFFF")
box((850, 100, 1110, 190), "Next-PC MUX\n(select PC + 4)", "#FFFFFF")

arrow([(245,392),(350,392)], "pc[12:2]", (298,365))
arrow([(600,350),(735,350)], "rs, rt, rd", (668,323))
arrow([(1035,350),(1180,350)], "A", (1107,323))
arrow([(1035,435),(1180,435)], "B", (1107,466))
arrow([(1430,392),(1530,392)], "ALU result", (1480,365))
arrow([(1570,455),(1570,585),(880,585),(880,515)], "RegWrite = 1", (1200,615))
arrow([(155,330),(155,145),(380,145)], "PC", (210,115))
arrow([(610,145),(850,145)], "pc + 4", (730,115))
arrow([(1110,145),(1620,145),(1620,330)], "next_pc", (1330,115))
arrow([(600,440),(690,440),(690,700),(155,700),(155,455)], "instruction flow", (420,730))

draw.text((75, 770), "Control: RegWrite=1, MemWrite=0, ALUSrc=rt, Dest=rd, PCSel=PC+4", font=small, fill="black")
img.save(out, dpi=(180, 180))
print(out)
