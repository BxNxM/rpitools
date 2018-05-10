import subprocess
import time
import os
import sys

# import memory dict client
sys.path.append("/home/pi/rpitools/tools/socketmem/lib/")
import clientMemDict
socketdictclient = clientMemDict.SocketDictClient()

#################################################################################
#                            joystick_elements rgb widget                       #
#                              ----------------------------                     #
#                                 ON/OFF R,G,B VALUES                           #
#################################################################################
rgb_joystick_elements = None

def page_setup(display, joystick_elements):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(0.1)
    rgb_manage_function(joystick_elements, display, joystick=None, mode="init")

    cmd_alias = "ps aux | grep -v grep | grep rgb_led_controller.py"
    stdout, stderr = run_command(cmd_alias, display)
    if str(stdout) == "":
        cmd_alias = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -s ON"
        run_command(cmd_alias, display, wait_for_done=False, wait=2)

def page(display, joystick, joystick_elements):
    uid, state, value = rgb_manage_function(joystick_elements, display, joystick, mode="run")

    if state is not None:
        if uid == "rgbbutton":
            button = "OFF"
            if state:
                button = "ON"
            socketdictclient.run_command("-md -n rgb -k LED -v " + str(button))

        if uid == "red":
            socketdictclient.run_command("-md -n rgb -k RED -v " + str(value))
        if uid == "green":
            socketdictclient.run_command("-md -n rgb -k GREEN -v " + str(value))
        if uid == "blue":
            socketdictclient.run_command("-md -n rgb -k BLUE -v " + str(value))
    return True

def page_destructor(display, joystick_elements):
    pass
    #cmd_alias = "/home/$USER/rpitools/gpio/rgb_led/bin/rgb_interface.py -s OFF -l OFF"
    #run_command(cmd_alias, display, wait_for_done=False)
    #rgb_manage_function(joystick_elements, display, joystick, mode="del")

#################################################################################
#execute command and wait for the execution + load indication
def run_command(cmd, display=None, wait_for_done=True, wait=0):
    x = 95
    y = 45
    stdout = stderr = ""
    if display is not None:
        w, h = display.draw_text("load", x, y)
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if wait_for_done:
        stdout, stderr = p.communicate()
    if display is not None:
        w, h = display.draw_text("    ", x, y)
    time.sleep(wait)
    return stdout, stderr

#################################################################################
def rgb_manage_function(joystick_elements, display, joystick, mode=None):
    global rgb_joystick_elements, socketdictclient

    # init section
    if mode == "init":
        rgb_appdict_str = socketdictclient.run_command("-md -n rgb -s True")
        rgb_appdict_dict = socketdictclient.string_to_dict(rgb_appdict_str)
        value_R = int(rgb_appdict_dict["RED"])
        value_G = int(rgb_appdict_dict["GREEN"])
        value_B = int(rgb_appdict_dict["BLUE"])
        value_button = rgb_appdict_dict["LED"]

        # init value elemet for red color
        je_red = joystick_elements.JoystickElement_value_bar(display, x=5, step=10, valmax=100, valmin=0, title="R")
        je_red.set_value(direct=value_R)

        # init value elemet for green color
        je_green = joystick_elements.JoystickElement_value_bar(display, x=35, step=10, valmax=100, valmin=0, title="G")
        je_green.set_value(direct=value_G)

        # init value elemet for green color
        je_blue = joystick_elements.JoystickElement_value_bar(display, x=65, step=10, valmax=100, valmin=0, title="B")
        je_blue.set_value(delta=value_B)

        # rgb on - off
        init_state_ = False
        if value_button == "ON":
            init_state_ = True
        je_rgb_button = joystick_elements.JoystickElement_button(display, x=95, title="RGB", init_state=init_state_)

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
