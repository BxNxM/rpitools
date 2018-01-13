import sys
import os
import subprocess
user = subprocess.check_output("echo $USER", shell = True).split()[0]
page_files_path = "/home/" + user + "/rpitools/tools/"
sys.path.append(page_files_path)
import wifi_info
import re

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

def get_weather_info():
    location = "Budapest"
    cmd = "curl wttr.in/?0/?T/?m/?M/" + location
    # get weather with command line command
    weather = subprocess.check_output(cmd, shell = True)
    if "ERROR" in weather:
        err_mess = weather
    else:
        err_mess = ""
    if weather != "Not so fast! Number of queries per day is limited to 1000" and "ERROR" not in weather:
        # remove ascii colors
        ansi_escape = re.compile(r'\x1B\[[0-?]*[ -/]*[@-~]')
        weather = ansi_escape.sub('', weather)
        # split lines
        weather = weather.split("\n")
        # return relevant part
        for index, line in enumerate(weather):
            converted_text = weather_line_convert(line)
            line = converted_text.rstrip().lstrip()
            if index != 0:
                weather[index] = line

        output_dict = {"location": weather[1],\
                       "weather": weather[3],\
                       "temp": weather[4],\
                       "wind": weather[5],
                       "altitude": weather[6],\
                       "rain": weather[7]\
                       }
    else:
        output_dict = {"location": "None"+str(err_mess),\
                       "weather": "None"+str(err_mess),\
                       "temp": "None"+str(err_mess),\
                       "wind": "None"+str(err_mess),
                       "altitude": "None"+str(err_mess),\
                       "rain": "None"+str(err_mess)\
                       }
    return output_dict

def weather_line_convert(line):
    buffered_output = ""
    for index, char in enumerate(line):
        if char.isalpha() or char.isdigit():
            for index in range(index, len(line)):
                buffered_output+=line[index]
            break
    return buffered_output

def print_weather_dict():
    o = get_weather_info()
    print("-"*40)
    for key, value in o.items():
        print("{} : {}".format(key, value))
    print("-"*40)

if __name__ == "__main__":
    print("WIFI signal quality: " + str(wifi_quality()))
    cpu, mem, temp, disk = performance_widget()
    print("cpu: {}\nmem: {}\ntemp: {}\ndisk: {}".format(cpu, mem, temp, disk))
    print("SSID: {}".format(wifi_get_ssid()))

    print("weather get info")
    print_weather_dict()
