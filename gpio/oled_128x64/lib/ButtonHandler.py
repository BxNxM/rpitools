#!/usr/bin/python3
import LogHandler
mylogger = LogHandler.LogHandler("oled_button_handler")
try:
    import RPi.GPIO as GPIO
except RuntimeError:
    mylogger.logger.error("Error importing RPi.GPIO!  This is probably because you need superuser privileges.  You can achieve this by using 'sudo' to run your script")

import os
import time

class OledButtonHandler():

    def __init__(self, left_pin, right_pin, ok_pin):
        self.channels_dict = {"LEFT": left_pin,\
                              "RIGHT": right_pin,\
                               "OK": ok_pin}
        # set gpio channels
        #GPIO.setmode(GPIO.BOARD)
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(left_pin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
        GPIO.setup(right_pin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
        GPIO.setup(ok_pin, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

    def simple_input_read(self, channel):
        try:
            while True:
                state = GPIO.input(channel)
                #print("Button raw input: " + str(state) + " channel: " + str(channel))
                if state == 1:
                    return True
                else:
                    return False
        except KeyboardInterrupt:
            return None
            mylogger.logger.info("CTRL-C exit")

    def button_event_get(self, channel):
        is_pressed = False
        try:
            state = self.simple_input_read(channel)
            while state:
                state = self.simple_input_read(channel)
                time.sleep(0.08)
                if not state:
                    is_pressed = True
                    mylogger.logger.info("Button was pressed")
                if state is None:
                    break
            return is_pressed
        except KeyboardInterrupt:
            return False
            mylogger.logger.info("CTRL-C exit")

    def oled_read_all_function_buttons(self, in_loop=True):
        while in_loop:
            for cmd, pin in self.channels_dict.items():
                value = self.button_event_get(pin)
                if value:
                    print("Button was pressed: " + str(cmd))
                    return cmd
                time.sleep(0.08)

    def __del__(self):
        try:
            print('kill object: cleanup')
            GPIO.cleanup(self.channels_dict["LEFT"])
            GPIO.cleanup(self.channels_dict["RIGHT"])
            GPIO.cleanup(self.channels_dict["OK"])
        except Exception as e:
            print(e)

if "ButtonHandler" in __name__:
    oled_buttons = OledButtonHandler(left_pin=26, right_pin=5, ok_pin=6)

if __name__ == "__main__":
    #oled_buttons = OledButtonHandler(left_pin=37, right_pin=29, ok_pin=31)     #GPIO.BOARD)
    oled_buttons = OledButtonHandler(left_pin=26, right_pin=5, ok_pin=6)
    #oled_buttons.simple_input_read(37)                                         #GPIO.BOARD)
    oled_buttons.oled_read_all_function_buttons()










