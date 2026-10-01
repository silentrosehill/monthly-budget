# Generates the Classic look's cork and paper textures (SVG noise as CSS data URIs) into cork.css.txt
from urllib.parse import quote
def svg(freq, octaves, matrix, size, seed):
    s = (f"<svg xmlns='http://www.w3.org/2000/svg' width='{size}' height='{size}'>"
         f"<filter id='n'><feTurbulence type='fractalNoise' baseFrequency='{freq}' numOctaves='{octaves}' seed='{seed}' stitchTiles='stitch'/>"
         f"<feColorMatrix values='{matrix}'/></filter><rect width='100%' height='100%' filter='url(#n)'/></svg>")
    return 'url("data:image/svg+xml,' + quote(s, safe="/:=' ") + '")'
dark   = svg(0.8, 2, "0 0 0 0 0.22  0 0 0 0 0.12  0 0 0 0 0.05  4.6 0 0 0 -2.6", 220, 3)     # dark cork granules
light  = svg(0.65, 2, "0 0 0 0 0.96  0 0 0 0 0.82  0 0 0 0 0.6  0 4.8 0 0 -2.95", 240, 9)    # light cork granules
mottle = svg(0.03, 3, "0 0 0 0 0.35  0 0 0 0 0.19  0 0 0 0 0.07  2.2 0 0 0 -0.95", 520, 2)   # soft colour variation
paper  = svg(0.6, 2, "0 0 0 0 0.45  0 0 0 0 0.38  0 0 0 0 0.25  0 0 0 0.9 -0.38", 200, 5)    # paper grain
open("cork.css.txt", "w").write("\n".join([dark, light, mottle, paper]))
