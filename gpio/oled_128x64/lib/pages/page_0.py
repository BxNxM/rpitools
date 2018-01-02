import subprocess
import time

#################################################################################
#                              PAGE 0 - performance monitor                     #
#                              ----------------------------                     #
#                             * IP, * CPU load, * MEM, * DISK                   #
#################################################################################

def page_setup(display):
    display.head_page_bar_switch(True, True)
    display.display_refresh_time_setter(3)

def page(display):
    #time.sleep(3)

    cmd = "hostname -I | cut -d\' \' -f1"
    IP = subprocess.check_output(cmd, shell = True)

    #cmd = "top -bn1 | grep load | awk '{printf \"CPU Load: %.2f\", $(NF-2)}'"
    cmd = "/home/$USER/rpitools/tools/proc_stat.sh -s"
    CPU = subprocess.check_output(cmd, shell = True )
    #CPU_percent = float(CPU.split()[2])*100
    #CPU_ = "CPU Load: " + str(CPU_percent) + " %"
    CPU_ = str(CPU) + " %"

    cmd = "free -m | awk 'NR==2{printf \"Mem: %s/%sMB %.2f%%\", $3,$2,$3*100/$2 }'"
    MemUsage = subprocess.check_output(cmd, shell = True )
    mem_string = MemUsage.split(" ")[2]
    mem_string += " (" + MemUsage.split(" ")[1] + ")"
    MemUsage = mem_string

    cmd = "df -h | awk '$NF==\"/\"{printf \"Disk: %d/%dGB %s\", $3,$2,$5}'"
    Disk = subprocess.check_output(cmd, shell = True )
    disk_string = Disk.split(" ")[2]
    disk_string += " (" + Disk.split(" ")[1] + ")"
    Disk = disk_string

    x = 0
    y = 14
    # Write two lines of text.
    w, h = display.draw_text("IP:   " + str(IP), x, y)
    y+=h
    display.draw_text("CPU:  " + str(CPU_), x, y)
    y+=h
    display.draw_text("MEM:  " + str(MemUsage), x, y)
    y+=h
    display.draw_text("DISK: " + str(Disk), x, y)

    #display.virtual_button("right")
    #display.oled_sys_message("test message, hello bello")

    return False

def page_destructor(display):
    pass
