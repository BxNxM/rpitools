import time
import LogHandler
mylogger = LogHandler.LogHandler("ledhandler")
try:
    import RPi.GPIO as GPIO
except RuntimeError:
    mylogger.logger.error("Error importing RPi.GPIO!  This is probably because you need superuser privileges.  You can achieve this by using 'sudo' to run your script")

class LedHandler():

    def __init__(self, channel, freq=80):
        self.channel = channel
        self.dc = 0                              # where dc is the duty cycle (0.0 <= dc <= 100.0)
        frequency = freq                    # Hz

        # set gpio
        GPIO.setmode(GPIO.BOARD)
        GPIO.setup(channel, GPIO.OUT)
        self.pin = GPIO.PWM(channel, frequency)

        # start pwm
        self.start(self.dc)

        mylogger.logger.info('LedHandler object is created')

    # SET DUTY CYCLE
    def set_dc(self, dc):
        self.dc = dc
        self.pin.ChangeDutyCycle(self.dc)
        mylogger.logger.info('Change duty cycle: ' + str(self.dc))

    # SET DC WITH DIM EFFECT
    def set_dc_with_gradient(self, dc):
        step = 1
        step_delay = 0.01
        mylogger.logger.info('Make gradient: {} to {}'.format(self.dc, dc))
        if dc > self.dc:
            for grad in range(self.dc, dc+1, step):
                time.sleep(step_delay)
                self.set_dc(grad)
                #print(grad)
        if dc < self.dc:
            for grad in range(self.dc, dc-1, step*-1):
                time.sleep(step_delay)
                self.set_dc(grad)
                #print(grad)
        if dc == self.dc:
            self.set_dc(dc)

    # STOP PWM
    def stop(self):
        self.pin.stop()
        mylogger.logger.info('stoping pwd')

    # START PWM
    def start(self, dc=None):
        if dc is None:
            dc = self.dc
            mylogger.logger.info('set dc from self.dc: ' + str(dc))
        self.pin.start(dc)
        mylogger.logger.info('Start PWM')

    def __del__(self):
        try:
            print('kill object: stop and cleanup')
            self.pin.stop()
            GPIO.cleanup(self.channel)
        except Exception as e:
            print(e)

if __name__ == "__main__":
    green = LedHandler(channel=12)
    time.sleep(1)
    green.set_dc_with_gradient(50)
    time.sleep(1)
    green.set_dc_with_gradient(100)
    time.sleep(1)
    green.set_dc_with_gradient(50)
    time.sleep(1)
    green.set_dc_with_gradient(0)
    time.sleep(1)
    input()
