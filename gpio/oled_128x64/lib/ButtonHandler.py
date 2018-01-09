#!/usr/bin/python3
import LogHandler
mylogger = LogHandler.LogHandler("oled_button_handler")
try:
    import RPi.GPIO as GPIO
except RuntimeError:
    mylogger.logger.error("Error importing RPi.GPIO!  This is probably because you need superuser privileges.  You can achieve this by using 'sudo' to run your script")

import os
import time
import threading

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

        ####################
        self.threads = []
        self.last_event_cmd = None
        self.button_thrd_timing = 0.1
        self.virtual_button_file_watch_thrd_timing = 0.2

        self.button_threads_init()

    def button_threads_init(self):
        self.threads.append(threading.Thread(target=self.left_button_thrd))
        self.threads.append(threading.Thread(target=self.ok_button_thrd))
        self.threads.append(threading.Thread(target=self.right_button_thrd))
        self.threads.append(threading.Thread(target=self.virtual_button_file_watch_thrd))
        # write more threads here...
        for thd in self.threads:
            thd.daemon = True                                   # with this set, can stop therad
            thd.start()
            time.sleep(0.1)
        # sleep a little while manage_pages_thread read contents
        time.sleep(0.5)

    def left_button_thrd(self):
        while True:
            channel = self.channels_dict["LEFT"]
            if self.__button_event_get(channel, edge="up"):
                self.last_event_cmd = "LEFT"
            time.sleep(self.button_thrd_timing)

    def ok_button_thrd(self):
        while True:
            channel = self.channels_dict["OK"]
            if self.__button_event_get(channel, edge="up"):
                self.last_event_cmd = "OK"
            time.sleep(self.button_thrd_timing)

    def right_button_thrd(self):
        while True:
            channel = self.channels_dict["RIGHT"]
            if self.__button_event_get(channel, edge="up"):
                self.last_event_cmd = "RIGHT"
            time.sleep(self.button_thrd_timing)

    def virtual_button_file_watch_thrd(self):
        myfolder = os.path.dirname(os.path.abspath(__file__))
        virtual_button_file_pipe = os.path.join(myfolder, ".virtual_button_file")
        while True:
            if os.path.exists(virtual_button_file_pipe):
                with open(virtual_button_file_pipe, 'r') as f:
                    cmd = f.read().rstrip()
                if cmd == "RIGHT" or cmd == "LEFT" or cmd == "OK":
                    self.last_event_cmd = cmd
                    time.sleep(0.5)
                    open(virtual_button_file_pipe, 'w').close()
            time.sleep(self.virtual_button_file_watch_thrd_timing)

    def get_button_evenet(self, in_loop=True):
        while in_loop:
            if self.last_event_cmd is not None:
                print("Button was pressed: " + str(self.last_event_cmd))
                return_value = self.last_event_cmd
                self.last_event_cmd = None
                return return_value
            time.sleep(0.08)

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

    def __button_event_get(self, channel, edge="up"):
        is_pressed = False
        if edge == "down":
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
        if edge == "up":
            try:
                state = self.simple_input_read(channel)
                while not state:
                    state = self.simple_input_read(channel)
                    time.sleep(0.1)
                    if state:
                        is_pressed = True
                        mylogger.logger.info("Button was pressed")
                    if state is None:
                        break
                return is_pressed
            except KeyboardInterrupt:
                return False
                mylogger.logger.info("CTRL-C exit")

    def oled_read_all_function_buttons(self, in_loop=True):
        return self.get_button_evenet(in_loop=True)

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









