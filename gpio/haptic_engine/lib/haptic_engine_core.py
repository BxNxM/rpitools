#!/usr/bin/python3
#GPIO USAGE: §https://sourceforge.net/p/raspberry-gpio-python/wiki/BasicUsage/
#GPIO PINOUT: https://www.raspberrypi-spy.co.uk/2012/06/simple-guide-to-the-rpi-gpio-header-and-pins/
try:
    import RPi.GPIO as GPIO
except RuntimeError:
    print("Error importing RPi.GPIO!  This is probably because you need superuser privileges.  You can achieve this by using 'sudo' to run your script")

import time


class OutputChannelDriver():

    def __init__(self, channel=12):
        self.channel = channel

        # SET GPIO MODE
        GPIO.setmode(GPIO.BOARD)
        #GPIO.setmode(GPIO.BCM)

        # GET GPIO MODE
        mode = GPIO.getmode()
        #print("gpio mode: " + str(mode))

        # GPIO OUTPUT EXAMPLE
        GPIO.setup(self.channel, GPIO.OUT)

    def set_state(self, state, time_sec=None):
        GPIO.output(self.channel, state)
        if time is not None:
            time.sleep(time_sec)

    def soft_pwm(self, high_percent, hold_time_sec=0):
        timing = 0.02 / 100
        loop = int(hold_time_sec / (timing * 100))
        for pwd_loop in range(0, loop):
            self.set_state(state=True, time_sec=timing * high_percent)
            self.set_state(state=False, time_sec=timing * (100 - high_percent))

    def gradient(self, start, end, hold_time=0.1):
        if start < end:
            for state in range(start, end, 8):
                self.soft_pwm(state, hold_time)
            if state != end:
                self.soft_pwm(end, hold_time)
        elif start > end:
            for state in range(start, end, -8):
                self.soft_pwm(state, hold_time)
            if state != end:
                self.soft_pwm(end, hold_time)

    def __del__(self):
        GPIO.cleanup(self.channel)

class HapticEngine(OutputChannelDriver):

    def __init__(self, channel=12):
        super().__init__(self, channel)

    def UP(self):
        pass

    def DOWN(self):
        pass

    def LOOP(self):
        pass

    def TAP(self):
        pass

def OutputChannelDriver_DEMO():
    hapt = OutputChannelDriver()
    print("set state")
    hapt.set_state(True, time_sec=0.2)
    time.sleep(0.5)
    print("soft_pwm")
    hapt.soft_pwm(30, 4)
    time.sleep(0.5)
    print("gradient 0 -> 100")
    hapt.gradient(0, 100)
    time.sleep(0.5)
    print("gradient 100 -> 0")
    hapt.gradient(100, 0)

if __name__ == "__main__":
    OutputChannelDriver_DEMO()
