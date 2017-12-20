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
        #print(output)
        quality = int(output[8])
        if quality <= 33:
            blocks = 1
        elif quality <= 66:
            blocks = 2
        elif quality <=100:
            blocks = 3
        else:
            blocks = 0
    except:
        blocks = -1
    return blocks

if __name__ == "__main__":
    print("WIFI signal quality: " + str(wifi_quality()))
