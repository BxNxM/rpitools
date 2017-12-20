import subprocess
import random
import time

#########################################################################
#                                                                       #
#               Simple screen saver - random objects                    #
#                                                                       #
#########################################################################

def page(display):
    display.head_page_bar_switch(True, True)

    size = 10
    x = random.randint(0, 128-size)
    y = random.randint(8, 64-4-size)
    display.draw.rectangle((x, y, x+size, y+size), outline=255, fill=0)

    time.sleep(1)
    #display.virtual_button("right")
    return True
