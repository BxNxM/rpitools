import subprocess
import time
import joystick_elements

#################################################################################
#                                PAGE 5 - empty page demo                       #
#                              ----------------------------                     #
#                                 * TEMP, * CPU freq                            #
#################################################################################

def page_setup(display):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(0)

    #joystick_elements.test_JoystickElementManager(display, joystick, mode="init")
    #joystick_elements.test_JoystickElementManager2(display, joystick, mode="init")
    joystick_elements.test_JoystickElementManager3(display, joystick=None, mode="init")

def page(display, ok_button, joystick):
    #joystick_elements.test_JoystickElement_button(display)
    #joystick_elements.test_JoystickElementManager(display, joystick, mode="run")
    #joystick_elements.test_JoystickElementManager2(display, joystick, mode="run")
    joystick_elements.test_JoystickElementManager3(display, joystick, mode="run")
    return False

def page_destructor(display):
    joystick_elements.test_JoystickElementManager3(display, joystick=None, mode="del")
