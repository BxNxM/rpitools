import subprocess
import time

def page_setup(display):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(3)

def page(display):
    #time.sleep(3)

    cmd = "/opt/vc/bin/vcgencmd measure_temp"
    temp = subprocess.check_output(cmd, shell = True)
    temp = "temp: " + temp.split("=")[1]

    cmd = 'frg=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) && echo "$frg Hz"'
    #cmd = "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
    freq = subprocess.check_output(cmd, shell = True)
    freq = "cpu freq: " + freq

    x = 5
    y = 14
    # Write two lines of text.
    w, h = display.draw_text(str(temp), x, y)
    y+=h
    display.draw_text(str(freq), x, y)

    return False
