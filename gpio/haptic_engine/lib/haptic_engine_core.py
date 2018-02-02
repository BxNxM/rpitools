#!/usr/bin/python3
#GPIO USAGE: §https://sourceforge.net/p/raspberry-gpio-python/wiki/BasicUsage/
#GPIO PINOUT: https://www.raspberrypi-spy.co.uk/2012/06/simple-guide-to-the-rpi-gpio-header-and-pins/
try:
    import RPi.GPIO as GPIO
except RuntimeError:
    print("Error importing RPi.GPIO!  This is probably because you need superuser privileges.  You can achieve this by using 'sudo' to run your script")

import time


class OutputChannelDriver():

    def __init__(self, channel=11):
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
        if time_sec is not None:
            time.sleep(time_sec)

    def soft_pwm(self, high_percent, hold_time_sec=0):
        timing = 0.02 / 100
        loop = int(hold_time_sec / (timing * 100))
        for pwd_loop in range(0, loop):
            self.set_state(state=True, time_sec=timing * high_percent)
            self.set_state(state=False, time_sec=timing * (100 - high_percent))

    def gradient(self, start, end, hold_time=0.1, step=8):
        if start < end:
            for state in range(start, end, step):
                self.soft_pwm(state, hold_time)
            if state != end:
                self.soft_pwm(end, hold_time)
        elif start > end:
            for state in range(start, end, -step):
                self.soft_pwm(state, hold_time)
            if state != end:
                self.soft_pwm(end, hold_time)

    def __del__(self):
        GPIO.cleanup(self.channel)

class HapticEngine(OutputChannelDriver):

    def __init__(self, channel=11, speed=18):
        super().__init__(channel)
        self.speed = 1 / speed

    def UP(self):
        self.gradient(5, 100, hold_time=self.speed, step=15)
        self.set_state(True, time_sec=0.05)
        self.set_state(False)

    def DOWN(self):
        self.set_state(True, time_sec=0.05)
        self.gradient(100, 5, hold_time=self.speed, step=15)
        self.set_state(False)

    def SOFT(self):
        self.gradient(5, 100, hold_time=self.speed, step=30)
        self.gradient(100, 5, hold_time=self.speed, step=30)
        self.set_state(False)

    def TAP(self):
        self.gradient(90, 100, hold_time=self.speed, step=10)
        self.set_state(False)

    def DoubleTAP(self):
        self.TAP()
        time.sleep(0.1)
        self.TAP()

    def SNOOZE(self):
        self.gradient(0, 100, hold_time=self.speed*5, step=5)
        self.set_state(False)

def OutputChannelDriver_DEMO():
    driver = OutputChannelDriver()
    print("set state")
    driver.set_state(True, time_sec=0.2)
    time.sleep(0.5)
    print("soft_pwm")
    driver.soft_pwm(30, 4)
    time.sleep(0.5)
    print("gradient 0 -> 100")
    driver.gradient(0, 100)
    time.sleep(0.5)
    print("gradient 100 -> 0")
    driver.gradient(100, 0)

def HapticEngine_DEMO():
    hapt = HapticEngine()
    print("HapticEngine: UP")
    hapt.UP()
    time.sleep(1)
    print("HapticEngine: DOWN")
    hapt.DOWN()
    time.sleep(1)
    print("HapticEngine: SOFT")
    hapt.SOFT()
    time.sleep(1)
    print("HapticEngine: TAP")
    hapt.TAP()
    time.sleep(1)
    print("HapticEngine: DoubleTAP")
    hapt.DoubleTAP()
    time.sleep(1)
    print("HapticEngine: SNOOZE")
    hapt.SNOOZE()

if __name__ == "__main__":
    OutputChannelDriver_DEMO()
    HapticEngine_DEMO()
