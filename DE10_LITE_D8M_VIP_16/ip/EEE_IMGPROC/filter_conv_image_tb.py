#!/usr/bin/env python3

import sys
import subprocess
import numpy as np
from PIL import Image

tb = "./filter_conv_image_tb.v"
image = "./image.jpg"
iverilog = "iverilog"

# -- open image ---------------------------------------------------------------
im = np.array(Image.open(image).resize((640, 480)))

# -- write image in binary format ---------------------------------------------
with open("image.bin", "w") as file:
    for r in im:
        for p in r:
            for c in p:
                file.write(format(c, '08b'))
            file.write(' ')
        file.write('\n')

# -- compile and run iverilog simulation --------------------------------------
command = subprocess.run(['iverilog', '-o', 'filter_conv_image_tb', 'filter_conv_image_tb.v'], capture_output=True)
sys.stdout.buffer.write(command.stdout)
sys.stderr.buffer.write(command.stderr)

command = subprocess.run(['./filter_conv_image_tb'], capture_output=True)
sys.stdout.buffer.write(command.stdout)
sys.stderr.buffer.write(command.stderr)

# -- recover processed result -------------------------------------------------
result_im = []
cnt = 0
with open("image.out", "r") as file:
    pixels = file.read().split(';')
    print(len(pixels))
    for pixel in pixels:
        if cnt >= 480*640:
            print("done")
            break
        r, g, b = pixel.split(',')
        r = np.uint8(int(r))
        g = np.uint8(int(g))
        b = np.uint8(int(b))
        result_im.append([r,g,b])
        cnt += 1

result_im = np.asarray(result_im)
result_im = result_im.reshape(480, 640, 3)
Image.fromarray(result_im).save("image_result.jpg")
