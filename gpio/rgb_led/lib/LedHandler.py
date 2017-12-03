try:
    import RPi.GPIO as GPIO
except RuntimeError:
    print("Error importing RPi.GPIO!  This is probably because you need superuser privileges.  You can achieve this by using 'sudo' to run your script")
import time

class LedHandler():

    def __init__(self, channel, freq=100):
        channel = channel
        self.dc = 0                              # where dc is the duty cycle (0.0 <= dc <= 100.0)
        frequency = freq                    # Hz

        # set gpio
        GPIO.setmode(GPIO.BOARD)
        GPIO.setup(channel, GPIO.OUT)
        self.pin = GPIO.PWM(channel, frequency)

        # start pwm
        self.start(self.dc)

    # SET DUTY CYCLE
    def set_dc(self, dc):
        self.dc = dc
        self.pin.ChangeDutyCycle(self.dc)

    # SET DC WITH DIM EFFECT
    def set_dc_with_gradient(self, dc):
        step = 1
        step_delay = 0.01
        if dc > self.dc:
            for grad in range(self.dc, dc, step):
                time.sleep(step_delay)
                self.set_dc(grad)
                #print(grad)
        if dc < self.dc:
            for grad in range(self.dc, dc, step*-1):
                time.sleep(step_delay)
                self.set_dc(grad)
                #print(grad)
        if dc == self.dc:
            self.set_dc(dc)

    # STOP PWM
    def stop(self):
       self.pin.stop()

    # START PWM
    def start(self, dc=None):
        if dc is None:
            dc = self.dc
        self.pin.start(dc)

    def __del__(self):
        self.pin.stop()
        GPIO.cleanup()

if __name__ == "__main__":
    green = LedHandler(channel=12)
    green.set_dc_with_gradient(50)
    green.set_dc_with_gradient(10)
    input()
