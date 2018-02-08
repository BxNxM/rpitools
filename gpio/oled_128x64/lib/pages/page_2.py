import subprocess
import random
import time

#################################################################################
#                                 PAGE 2 - screen saver                         #
#                              ----------------------------                     #
#                                    random squares                             #
#################################################################################
set_counter = 50
counter = set_counter

def page_setup(display, joystick_elements):
    global counter
    counter = set_counter
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(0.5)

def page(display, joystick, joystick_elements):
    global counter
    counter-=1

    size = 8
    x = random.randint(0, 128-size)
    y = random.randint(10, 64-10-size)
    shape = random.randint(0, 3)

    # Write two lines of text.
    #w, h = display.draw_text("counter: " + str(counter), 0, 14)

    if shape == 0:
        # draw shape rectangle
        display.draw.rectangle((x, y, x+size, y+size), outline=255, fill=0)
    elif shape == 1:
        # draw shape ellipse
        display.draw.ellipse((x, y, x+size, y+size), outline=255, fill=0)
    elif shape == 2:
        # draw shape polygon - triangle
        display.draw.polygon([(x, y), (x, y+size), (x-size, y)], outline=255, fill=0)
    elif shape == 3:
        # draw lines shape X
        display.draw.line((x, y, x+size, y+size), fill=255)
        display.draw.line((x+size, y, x, y+size), fill=255)


    if counter <= 0:
        display.clever_screen_clean(force_clean=True)
        counter = set_counter

    return True

def page_destructor(display, joystick_elements):
    pass
