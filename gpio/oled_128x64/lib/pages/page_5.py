import subprocess
import time

#################################################################################
#                              PAGE 1 - performance monitor                     #
#                              ----------------------------                     #
#                                 * TEMP, * CPU freq                            #
#################################################################################

def page_setup(display):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(3)

def page(display):
    return False

def page_destructor(display):
    pass
