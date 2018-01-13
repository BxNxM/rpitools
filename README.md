![logo](https://github.com/BxNxM/rpitools/blob/master/template/demo_images/rpitools_logic.png?raw=true)

```
  _____    _____    _____   _______    ____     ____    _         _____ 
 |  __ \  |  __ \  |_   _| |__   __|  / __ \   / __ \  | |       / ____|
 | |__) | | |__) |   | |      | |    | |  | | | |  | | | |      | (___  
 |  _  /  |  ___/    | |      | |    | |  | | | |  | | | |       \___ \ 
 | | \ \  | |       _| |_     | |    | |__| | | |__| | | |____   ____) |
 |_|  \_\ |_|      |_____|    |_|     \____/   \____/  |______| |_____/ 
```

## CONFIGURATION ON MAC/LINUX
***Deploy and setup raspbain image***

* clone rpi repository from github - to get the resources (file a "folder")

```
git clone https://github.com/BxNxM/rpitools.git
```

* go to rpitools/prepare_sd to find SD card preparing scripts

```
cd rpitools/prepare_sd
```

* Copy raspbian image to the rpitools/prepare\_sd/raspbian\_img folder for the installing / deploying process

```
cp ~/Downloads/*raspbian*.img raspbian_img/
```

* run the sd card imager and follow the instructions - it "burns" the raspbian.img file to the SD card.

```
./raspbian_imager.bash
```

* configure raspbian image on SD card (set: ssh, wifi, usb-eth, video ram) - follow the instructions

```
./boot_config.bash
```

* set your wifi ssid and password on the wpa_supplicant.conf file
 
```
-> manually (wifi) setup /Volumes/boot/wpa_supplicant.conf file.
```

* ***FINALLY: unmount SD card, put it in the rpi zero w***

* After raspberry pi ***BOOTED UP*** - copy rpitools (from your computer) to the raspberrypi

```
copy rpitools:
(if needed: ssh-keygen -R raspberrypi.local)
cd rpitools/prepare_sd
rm -f raspbian_img/*.img && scp -r ../../rpitools/ pi@raspberrypi.local:~/
(default pwd: raspberry)
```
## CONFIGURATION ON WINDOWS
* coming soon...

# CONFIGURATION ON THE RASPBERRY PI

* COnnect (SSH) to the pi

```
ssh pi@raspberrypi.local
(default pwd: raspberry)
```
***Configuration on  YOUR PI with rpitools***

* Source rpitools - install / setup / configure

```
cd rpitools/
source setup
```

* if you use raspbain lite, and you want a GUI

```
./install_PIXEL.bash
```

* if you want remote desktop access

```
./install_vnc.bash
```

* Finally some manual setups with raspi-config (don't forget)

```
sudo raspi-config

and set:
set default login console/desktop
location
expand file system
screen resolution
set local name
```

# ==== OLED FRAMEWORK ===
![oled](https://github.com/BxNxM/rpitools/blob/master/template/demo_images/oled.jpg?raw=true)

SUPPORTED OLED TYPE: 128x64 i2c SSD1306 Driver IC


####Enable i2c interface with raspi-config

```
sudo raspi-config
```
-> interfacing options - > i2c

***OLED BOOTUP LOUNCH SETUP - CONFIGURE A SERVICE (optional) [1]***

```
oledinterface --set_service
```

* manage oled service over systemd if you want (if you make [1] step):

```
sudo systemctl status oled_gui_core
sudo systemctl restart oled_gui_core
sudo systemctl start oled_gui_core
sudo systemctl stop oled_gui_core
```

* or manage oled framework over its own interface ([1] step isn't mandatory)

```
for more info:
oledinterface -h
```

* use virtual buttons LEFT / OK / RIGHT / standbyTrue / standbyFalse

```
oledinterface -b LEFT
oledinterface -b RIGHT
oledinterface -b OK
oledinterface -b stanbyTrue
oledinterface -b stanbyFalse
```

#### CUSTOMIZE OLED FRAMEWORK AND CRAETE NEW PAGES (OPTIONAL)
* set default page 0 < - > page numbers in /home/$USER/rpitools/gpio/oled_128x64/lib/pages/ folder

```
vim /home/$USER/rpitools/gpio/oled_128x64/lib/.defaultindex.dat
```

* create your own page under

```
/home/$USER/rpitools/gpio/oled_128x64/lib/pages/page_XY.py
```
Change XY to the next page number

Use the example page resources under page folder, and create your own custom pages. List existing pages with:

```
List folder content:
llt /home/$USER/rpitools/gpio/oled_128x64/lib/pages
or
ls -lath /home/$USER/rpitools/gpio/oled_128x64/lib/pages
```

## oled framework main features
* draw text
* draw shapes: ellipse, rectangle, line, poligon
* draw image
* automatic functions: header bar (optional), page bar (optional), button handling
* automatic button handling (physical and virtual over oledinterface)
* page control, load, run in loop, unload, next, previus etc...

![page_welcome](https://github.com/BxNxM/rpitools/blob/master/template/demo_images/page_pi.jpg?raw=true)
![weather](https://github.com/BxNxM/rpitools/blob/master/template/demo_images/weather_page.jpg?raw=true)
![weather](https://github.com/BxNxM/rpitools/blob/master/template/demo_images/page_perf.jpg?raw=true)

## performance with default setting (medium)
RaspberryPi Zero W - get service CPU usage (average)

```
while true; do cpu=$(ps aux | grep -v grep | grep "oled_gui_core" | awk '{print $3}') && echo -ne "oledfw: $cpu %\r"; done
```

On MEDIUM performance set:

```
CPU LOAD: 25 % - 35 %
CPU if oled in STANDBY: 2.3 %
```

## GIT
***push repo:*** git push -u origin master
