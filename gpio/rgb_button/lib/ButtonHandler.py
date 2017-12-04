#!/usr/bin/python3

try:
    import RPi.GPIO as GPIO
except RuntimeError:
    print("Error importing RPi.GPIO!  This is probably because you need superuser privileges.  You can achieve this by using 'sudo' to run your script")

import os
import time
button_file_path = "button_event"


def simple_input_read():
    channel = 11

    # set gpio
    GPIO.setmode(GPIO.BOARD)
    GPIO.setup(channel, GPIO.IN)

    try:
        while True:
            state = GPIO.input(channel)
            #print("Touch button: " + str(state))
            time.sleep(0.05)
            if state == 1:
                return True
            else:
                return False
    except KeyboardInterrupt:
        return None
        print("CTRL-C exit")

def write_button_file(retry=10, try_delay=0.1):
    global button_file_path
    while retry > 0:
        try:
            with open(button_file_path, 'a') as f:
                f.write(str(time.time()) + "\n" )
                break
        except:
            retry -= 1
            time.sleep(try_delay)

def button_loop():
    try:
        while True:
            is_pressed = False
            state = simple_input_read()
            while not state:
                state = simple_input_read()
                if state is None:
                    break
                if state:
                    is_pressed = True
                    print("Button was pressed")
                    write_button_file()
            if state is None:
                break

    except KeyboardInterrupt:
        return False
        print("CTRL-C exit")

def init():
    global button_file_path
    if os.path.exists(button_file_path):
        os.remove(button_file_path)

if __name__ == "__main__":
    init()
    button_loop()
