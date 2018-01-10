import subprocess
import time

#################################################################################
#                                    PAGE 9 - screen off                        #
#                              ----------------------------                     #
#                                                                               #
#################################################################################
state = False

def page_setup(display):
    global state
    state = False
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(1)

def page(display, ok_button):
    global state
    x = 0
    y = 15
    # Write two lines of text.
    w, h = display.draw_text("OLED STANDBY?", x, y)
    y+=h + 2
    w, h = display.draw_text("Press OK", x+35, y)
    y+=h + 2

    if ok_button and state is False:
        state = True
        display.standby_switch(mode=True)
    elif ok_button and state is True:
        state = False
        display.standby_switch(mode=False)

    return False

def page_destructor(display):
    pass
