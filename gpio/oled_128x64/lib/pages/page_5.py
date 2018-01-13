import subprocess
import time
import os
import sys
import time
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
images_path = "pages/images/weather_images/"
attention = True
page_icon_name = None

def page_setup(display):
    global page_icon_name
    page_icon_name = None
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(90)

def page(display, ok_button):
    global attention

    # image demo
    #test_images(display)

    try:
        weather_dict = oled_gui_widgets.get_weather_info()
    except Exception as e:
        raise Exception(str(e))
    draw_weather_state(display, state=str(weather_dict["weather"]))

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
    display.draw_text("temp: " + str(weather_dict["temp"][0:3]) + " 'C", x, y)
    y+=h
    display.draw_text("wind: " + str(weather_dict["wind"]), x, y)
    y+=h
    display.draw_text("rain: " + str(weather_dict["rain"]), x, y)
    return False

def page_destructor(display):
    pass

def draw_weather_state(display, state):
    global page_icon_name
    if page_icon_name != state:
        page_icon_name = state

        x =100
        y = 25
        size = 20

        if state.lower() == "sunny" or state.lower() == "clear":
            image_path = os.path.join(images_path, "sunny.png")
            display.draw_image(image_path)
        if "cloudy" in state.lower() or state.lower() == "overcast":
            image_path = os.path.join(images_path, "cloudy.png")
            display.draw_image(image_path)
        if "rain" in state.lower() or "drizzle" in state.lower():
            image_path = os.path.join(images_path, "rain.png")
            display.draw_image(image_path)
        if "partly cloudy" in state.lower():
            image_path = os.path.join(images_path, "partly_cloudy.png")
            display.draw_image(image_path)
        if "mist" in state.lower():
            image_path = os.path.join(images_path, "mist.png")
            display.draw_image(image_path)
        if "snow" in state.lower():
            image_path = os.path.join(images_path, "snow.png")
            display.draw_image(image_path)
        if "snow" in state.lower() and "rain" in state.lower():
            image_path = os.path.join(images_path, "snow-rain.png")
            display.draw_image(image_path)
        if "storm" in state.lower():
            image_path = os.path.join(images_path, "storm.png")
            display.draw_image(image_path)


def test_images(display):
    draw_weather_state(display, state="sunny")
    display.display_show()
    time.sleep(2)
    draw_weather_state(display, state="cloudy")
    display.display_show()
    time.sleep(2)
    draw_weather_state(display, state="rain")
    display.display_show()
    time.sleep(2)
    draw_weather_state(display, state="partly cloudy")
    display.display_show()
    time.sleep(2)
    draw_weather_state(display, state="mist")
    display.display_show()
    time.sleep(2)
    draw_weather_state(display, state="snow")
    display.display_show()
    time.sleep(2)
    draw_weather_state(display, state="snow rain")
    display.display_show()
    time.sleep(2)
    draw_weather_state(display, state="storm")
    display.display_show()
    time.sleep(2)
