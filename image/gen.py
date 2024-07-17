#%%
import PIL.Image as Image

im = Image.open("./test.jpg")
im = im.resize((640, 480))
im.save("./test_vga.jpg")