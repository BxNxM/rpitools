import subprocess
import time
from PIL import Image
import random

#################################################################################
#                                  PAGE 7 - images view                         #
#                              ----------------------------                     #
#                                                                               #
#################################################################################
pics_index = 0
stored_index = -1

def page_setup(display):
    global pics_index, stored_index
    stored_index = -1
    pics_index = 0
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(1)

def page(display, ok_button):
    global pics_index, stored_index
    image_list = [ 'pages/images/rpi.png', 'pages/images/happycat_oled_64.ppm']
    if ok_button:
        pics_index += 1
        if pics_index >= len(image_list):
            pics_index = 0

    if stored_index != pics_index:
        stored_index = pics_index
        display.draw_image(image_list[pics_index])
    return True

def page_destructor(display):
    pass
