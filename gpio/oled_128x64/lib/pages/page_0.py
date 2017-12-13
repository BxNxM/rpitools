import subprocess

def page(display):
    # Draw a black filled box to clear the image.
    #self.draw.rectangle((0,0,self.disp.width,self.disp.height), outline=0, fill=0)

    # Shell scripts for system monitoring from here : https://unix.stackexchange.com/questions/119126/command-to-display-memory-usage-disk-usage-and-cpu-load
    cmd = "hostname -I | cut -d\' \' -f1"
    IP = subprocess.check_output(cmd, shell = True)

    cmd = "top -bn1 | grep load | awk '{printf \"CPU Load: %.2f\", $(NF-2)}'"
    CPU = subprocess.check_output(cmd, shell = True )
    CPU_percent = float(CPU.split()[2])*100
    CPU_ = "CPU Load: " + str(CPU_percent) + " %"

    cmd = "free -m | awk 'NR==2{printf \"Mem: %s/%sMB %.2f%%\", $3,$2,$3*100/$2 }'"
    MemUsage = subprocess.check_output(cmd, shell = True )

    cmd = "df -h | awk '$NF==\"/\"{printf \"Disk: %d/%dGB %s\", $3,$2,$5}'"
    Disk = subprocess.check_output(cmd, shell = True )

    x = 5
    y = 14
    # Write two lines of text.
    w, h = display.draw_text("IP: " + str(IP), x, y)
    y+=h
    display.draw_text(str(CPU_), x, y)
    y+=h
    display.draw_text(str(MemUsage), x, y)
    y+=h
    display.draw_text(str(Disk), x, y)
