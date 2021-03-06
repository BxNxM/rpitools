import subprocess
import time

#################################################################################
#                                    PAGE 9 - joystick                          #
#                              ----------------------------                     #
#                                                                               #
#################################################################################

def page_setup(display, joystick_elements):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(1)

def page(display, joystick, joystick_elements):
    center = "cyrcle"
    draw_shapes(display, center)
    draw_event(display, center, joystick)
    return True

def page_destructor(display, joystick_elements):
    pass


def draw_shapes(display, center):
    display.draw.polygon([(22, 21), (30, 9), (38, 21)], outline=255, fill=0)            # up
    display.draw.polygon([(5, 30), (18, 23), (18, 38)], outline=255, fill=0)            # left
    display.draw.polygon([(55, 30), (42, 23), (42, 38)], outline=255, fill=0)           # right
    display.draw.polygon([(30, 55), (38, 42), (22, 42)], outline=255, fill=0)           # down
    if center == "cyrcle":
        display.draw.ellipse((22, 24 , 38, 38), outline=255, fill=0)                    # center
    if center == "rectangle":
        display.draw.rectangle((22, 24,38,38), outline=255, fill=0)                     # center

def draw_event(display, center, joystick):
    x = 70
    y = 28

    # Write two lines of text.
    if joystick is not None:
        w, h = display.draw_text(str(joystick), x, y)
    else:
        w, h = display.draw_text("         ", x, y)

    if str(joystick) == "UP":
        display.draw.polygon([(22, 21), (30, 9), (38, 21)], outline=255, fill=1)        # up - filled

    if str(joystick) == "LEFT":
        display.draw.polygon([(5, 30), (18, 23), (18, 38)], outline=255, fill=1)        # left - filled

    if str(joystick) == "RIGHT":
        display.draw.polygon([(55, 30), (42, 23), (42, 38)], outline=255, fill=1)       # right - filled

    if str(joystick) == "DOWN":
        display.draw.polygon([(30, 55), (38, 42), (22, 42)], outline=255, fill=1)       # down

    if center == "cyrcle":
        if str(joystick) == "CENTER":
            display.draw.ellipse((22, 24 , 38, 38), outline=255, fill=1)                # center - filled
    if center == "rectangle":
        if str(joystick) == "CENTER":
            display.draw.rectangle((22, 24,38,38), outline=255, fill=1)                 # center - filled
