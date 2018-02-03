import subprocess
import time

#################################################################################
#                                PAGE 5 - empty page demo                       #
#                              ----------------------------                     #
#                                 * TEMP, * CPU freq                            #
#################################################################################

def page_setup(display):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(10)

def page(display, ok_button, joystick):
    return False

def page_destructor(display):
    pass
