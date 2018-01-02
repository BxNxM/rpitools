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

    cmd = "df -h | awk '$NF==\"/\"{printf \"Disk: %d/%dGB %s\", $3,$2,$5}'"
    Disk = subprocess.check_output(cmd, shell = True )
    disk_string = Disk.split(" ")[2]
    disk_string += " (" + Disk.split(" ")[1] + ")"
    Disk = disk_string

    cmd = 'frg=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq) && echo "$frg Hz"'
    freq = subprocess.check_output(cmd, shell = True)
    freqMhz = int(freq.split(" ")[0]) / 1000

    x = 0
    y = 14
    # Write two lines of text.
    w, h = display.draw_text("DISK: " + str(Disk), x, y)
    y+=h
    display.draw_text("CPU:  " + str(freqMhz) + " MHz ", x, y)

    return False

def page_destructor(display):
    pass
