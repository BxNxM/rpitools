import subprocess
import time
from PIL import Image

#################################################################################
#                              PAGE 1 - performance monitor                     #
#                              ----------------------------                     #
#                                 * TEMP, * CPU freq                            #
#################################################################################

def page_setup(display):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(20)

def page(display, ok_button):
    image = Image.open('pages/happycat_oled_64.ppm').convert('1')
    display.draw_image(image)
    return True

def page_destructor(display):
    pass
