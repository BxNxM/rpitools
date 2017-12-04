rgb_service="[r]gb_led_controller.py"
rgb_demo="[r]gb_demo.py"
button_event_handler="[B]uttonHandler.py"
rgb_button_app="[s]tart_rgb_w_button_demo"

proc="$rgb_service"
echo -e "RGB CONTROLLER:\t\t$proc -> $(ps aux | grep "$proc")"

proc="$rgb_demo"
echo -e "RGB DATA GENERATOR:\t$proc -> $(ps aux | grep "$proc")"

proc="$button_event_handler"
echo -e "BUTTON HANDLER:\t\t$proc -> $(ps aux | grep "$proc")"

proc="$rgb_button_app"
echo -e "MAIN APP:\t\t$proc -> $(ps aux | grep "$proc")"
