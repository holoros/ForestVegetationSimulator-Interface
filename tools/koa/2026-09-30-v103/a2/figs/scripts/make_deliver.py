#!/usr/bin/env python3
"""make_deliver.py (a2/figs): copy the twelve v103 figures (600 dpi TIFF, PNG embed) from out/ to deliver/, write the contact sheet and MD5SUMS.txt."""
import glob, os, shutil, hashlib
from PIL import Image, ImageDraw, ImageFont
Image.MAX_IMAGE_PIXELS = None
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
STEMS = ["Fig3_components", "Fig4_projections", "Fig5_longterm", "Fig6_scenarios", "FigS1_height_hcb_survival", "FigS2_increment_diagnostics",
         "FigS3_survival_recovery", "FigS4_survival_deployability", "FigS5_validation", "FigS6_natural", "FigS7_planted", "FigS8_bakuzis"]
os.makedirs("deliver", exist_ok=True)
for f in glob.glob("deliver/*"): os.remove(f)
for s in STEMS:
    for e in ("tiff", "png"): shutil.copy2(f"out/{s}.{e}", f"deliver/{s}.{e}")
cw, ch, cols = 700, 760, 4
sheet = Image.new("RGB", (cols * cw, 3 * ch), "white"); d = ImageDraw.Draw(sheet)
font = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", 26)
for i, s in enumerate(STEMS):
    im = Image.open(f"deliver/{s}.png").convert("RGB"); im.thumbnail((cw - 20, ch - 60)); x, y = (i % cols) * cw, (i // cols) * ch
    d.text((x + 12, y + 10), s, fill="black", font=font); sheet.paste(im, (x + 10 + (cw - 20 - im.size[0]) // 2, y + 50))
sheet.save("deliver/contact_sheet_v103.png")
with open("deliver/MD5SUMS.txt", "w") as fh:
    for f in sorted(os.listdir("deliver")):
        if f != "MD5SUMS.txt": fh.write(f"{hashlib.md5(open('deliver/' + f, 'rb').read()).hexdigest()}  {f}\n")
    for s in STEMS:
        im = Image.open(f"deliver/{s}.tiff"); assert tuple(round(v) for v in im.info["dpi"]) == (600, 600), s
print("deliver ok", len(os.listdir("deliver")), "files")
