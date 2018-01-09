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
attention = True

def page_setup(display):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(90)

def page(display, ok_button):
    global attention

    weather_dict = oled_gui_widgets.get_weather_info()
    draw_weather_state(display, state=str(weather_dict["weather"]))
    #draw_weather_state(display, state="Light drizzle")

    x = 0
    y = 14
    if "None" in weather_dict.values() and attention:
        w, h = display.draw_text("WEATHER: curl wttr.in/location", x, y)
        y += h
        w, h = display.draw_text("Maximum call reached!", x, y)
        return False

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

def draw_weather_state(display, state):
    x =100
    y = 25
    size = 20

    if state.lower() == "sunny":
        image_path = 'pages/images/sunny.png'
        display.draw_image(image_path)
    if "cloudy" in state.lower() or state.lower() == "overcast":
        image_path = 'pages/images/cloudy.png'
        display.draw_image(image_path)
    if "rain" in state.lower() or "drizzle" in state.lower():
        image_path = 'pages/images/rain.png'
        display.draw_image(image_path)
    if "partly cloudy" in state.lower():
        image_path = 'pages/images/partly_cloudy.png'
        display.draw_image(image_path)