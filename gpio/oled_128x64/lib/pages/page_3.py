import subprocess
import random

#################################################################################
#                                 PAGE 4 - rgb led demo                         #
#                              ----------------------------                     #
#                                                                               #
#################################################################################

def page_setup(display, joystick_elements):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(0.3)

def page(display, ok_button, joystick, joystick_elements):
    x = 0
    y =14

    w, h = display.draw_text("LED:", x, y)
    display.draw.rectangle((70,  30, 127, 50), outline=255, fill=0)
    display.draw_text("Press OK", x+76, y*3 - 8)
    y += h

    if ok_button:
        min_value = 30
        display.draw.rectangle((70,  30, 127, 50), outline=0, fill=0)
        r_value = random.randint(min_value, 100)
        g_value = random.randint(min_value, 100)
        b_value = random.randint(min_value, 100)

        w, h = display.draw_text("    r: " + str(r_value) + " ", x, y)
        y += h
        w, h = display.draw_text("    g: " + str(g_value) + " ", x, y)
        y += h
        w, h = display.draw_text("    b: " + str(b_value) + " ", x, y)

        cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -s ON -l ON -r {} -g {} -b {}".format(r_value, g_value, b_value)
        subprocess.Popen(cmd_aliad, shell=True)

    return False

def page_destructor(display, joystick_elements):
    cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -s OFF -l OFF"
    subprocess.Popen(cmd_aliad, shell=True)
