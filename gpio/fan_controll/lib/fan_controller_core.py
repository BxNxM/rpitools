#!/usr/bin/python3
#GPIO USAGE: https://sourceforge.net/p/raspberry-gpio-python/wiki/BasicUsage/
#GPIO PINOUT: https://www.raspberrypi-spy.co.uk/2012/06/simple-guide-to-the-rpi-gpio-header-and-pins/
try:
    import RPi.GPIO as GPIO
except RuntimeError:
    print("Error importing RPi.GPIO!  This is probably because you need superuser privileges.  You can achieve this by using 'sudo' to run your script")
import LogHandler
fancontroll = LogHandler.LogHandler("fancontroll")
import LocalMachine
import time
import os
import sys
myfolder = os.path.dirname(os.path.abspath(__file__))

try:
    confighandler_path = myfolder + os.sep + "../../../autodeployment/bin/ConfigHandlerInterface.py"

    cmd = "{} -s {} -o {}".format(confighandler_path, "TEMP_CONTROLL_FAN", "activate")
    exit_code, stdout, stderr = LocalMachine.run_command(cmd)
    is_activated = stdout.decode("utf-8")

    cmd = "{} -s {} -o {}".format(confighandler_path, "TEMP_CONTROLL_FAN", "temperature_trigger_celsius")
    exit_code, stdout, stderr = LocalMachine.run_command(cmd)
    temperature_trigger_celsius = stdout.decode("utf-8")

    cmd = "{} -s {} -o {}".format(confighandler_path, "TEMP_CONTROLL_FAN", "temperature_inertia_celsius")
    exit_code, stdout, stderr = LocalMachine.run_command(cmd)
    temperature_inertia_celsius = stdout.decode("utf-8")

    cmd = "{} -s {} -o {}".format(confighandler_path, "TEMP_CONTROLL_FAN", "pin_channel")
    exit_code, stdout, stderr = LocalMachine.run_command(cmd)
    pin_channel = stdout.decode("utf-8")
except Exception as e:
    fancontroll.logger.warn("Import config handler failed: " + str(e))

#################################
#       Configuration           #
#################################
channel = int(pin_channel)
temperature_trigger_celsius = int(temperature_trigger_celsius)
temperature_inertia_celsius = int(temperature_inertia_celsius)

#################################
#           Functions           #
#################################
def get_cpu_temp():
    data = LocalMachine.run_command_safe("/opt/vc/bin/vcgencmd measure_temp")
    data = data[5:-2]
    return float(data)

def get_gpu_temp():
    data = LocalMachine.run_command_safe("cat /sys/class/thermal/thermal_zone0/temp")
    data = float(data) / 1000
    data = '%.1f' % data
    return float(data)

def get_cpu_gpu_average_temp():
    print("Get temp")
    cpu_temp = get_cpu_temp()
    gpu_temp = get_gpu_temp()
    return int((cpu_temp + gpu_temp) / 2)

def init_gpio_pin(channel=40):
    print("Init pin")
    # SET GPIO MODE
    GPIO.setmode(GPIO.BOARD)
    #GPIO.setmode(GPIO.BCM)

    # GET GPIO MODE
    mode = GPIO.getmode()
    fancontroll.logger.info("gpio mode: " + str(mode))

    # GPIO OUTPUT EXAMPLE
    GPIO.setup(channel, GPIO.OUT)

def clean_gpio_pin(channel=40):
    print("Clean pin")
    # CLEANUP GPIO AFTER USAGE
    #GPIO.cleanup()
    GPIO.cleanup(channel)

def fan_pin_controll(channel=40, state=True):
    global temperature_trigger_celsius, temperature_inertia_celsius
    switch_action = False
    while True:
        # get actual temperature
        temp = get_cpu_gpu_average_temp()
        fancontroll.logger.debug("Actual temperature: " + str(temp))
        print("Actual temperature: " + str(temp))
        if temp >= temperature_trigger_celsius:
            if switch_action is False:
                fancontroll.logger.debug("Trigger exceeded [{} celsius]-> action: turn on the fan".format(temperature_trigger_celsius))
                print("Trigger exceeded [{} celsius]-> action: turn on the fan".format(temperature_trigger_celsius))
                switch_action = not switch_action
                # override official temperature trigger value for controll stabilization
                temperature_trigger_celsius = temperature_trigger_celsius - temperature_inertia_celsius
                fancontroll.logger.debug("\tTurn off temperature: " + str(temperature_trigger_celsius))
                print("\tTurn off temperature: " + str(temperature_trigger_celsius))

                # turn on the fan
                GPIO.output(channel, state)
        else:
            if switch_action is True:
                fancontroll.logger.debug("Trigger exceeded [{} celsius]-> action: turn off the fan".format(temperature_trigger_celsius))
                print("Trigger exceeded [{} celsius]-> action: turn off the fan".format(temperature_trigger_celsius))
                switch_action = not switch_action
                # retrieve original trigger temperature
                temperature_trigger_celsius = temperature_trigger_celsius + temperature_inertia_celsius
                fancontroll.logger.debug("\tTurn on temperature: " + str(temperature_trigger_celsius))
                print("\tTurn on temperature: " + str(temperature_trigger_celsius))
                # negate (trun off) the fan
                GPIO.output(channel, not state)
        time.sleep(5)

#################################
#           Main core           #
#################################
def main():
    fancontroll.logger.info("Start fan conntrolling PIN: {}, TEMP: {}, INERTIA: {}".format(channel, temperature_trigger_celsius, temperature_inertia_celsius))
    init_gpio_pin(channel=channel)
    try:
        fan_pin_controll(channel=channel)
    except KeyboardInterrupt:
        print("Goodbye")
    except Exception as e:
        print(e)
        clean_gpio_pin(channel=channel)
    clean_gpio_pin(channel=channel)

if __name__ == "__main__":
    if is_activated.lower() == "true":
        main()
    else:
        fancontroll.logger.warn("Fan controll was not activated in: confeditor")

