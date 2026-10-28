"""Draw the editor's original, small geometric UI glyphs. Requires Pillow.

Run from the repository root. All glyphs share one 32px canvas and are rendered
at 4x before downsampling. Runtime uses these TGA files as ordinary textures.
"""
from pathlib import Path
import math
from PIL import Image, ImageDraw

DEST = Path(__file__).resolve().parents[1] / 'Interface/AddOns/CherrysKit/RomWeakAuras/Media/Textures/UI'
DEST.mkdir(parents=True, exist_ok=True)
CYAN, GOLD, RED, GREEN = '#55dcf2', '#ffd35e', '#ff5f6d', '#4af5b4'

for name in ('buff','debuff','clock','cast','history','health','mana','resource','combat','target','class','rule','always','code','sound','text','move','image','colour','kitty'):
    im=Image.new('RGBA',(128,128)); d=ImageDraw.Draw(im)
    color=GOLD if name in ('sound','image','colour') else RED if name in ('health','debuff') else GREEN if name=='buff' else CYAN
    def line(points,fill=color,width=2): d.line([(int(x*4),int(y*4)) for x,y in points],fill=fill,width=width*4,joint='curve')
    def poly(points,fill=color): d.polygon([(int(x*4),int(y*4)) for x,y in points],fill=fill)
    def oval(box,fill=None,outline=color,width=2): d.ellipse(tuple(int(v*4) for v in box),fill=fill,outline=outline,width=width*4)
    if name=='buff': poly([(5,5),(16,2),(27,5),(25,19),(21,25),(16,30),(11,25),(7,19)])
    elif name=='debuff':
        oval((5,3,27,25),color); poly([(10,20),(22,20),(22,29),(10,29)])
        oval((9,10,14,16),'#06131f',None);oval((18,10,23,16),'#06131f',None);line([(14,24),(14,29)],'#06131f',1);line([(18,24),(18,29)],'#06131f',1)
    elif name in ('clock','history'):
        oval((3,3,29,29));line([(16,7),(16,16),(22,20)])
        if name=='history':poly([(1,4),(11,4),(1,14)],GOLD)
    elif name=='health':
        oval((3,4,17,18),color,None);oval((15,4,29,18),color,None);poly([(3,13),(29,13),(16,29)])
    elif name=='mana':poly([(16,2),(27,18),(27,24),(22,29),(10,29),(5,24),(5,18)]);line([(10,20),(11,24),(14,25)],'#c9faff',2)
    elif name in ('cast','resource'):poly([(18,1),(5,18),(14,18),(11,31),(28,12),(18,12)])
    elif name in ('target','move'):
        if name=='target':oval((6,6,26,26));oval((13,13,19,19),color,None)
        for a,b in [((16,1),(16,9)),((16,23),(16,31)),((1,16),(9,16)),((23,16),(31,16))]:line([a,b])
        if name=='move':
            line([(11,6),(16,1),(21,6)]);line([(11,26),(16,31),(21,26)]);line([(6,11),(1,16),(6,21)]);line([(26,11),(31,16),(26,21)])
    elif name=='class':
        oval((3,3,14,14),color,None);oval((19,3,30,14),color,None);poly([(2,29),(2,20),(5,16),(12,16),(16,20),(16,29)]);poly([(18,29),(18,20),(21,16),(28,16),(31,20),(31,29)])
    elif name=='rule':
        line([(16,9),(16,18),(5,18),(5,26)]);line([(16,18),(27,18),(27,26)])
        for x,y in ((12,2),(1,24),(12,24),(23,24)):poly([(x,y),(x+8,y),(x+8,y+6),(x,y+6)],'#b79bff')
    elif name=='always':oval((3,3,29,29));line([(8,16),(13,22),(24,10)],GREEN,3)
    elif name=='code':line([(10,6),(3,16),(10,26)],GOLD,3);line([(22,6),(29,16),(22,26)],GOLD,3);line([(19,3),(13,29)],GOLD,2)
    elif name=='sound':poly([(3,11),(10,11),(18,4),(18,28),(10,21),(3,21)]);line([(22,10),(25,16),(22,22)]);line([(26,5),(30,16),(26,27)])
    elif name=='text':line([(3,5),(21,5)],width=3);line([(12,5),(12,28)],width=3);line([(20,14),(30,14)]);line([(25,14),(25,28)])
    elif name=='image':
        line([(3,4),(29,4),(29,28),(3,28),(3,4)]);oval((7,8,13,14),color,None);poly([(5,25),(15,15),(20,20),(24,16),(28,25)])
    elif name=='colour':
        oval((2,3,30,29),color,None)
        for x,y,c in [(8,10,RED),(16,7,CYAN),(24,11,GREEN),(24,20,'#905bff')]:oval((x-3,y-3,x+3,y+3),c,None)
        oval((8,20,15,27),'#071520',None)
    elif name=='combat':line([(5,3),(27,28)],GOLD,3);line([(27,3),(5,28)],GOLD,3);line([(2,22),(10,29)],GOLD,3);line([(22,29),(30,22)],GOLD,3)
    elif name=='kitty':
        oval((8,13,25,30),'#b79bff',None)
        for x,y in [(4,11),(11,5),(22,5),(29,11)]:oval((x-3,y-4,x+3,y+4),'#b79bff',None)
    im.resize((32,32),Image.Resampling.LANCZOS).save(DEST/f'{name}.tga')
print('Wrote 20 shared UI glyphs (32 x 32 RGBA).')

# Shared white alpha masks keep the existing two-texture button skin. Width
# buckets preserve a small corner radius without allocating more native widgets.
for width,height in [(32,32),(64,32),(128,32),(256,32),(512,32),(1024,32),(256,96),(512,96)]:
    mask=Image.new('RGBA',(width*4,height*4))
    ImageDraw.Draw(mask).rounded_rectangle((0,0,width*4-1,height*4-1),radius=16,fill='white')
    mask.resize((width,height),Image.Resampling.LANCZOS).save(DEST/f'round-{width}-{height}.tga')
print('Wrote 8 shared button corner masks.')
