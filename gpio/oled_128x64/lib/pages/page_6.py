import subprocess
import time

#################################################################################
#                                    PAGE 9 - screen off                        #
#                              ----------------------------                     #
#                                                                               #
#################################################################################
is_first_load = True

def page_setup(display):
    global is_first_load
    is_first_load = True
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(1)

def page(display, ok_button):
    global is_first_load

    x = 0
    y = 15
    # Write two lines of text.
    w, h = display.draw_text("OLED STANDBY?", x, y)
    y+=h + 2
    w, h = display.draw_text("Press OK", x+35, y)
    y+=h + 2

    if display.standby is False and not is_first_load:
        state = False
        display.draw_text("oled is ready...", x+35, y)
        display.standby_switch(mode=False)
    if ok_button and display.standby is False:
        state = True
        display.draw_text("going standby...", x+35, y)
        display.display_show()
        time.sleep(1)
        y+=h + 2
        display.standby_switch(mode=True)
        is_first_load = not is_first_load

    return False

def page_destructor(display):
    pass
