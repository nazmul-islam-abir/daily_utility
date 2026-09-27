"""Resize every screenshot in app_images/ to a mobile-friendly size and
write the smaller copies into app_images/sm/. Originals are kept.

The originals are 1080x2400 (portrait). For GitHub README we want each
image to fit comfortably inside a ~360-400px wide column on mobile, but
still look crisp on desktop. Width 540 (1/2 of original) hits that sweet
spot — same aspect ratio, ~75% smaller file.
"""
import os
from pathlib import Path
from PIL import Image

SRC = Path(r"app_images")
DST = Path(r"app_images/sm")
DST.mkdir(parents=True, exist_ok=True)

MAX_W = 540            # target width for the resized copies
JPEG_Q = 78            # quality when converting RGBA -> JPEG

count_in = 0
count_out = 0
saved_bytes = 0

for src in sorted(SRC.glob("Screenshot_*.png")):
    count_in += 1
    dst = DST / src.name
    with Image.open(src) as im:
        # Convert palette/RGBA -> RGB so we can save as JPEG for size.
        if im.mode not in ("RGB", "L"):
            im = im.convert("RGB")
        w, h = im.size
        if w > MAX_W:
            new_h = round(h * MAX_W / w)
            im = im.resize((MAX_W, new_h), Image.LANCZOS)
        # Keep PNG so the file extension matches README refs.
        im.save(dst, "PNG", optimize=True)
        count_out += 1
        saved_bytes += src.stat().st_size - dst.stat().st_size

print(f"Processed: {count_in}  Wrote: {count_out}")
print(f"Originals total: {sum(p.stat().st_size for p in SRC.glob('Screenshot_*.png'))/1024/1024:.1f} MB")
print(f"Resized  total: {sum(p.stat().st_size for p in DST.glob('Screenshot_*.png'))/1024/1024:.1f} MB")
