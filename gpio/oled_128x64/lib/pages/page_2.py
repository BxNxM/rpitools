import subprocess
import random
import time

#################################################################################
#                                 PAGE 2 - screen saver                         #
#                              ----------------------------                     #
#                                    random squares                             #
#################################################################################

def page_setup(display):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(1)

def page(display):
    size = 4
    x = random.randint(0, 128-size)
    y = random.randint(9, 64-10-size)
    display.draw.rectangle((x, y, x+size, y+size), outline=255, fill=0)

    #display.virtual_button("right")
    return True

def page_destructor(display):
    pass
