#%%
from test_vga import *

string_byte_arr = []

for byte_val in test_vga_640_480:
  print('{:06X}'.format(byte_val))
  string_byte_arr.append('{:06X}'.format(byte_val))

with open("./input.coe.tmp", "r") as file:
  template = file.read()
  template = template.replace("%%{vector}%%", "\n".join(string_byte_arr))

with open("./vga_fb_init.coe", "w") as file:
  file.write(template)