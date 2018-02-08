import subprocess
import time

#################################################################################
#                              PAGE 0 - performance monitor                     #
#                              ----------------------------                     #
#                             * IP, * CPU load, * MEM, * DISK                   #
#################################################################################

def page_setup(display, joystick_elements):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(3)

def page(display, joystick, joystick_elements):
    #time.sleep(3)

    cmd = "hostname -I | cut -d\' \' -f1"
    IP = subprocess.check_output(cmd, shell = True)

    #cmd = "top -bn1 | grep load | awk '{printf \"CPU Load: %.2f\", $(NF-2)}'"
    cmd = "/home/$USER/rpitools/tools/proc_stat.sh -s"
    CPU = subprocess.check_output(cmd, shell = True )
    CPU_ = str(CPU) + " %"

    cmd = "free -m | awk 'NR==2{printf \"Mem: %s/%sMB %.2f%%\", $3,$2,$3*100/$2 }'"
    MemUsage = subprocess.check_output(cmd, shell = True )
    mem_string = MemUsage.split(" ")[2]
    mem_string += " (" + MemUsage.split(" ")[1] + ")"
    MemUsage = mem_string

    cmd = "/opt/vc/bin/vcgencmd measure_temp"
    temp = subprocess.check_output(cmd, shell = True)
    temp = temp.split("=")[1]

    x = 0
    y = 14
    # Write two lines of text.
    w, h = display.draw_text("IP:   " + str(IP), x, y)
    y+=h
    display.draw_text("CPU:  " + str(CPU_), x, y)
    y+=h
    display.draw_text("MEM:  " + str(MemUsage), x, y)
    y+=h
    display.draw_text("TEMP: " + str(temp), x+1, y)

    #display.virtual_button("right")
    #display.oled_sys_message("test message, hello bello")

    return False

def page_destructor(display, joystick_elements):
    pass
