import subprocess
import time

#################################################################################
#                            joystick_elements rgb widget                       #
#                              ----------------------------                     #
#                                 ON/OFF R,G,B VALUES                           #
#################################################################################
rgb_joystick_elements = None

def page_setup(display, joystick_elements):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(0)
    rgb_manage_function(joystick_elements, display, joystick=None, mode="init")
    cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -s ON"
    run_command(cmd_aliad, display)

def page(display, joystick, joystick_elements):
    uid, state, value = rgb_manage_function(joystick_elements, display, joystick, mode="run")

    if state is not None:
        if uid == "rgbbutton":
            button = "OFF"
            if state:
                button = "ON"
            cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -l {}".format(button)
            run_command(cmd_aliad, display)

        if uid == "red":
            cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -r {}".format(value)
            run_command(cmd_aliad, display)
        if uid == "green":
            cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -g {}".format(value)
            run_command(cmd_aliad, display)
        if uid == "blue":
            cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -b {}".format(value)
            run_command(cmd_aliad, display)
    return True

def page_destructor(display, joystick_elements):
    cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -s OFF -l OFF"
    run_command(cmd_aliad, display)
    rgb_manage_function(joystick_elements, display, joystick, mode="del")

#################################################################################
#execute command and wait for the execution + load indication
def run_command(cmd, display=None):
    x = 95
    y = 45
    if display is not None:
        w, h = display.draw_text("load", x, y)
    p = subprocess.Popen(cmd, shell=True)
    p.communicate()
    if display is not None:
        w, h = display.draw_text("    ", x, y)

#################################################################################
def rgb_manage_function(joystick_elements, display, joystick, mode=None):
    global rgb_joystick_elements

    # init section
    if mode == "init":
        default_value = 30

        # init value elemet for red color
        je_red = joystick_elements.JoystickElement_value_bar(display, x=5, step=10, valmax=100, valmin=0, title="R")
        je_red.set_value(delta=default_value)
        # set led state:
        cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -r {}".format(default_value)
        subprocess.Popen(cmd_aliad, shell=True)

        # init value elemet for green color
        je_green = joystick_elements.JoystickElement_value_bar(display, x=35, step=10, valmax=100, valmin=0, title="G")
        je_green.set_value(delta=30)
        # set led state:
        cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -g {}".format(default_value)
        subprocess.Popen(cmd_aliad, shell=True)

        # init value elemet for green color
        je_blue = joystick_elements.JoystickElement_value_bar(display, x=65, step=10, valmax=100, valmin=0, title="B")
        je_blue.set_value(delta=30)
        # set led state:
        cmd_aliad = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -b {}".format(default_value)
        subprocess.Popen(cmd_aliad, shell=True)

        # rgb on - off
        je_rgb_button = joystick_elements.JoystickElement_button(display, x=95, title="RGB")

        # init button handler - and element manager list with created elements
        rgb_joystick_elements = joystick_elements.JoystickElementManager(default_index=3)
        rgb_joystick_elements.add_element(je_red, "red")                        # object, uid (id to get value change)
        rgb_joystick_elements.add_element(je_green, "green")
        rgb_joystick_elements.add_element(je_blue, "blue")
        rgb_joystick_elements.add_element(je_rgb_button, "rgbbutton")
        time.sleep(1)

    # run change check on elemets list - return cahnge
    if mode == "run":
        change = rgb_joystick_elements.run_elements(joystick)
        if change[0] is not None:
            print("#"*100)
            print("uid: " + str(change[0]) + " state: " + str(change[1]) + " value: " + str(change[2]))
            print("#"*100)
        return change

    # delete created object!
    if mode == "del":
        del rgb_joystick_elements
