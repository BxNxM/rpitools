import subprocess
import random
import time

change_time = 5
change_cycle = 100

# CHANGE COLOR
for cycle in range(0, change_cycle):
    red = random.randint(0, 100)
    green = random.randint(0, 100)
    blue = random.randint(0, 100)

    print("CAHNGE COLOR: R {} G {} B {}".format(red, green, blue))
    args = ["./rgb_interface.py", "-r", str(red), "-g", str(green), "-b", str(blue)]
    p = subprocess.Popen(args)
    time.sleep(change_time)

# TURN OFF LED
print("TURN OFF LED")
args = ["./rgb_interface.py", "-l", "OFF"]
p = subprocess.Popen(args)
time.sleep(4)

print("TURN ON LED SERVICE")
# TURN OFF LED SERVICE
args = ["./rgb_interface.py", "-s", "OFF"]
p = subprocess.Popen(args)
