import subprocess
import time

#################################################################################
#                                    PAGE 9 - screen off                        #
#                              ----------------------------                     #
#                                                                               #
#################################################################################
oled_state = True


def page_setup(display):
    global oled_state
    oled_state = True
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(1)

def page(display, ok_button):
    global oled_state
    x = 0
    y = 15
    # Write two lines of text.
    w, h = display.draw_text("GETS OLED TO STANDBY?", x, y)
    y+=h + 2
    w, h = display.draw_text("Press OK", x+35, y)
    y+=h + 2
    if ok_button and oled_state:
        oled_state = False
        w, h = display.draw_text("going standby", x+35, y)
        display.display_show()
        y+=h

        # clean display
        display.head_page_bar_switch(False, False)
        time.sleep(2)
        display.draw.rectangle((0,0,display.disp.width, display.disp.height), outline=0, fill=0)
        display.disp.clear()
        display.display_show()
        time.sleep(1.5)

    elif ok_button and not oled_state:
        oled_state = True
        display.head_page_bar_switch(True, True)
        w, h = display.draw_text("oled is ready", x+35, y)
        display.display_show()

    return False

def page_destructor(display):
    pass
