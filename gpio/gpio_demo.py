#!/usr/bin/python3
#GPIO USAGE: §https://sourceforge.net/p/raspberry-gpio-python/wiki/BasicUsage/
#GPIO PINOUT: https://www.raspberrypi-spy.co.uk/2012/06/simple-guide-to-the-rpi-gpio-header-and-pins/
try:
    import RPi.GPIO as GPIO
except RuntimeError:
    print("Error importing RPi.GPIO!  This is probably because you need superuser privileges.  You can achieve this by using 'sudo' to run your script")

import time

def simple_gpio_usage_output():
    # SET GPIO MODE
    GPIO.setmode(GPIO.BOARD)
    #GPIO.setmode(GPIO.BCM)

    # GET GPIO MODE
    mode = GPIO.getmode()
    print("gpio mode: " + str(mode))

    # GPIO OUTPUT EXAMPLE
    channel=12
    state=True
    GPIO.setup(channel, GPIO.OUT)
    GPIO.output(channel, state)

    time.sleep(1)

    state=False
    GPIO.output(channel, state)

    # CLEANUP GPIO AFTER USAGE
    #GPIO.cleanup()
    GPIO.cleanup(channel)


def pwm_gpio_usage_output():
    channel = 12
    dc = 0                              # where dc is the duty cycle (0.0 <= dc <= 100.0)
    frequency = 40                      # Hz

    # set gpio
    GPIO.setmode(GPIO.BOARD)
    GPIO.setup(channel, GPIO.OUT)
    p = GPIO.PWM(channel, frequency)

    # start pwm
    p.start(dc)

    # brighten/dim demo
    for i in range(1,50):
        time.sleep(0.1)
        dc = i
        p.ChangeDutyCycle(dc)

    # exit
    input('Press return to stop:')      # use raw_input for Python 2
    p.stop()
    GPIO.cleanup()

#simple_gpio_usage_output()
pwm_gpio_usage_output()
