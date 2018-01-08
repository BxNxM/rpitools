import subprocess
import time

#################################################################################
#                            PAGE 6 - software shutdown button                  #
#                              ----------------------------                     #
#                                                                               #
#################################################################################

def page_setup(display):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(1)

def page(display, ok_button):
    x = 0
    y = 15
    # Write two lines of text.
    w, h = display.draw_text("SHUTDOWN PI?", x, y)
    y+=h + 2
    w, h = display.draw_text("Press OK", x+35, y)
    y+=h + 2
    if ok_button:
        w, h = display.draw_text("shutting down...", x+35, y)
        display.display_show()
        cmd = "sudo shutdown now"
        output = subprocess.check_output(cmd, shell = True)
        y+=h
        w, h = display.draw_text(str(output), x+35, y)

    return False

def page_destructor(display):
    pass
