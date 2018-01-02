import subprocess
import time

#################################################################################
#                              PAGE 1 - performance monitor                     #
#                              ----------------------------                     #
#                                 * TEMP, * CPU freq                            #
#################################################################################

def page_setup(display):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(3)

def page(display):
    #time.sleep(3)

    cmd = "/opt/vc/bin/vcgencmd measure_temp"
    temp = subprocess.check_output(cmd, shell = True)
    temp = temp.split("=")[1]

    cmd = 'frg=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) && echo "$frg Hz"'
    freq = subprocess.check_output(cmd, shell = True)
    freqMhz = int(freq.split(" ")[0]) / 1000

    x = 0
    y = 14
    # Write two lines of text.
    w, h = display.draw_text("TEMP: " + str(temp), x+1, y)
    y+=h
    display.draw_text("CPU:  " + str(freqMhz) + " MHz ", x, y)

    return False
