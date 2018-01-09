import subprocess
import time
import os
import sys
try:
    myfolder = os.path.dirname(os.path.abspath(__file__))
    widget_module_path = os.path.dirname(myfolder)
    sys.path.append(widget_module_path)
    import oled_gui_widgets
except Exception as e:
    print("!"*100)
    print(e)
    print("!"*100)

#################################################################################
#                                 PAGE 8 - WEATHER PAGE                         #
#                              ----------------------------                     #
#                               *weather *temp *wind *rain                      #
#################################################################################

def page_setup(display):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(10)

def page(display, ok_button):
    weather_dict = oled_gui_widgets.get_weather_info()

    x = 0
    y = 14
    # Write two lines of text.
    w, h = display.draw_text(str(weather_dict["weather"]), x, y)
    y+=h
    display.draw_text("temp:  " + str(weather_dict["temp"][0:3]) + " 'C", x, y)
    y+=h
    display.draw_text("wind:  " + str(weather_dict["wind"]), x, y)
    y+=h
    display.draw_text("rain:  " + str(weather_dict["rain"]), x, y)
    return False

def page_destructor(display):
    pass
