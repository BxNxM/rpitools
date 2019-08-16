#!/usr/bin/python3
import LogHandler
import os
import time
import threading
import sys
mylogger = LogHandler.LogHandler("joystick_handler")
myfolder = os.path.dirname(os.path.abspath(__file__))

# IMPORT IMPORTING GPIO LIB
try:
    import RPi.GPIO as GPIO
except RuntimeError:
    mylogger.logger.error("Error importing RPi.GPIO!  This is probably because you need superuser privileges.  You can achieve this by using 'sudo' to run your script")

def rpienv_source():
    import subprocess
    if not os.path.exists(str(myfolder) + '/.rpienv'):
        print("[ ENV ERROR ] " + str(myfolder) + "/.rpienv path not exits!")
        sys.exit(1)
    command = ['bash', '-c', 'source ' + str(myfolder) + '/.rpienv -s && env']
    proc = subprocess.Popen(command, stdout = subprocess.PIPE)
    for line in proc.stdout:
        if type(line) is bytes:
            line = line.decode("utf-8")
        try:
            name = line.partition("=")[0]
            value = line.partition("=")[2]
            if type(value) is unicode:
                value = value.encode('ascii','ignore')
            value = value.rstrip()
            os.environ[name] = value
        except Exception as e:
            if "name 'unicode' is not defined" != str(e):
                print(e)
    proc.communicate()
rpienv_source()

# IMPORT SAHERED SOCKET MEMORY FOR VIRTUAL BUTTONS
try:
    clientmemdict_path = os.path.join(os.path.dirname(os.environ['CLIENTMEMDICT']))
    sys.path.append( clientmemdict_path )
    import clientMemDict
    socketdict = clientMemDict.SocketDictClient()
except Exception as e:
    socketdict = None
    print("Socket client error: " + str(e))

# IMPORT HAPTIC ENGINE INTERFACE
try:
    haptic_eng_bin_path = os.path.join(myfolder, "../../haptic_engine/bin/")
    sys.path.append(haptic_eng_bin_path)
    import hapticenginge_interface as hei
    hei.hapt.set_channel_clean(False)                                # not clean haptic engine channel under button uses it!
except Exception as e:
    print("Haptic engine import failed: " + str(e))

class JoystickHandler():

    def __init__(self, up_pin, down_pin, right_pin, left_pin, center_pin, haptic=True, mode="BCM"):
        self.channels_dict = {"UP": up_pin,\
                              "DOWN": down_pin,\
                              "RIGHT": right_pin,\
                              "LEFT": left_pin,\
                              "CENTER": center_pin}
        self.haptic = haptic
        # set gpio channels
        if mode == "BOARD":
            GPIO.setmode(GPIO.BOARD)
        elif mode == "BCM":
            GPIO.setmode(GPIO.BCM)
        for key in self.channels_dict:
            GPIO.setup(self.channels_dict[key], GPIO.IN, pull_up_down=GPIO.PUD_DOWN)

        ####################
        self.threads = []
        self.last_event_cmd = None
        self.button_thrd_timing = 0.1
        self.virtual_button_socketMemDict_watch_thrd_timing = 0.2

        self.button_threads_init()

    def button_threads_init(self):
        self.threads.append(threading.Thread(target=self.up_button_thrd))
        self.threads.append(threading.Thread(target=self.down_button_thrd))
        self.threads.append(threading.Thread(target=self.left_button_thrd))
        self.threads.append(threading.Thread(target=self.right_button_thrd))
        self.threads.append(threading.Thread(target=self.center_button_thrd))
        self.threads.append(threading.Thread(target=self.virtual_button_socketMemDict_watch_thrd))
        # write more threads here...
        for thd in self.threads:
            thd.daemon = True                                   # with this set, can stop therad
            thd.start()
            time.sleep(0.1)
        # sleep a little while manage_pages_thread read contents
        time.sleep(0.5)

    def up_button_thrd(self):
        while True:
            channel = self.channels_dict["UP"]
            if self.__button_event_get(channel, edge="up"):
                self.last_event_cmd = "UP"
            time.sleep(self.button_thrd_timing)

    def down_button_thrd(self):
        while True:
            channel = self.channels_dict["DOWN"]
            if self.__button_event_get(channel, edge="up"):
                self.last_event_cmd = "DOWN"
            time.sleep(self.button_thrd_timing)

    def left_button_thrd(self):
        while True:
            channel = self.channels_dict["LEFT"]
            if self.__button_event_get(channel, edge="up"):
                self.last_event_cmd = "LEFT"
            time.sleep(self.button_thrd_timing)

    def right_button_thrd(self):
        while True:
            channel = self.channels_dict["RIGHT"]
            if self.__button_event_get(channel, edge="up"):
                self.last_event_cmd = "RIGHT"
            time.sleep(self.button_thrd_timing)

    def center_button_thrd(self):
        while True:
            channel = self.channels_dict["CENTER"]
            if self.__button_event_get(channel, edge="up"):
                self.last_event_cmd = "CENTER"
            time.sleep(self.button_thrd_timing)

    def virtual_button_socketMemDict_watch_thrd(self):
        while True:
            cmd = socketdict.get_parameter("oled", "joystick").rstrip().upper()
            if cmd == "UP" or cmd == "DOWN" or cmd == "CENTER" or cmd == "RIGHT" or cmd == "LEFT":
                self.last_event_cmd = cmd
                time.sleep(0.5)
                socketdict.set_parameter("oled", "joystick", "None")
            time.sleep(self.virtual_button_socketMemDict_watch_thrd_timing)

    def get_button_evenet(self, in_loop=True):
        while in_loop:
            if self.last_event_cmd is not None:
                print("Button was pressed: " + str(self.last_event_cmd))
                return_value = self.last_event_cmd
                self.last_event_cmd = None
                try:
                    if self.haptic:
                        hei.run_interface(option="tap")
                except Exception as e:
                    print("Haptic engine call failed: " + str(e))
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

    def joystick_wait_for_event(self, in_loop=True):
        return self.get_button_evenet(in_loop=True)

    def __del__(self):
        try:
            print('kill object: cleanup')
            for key in self.channels_dict:
                GPIO.cleanup(self.channels_dict[key])
            hei.hapt.set_channel_clean(True)                            # set channel clean to True after button finished to use it
        except Exception as e:
            print(e)

if "JoystickHandler" in __name__:
    joystick = JoystickHandler(up_pin=22, down_pin=16, right_pin=27, left_pin=25, center_pin=24)        # BCM mode

if __name__ == "__main__":
    joystick = JoystickHandler(up_pin=22, down_pin=16, right_pin=27, left_pin=25, center_pin=24)        # BCM mode
    while True:
        try:
            joystick.joystick_wait_for_event()
        except KeyboardInterrupt:
            break

