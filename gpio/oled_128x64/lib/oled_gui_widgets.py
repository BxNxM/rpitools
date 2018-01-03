import sys
import os
import subprocess
user = subprocess.check_output("echo $USER", shell = True).split()[0]
page_files_path = "/home/" + user + "/rpitools/tools/"
sys.path.append(page_files_path)
import wifi_info

def wifi_quality():
    try:
        output = wifi_info.run_main()
        print(output)
        if str(wifi_get_ssid()) in output:
            quality = int(output[8])
            if quality <= 33:
                blocks = 1
            elif quality <= 66:
                blocks = 2
            elif quality <=100:
                blocks = 3
            else:
                blocks = 0
        else:
            blocks = -1
    except:
        blocks = -1
    return blocks

def wifi_get_ssid():
    try:
        cmd = 'iwlist wlan0 scan | grep "ESSID"'
        ssid_connected = subprocess.check_output(cmd, shell = True)
        ssid_connected = ssid_connected.split("\n")[0]
        ssid_connected = ssid_connected.split(":")[1]
        ssid_connected = ssid_connected[1:-1]
    except:
        ssid_connected = None
    return str(ssid_connected)

def performance_widget():
    cmd = "/home/$USER/rpitools/tools/proc_stat.sh -s"
    CPU = subprocess.check_output(cmd, shell = True)

    cmd = "free -m | awk 'NR==2{printf \"Mem: %s/%sMB %.2f%%\", $3,$2,$3*100/$2 }'"
    MemUsage = subprocess.check_output(cmd, shell = True)
    MemUsage = MemUsage.split(" ")[2]
    MemUsage = MemUsage.split(".")[0]

    cmd = "df -h | awk '$NF==\"/\"{printf \"Disk: %d/%dGB %s\", $3,$2,$5}'"
    Disk = subprocess.check_output(cmd, shell = True )
    DiskUsage = Disk.split(" ")[2]
    DiskUsage = DiskUsage[0:-1]

    cmd = "/opt/vc/bin/vcgencmd measure_temp"
    temp = subprocess.check_output(cmd, shell = True)
    temp = temp.split("=")[1]
    temp = temp.split(".")[0]

    return CPU, MemUsage, temp, DiskUsage

if __name__ == "__main__":
    print("WIFI signal quality: " + str(wifi_quality()))
    cpu, mem, temp, disk = performance_widget()
    print("cpu: {}\nmem: {}\ntemp: {}\ndisk: {}".format(cpu, mem, temp, disk))
    print("SSID: {}".format(wifi_get_ssid()))
