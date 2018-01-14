import subprocess
import time

#################################################################################
#                            PAGE 8 - system restart button                  #
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
    w, h = display.draw_text("RESTART PI?", x, y)
    y+=h + 2
    w, h = display.draw_text("Press OK", x+35, y)
    y+=h + 2
    if ok_button:
        w, h = display.draw_text("restarting down...", x+35, y)
        display.display_show()
        y+=h

        # clean display
        display.head_page_bar_switch(False, False)
        time.sleep(1)
        display.draw.rectangle((0,0,display.disp.width, display.disp.height), outline=0, fill=0)
        display.disp.clear()
        display.display_show()
        time.sleep(1.5)

        cmd = "sudo reboot -f"
        output = subprocess.check_output(cmd, shell = True)
        w, h = display.draw_text(str(output), x+35, y)
        display.display_show()
    return False

def page_destructor(display):
    pass
