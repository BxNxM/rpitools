import subprocess
import random

#################################################################################
#                                 PAGE 4 - rgb led demo                         #
#                              ----------------------------                     #
#                                                                               #
#################################################################################

def page_setup(display):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(10)

def page(display, ok_button):
    x = 0
    y =14

    r_value = random.randint(0, 100)
    g_value = random.randint(0, 100)
    b_value = random.randint(0, 100)

    cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -s ON -l ON -r {} -g {} -b {}".format(r_value, g_value, b_value)
    #cmd_aliad = "rgbinterface  -r {} -g {} -b {}".format(r_value, g_value, b_value)
    subprocess.call(cmd_aliad, shell=True)

    w, h = display.draw_text("LED:", x, y)
    y += h
    w, h = display.draw_text("    r: " + str(r_value) + " ", x, y)
    y += h
    w, h = display.draw_text("    g: " + str(g_value) + " ", x, y)
    y += h
    w, h = display.draw_text("    b: " + str(b_value) + " ", x, y)

    return False

def page_destructor(display):
    cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -s OFF -l OFF"
    subprocess.call(cmd_aliad, shell=True)
