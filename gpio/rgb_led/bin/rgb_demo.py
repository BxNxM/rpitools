#!/usr/bin/python3

import subprocess
import random
import time

change_time = 10
change_cycle = 1000

# CHANGE COLOR
for cycle in range(0, change_cycle):
    #red = random.randint(0, 100)
    red = int(random.randrange(0, 100, 5))
    #green = random.randint(0, 100)
    green = int(random.randrange(0, 100, 5))
    #blue = random.randint(0, 100)
    blue = int(random.randrange(0, 100, 5))

    print("[{}/{}] CAHNGE COLOR: R {} G {} B {}".format(cycle, change_cycle, red, green, blue))
    args = ["./rgb_interface.py", "-r", str(red), "-g", str(green), "-b", str(blue)]
    p = subprocess.Popen(args)
    time.sleep(change_time)

# TURN OFF LED
print("TURN OFF LED")
args = ["./rgb_interface.py", "-l", "OFF"]
p = subprocess.Popen(args)
time.sleep(3)

#print("TURN ON LED SERVICE")
# TURN OFF LED SERVICE
#args = ["./rgb_interface.py", "-s", "OFF"]
#p = subprocess.Popen(args)
