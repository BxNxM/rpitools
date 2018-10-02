![logo](https://github.com/BxNxM/rpitools/blob/master/template/demo_images/rpitools_structure.png?raw=true)

```
  _____    _____    _____   _______    ____     ____    _         _____ 
 |  __ \  |  __ \  |_   _| |__   __|  / __ \   / __ \  | |       / ____|
 | |__) | | |__) |   | |      | |    | |  | | | |  | | | |      | (___  
 |  _  /  |  ___/    | |      | |    | |  | | | |  | | | |       \___ \ 
 | | \ \  | |       _| |_     | |    | |__| | | |__| | | |____   ____) |
 |_|  \_\ |_|      |_____|    |_|     \____/   \____/  |______| |_____/ 
```
## WHAT IS RPITOOLS [HomeCloud]?
* RPITOOLS is an installation and configuration (deployment) system for the raspberry pi (Zero, and 3). It deploys the official raspbain lite operating system and many useful programs, and set the complete system to a tiny playground and procreate your HomeCloud. 
* Completly set for remote usage - ssh, sshfs, sftp, smb, vnc(optional), website(http)
* Sets an optinal GUI (PIXEL) for graphical usage
* Supports a UNIQUE extension shiled with many periphery.
* LIST OF FUNCTIONS:
	* torrent client - transmission (with http client, port: 9091)
	* network drive - samba (smb)
	* OLED (128x64) display support on extension shield
	* extarnal ip deepnet clinet access (dropbox - external ip sync)
	* disks automount, and command line interface
	* git config
	* terminal/command line set for easy usage - aliases and so on
	* vim, xdotool, scrot, python (with many modules), kodi etc.
	* custom ```rpitools/autodeployment/config/rpitools_config.cfg``` user configuration based on ```rpitools/autodeployment/config/rpitools_config_template.cfg```
	* easy update: ```update_rpitools```

## How to install:
 
#### CONFIGURATION ON MAC & LINUX

***Deploy and setup raspbian image***

* ***macOS***: open terminal ```CMD+SPACE``` type ```Terminal``` press enter
* ***Linux***: open ```terminal``` and ```sudo apt-get install git```

* clone rpitools repository from github - to get the resources

```
git clone https://github.com/BxNxM/rpitools.git
```

* go to rpitools/

```
cd rpitools/
source setup

#### SETUP EXECUTION ####
* Detect the device | linux | mac | raspbian
* [linux | mac] install requirements on deployment side
  and set installation environment. 
* [raspbain] manage depoyment depends on your custom config
#########################
```
Follow the instructions.

## VIM - command line text editor

ESC MODE

```
:w			- type & enter - save the actual file
:q!     	- type & enter - exit without save
:wq			- type & enter - save and exit

jump end of the line: $
jump beginning of the line: 0 
```

INSERT MODE

```
move the cursor with the arrows [up - down - right - left]
SHIT + v	- type - select line
CTRL + v 	- type - select block
y			- type - copy selected area
x			- type - cut selected area
p			- type - paste copied area
```

## Deployment

* Execute deployment scripts:

```
./1_raspbian_imager.bash
###### DESCRIPTION ######
* It deploys (write) the factory raspbian_lite_latest image to the SD card.
(It serach your rapbian image from Downloads folder)
(If it not works copy your image under: rpitools/prepare/sd_card/raspbian_img)
#########################

./2_boot_config.bash
###### DESCRIPTION ######
* It makes an SD configuration, before the fisrt boot:
wifi, ssh, i2c, spi etc. based on previously set config file (rpitools_config.cfg)
#########################
```

* Unmount and disconnect the SD card from your computer. Take it to the pi, and power it up.
* Wait a little to boot up propely (max. 2-4 min.)

```
./3_remote_config_for_rpi_machine.bash
###### DESCRIPTION ######
* It copies all the rpitools repository to the raspberrypi
* Executes the rpitools/setup configuration sourcing
*** Based on your configuration (rpitools_config.cfg) it will prepare
your whole system.
* It takes 30-80 minutes (many installations and configurations with reboots)
#########################

./4_connect_and_enjoy.bash
###### DESCRIPTION ######
* FInally connect to your pi, and enjoy your NEW, PERSONAL environmat!
#########################
```

***WIRING***

######If you have our - offcial shild - just connect it to your raspberrypi.

#####RPITOOLS EXTENSION SHILED WIRING 1.0

![page_welcome](https://github.com/BxNxM/rpitools/blob/master/gpio/RPITOOLS_1.0_GPIO_PINOUT.png?raw=true)

***OLED BOOTUP LAUNCH SETUP - CONFIGURE A SERVICE (optional) [1]***

```
for more info:
oledinterface -h
```

* Use virtual buttons:

Oled dedicated buttons

```
oledinterface -b LEFT
oledinterface -b RIGHT
oledinterface -b OK
oledinterface -b standby

```
Oled page joystick buttons

```
oledinterface -j LEFT
oledinterface -j RIGHT
oledinterface -j CENTER
oledinterface -j UP
oledinterface -j DOWN
```

#### CUSTOMIZE OLED FRAMEWORK AND CREATE NEW PAGES (OPTIONAL)

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

![oled_pages_demo](https://github.com/BxNxM/rpitools/blob/master/template/demo_images/oledPagesDemo.png?raw=true)
![oled_pages_gif](https://github.com/BxNxM/rpitools/blob/master/template/demo_images/oledp.GIF?raw=true)
## performance with default settings (medium)
RaspberryPi Zero W - get service CPU usage (average)

```
while true; do cpu=$(ps aux | grep -v grep | grep "oled_gui_core" | awk '{print $3}') && echo -ne "oledfw: $cpu %\r"; done
```

On MEDIUM performance set:

```
CPU LOAD: 25 % - 35 %
CPU if oled in STANDBY: 2.3 %
```

# BUILT IN KODI
```                            
  _  __   ____    _____    _____ 
 | |/ /  / __ \  |  __ \  |_   _|
 | ' /  | |  | | | |  | |   | |  
 |  <   | |  | | | |  | |   | |  
 | . \  | |__| | | |__| |  _| |_ 
 |_|\_\  \____/  |_____/  |_____|
                                           
``` 

***use hardware optimized media player for 720p and 180p videos***

```
run in command line:
kodibg
```

It gives you a full media player with many options. 
The video output goes to the dedicated HDMI connector.


# RGB interface
```
                 _       _           _                    __                       
                | |     (_)         | |                  / _|                      
  _ __    __ _  | |__    _   _ __   | |_    ___   _ __  | |_    __ _    ___    ___ 
 | '__|  / _` | | '_ \  | | | '_ \  | __|  / _ \ | '__| |  _|  / _` |  / __|  / _ \
 | |    | (_| | | |_) | | | | | | | | |_  |  __/ | |    | |   | (_| | | (__  |  __/
 |_|     \__, | |_.__/  |_| |_| |_|  \__|  \___| |_|    |_|    \__,_|  \___|  \___|
          __/ |                                                                    
         |___/                                                                     
```
To controll connected rgb leds.

* start rgb service - it controlls the leds - and process requests

```
rgbinterface -s ON
```

* turn on the leds

```
rgbinterface -l ON
```

* set colors

```
rgbinterface -r 0 -g 0 -b 0
rgbinterface -r 100 -g 100 -b 100

# color ranges: 0-100, min. step 1
```

* turn off the leds

```
rgbinterface -l OFF
```

* turn off the service

```
rgbinterface -s OFF
```
You don't have to turn off the service, it can runs in the background, so you can send data for it over rgbinterface and it makes the magic ;)

* show rgb leds service status

```
rgbinterface -sh
```

* interface help for informations

```
rgbinterface -h
```

# HAPTIC-ENGINE interface
```
  _    _              _____    _______   _____    _____   ______   _   _    _____   _____   _   _   ______ 
 | |  | |     /\     |  __ \  |__   __| |_   _|  / ____| |  ____| | \ | |  / ____| |_   _| | \ | | |  ____|
 | |__| |    /  \    | |__) |    | |      | |   | |      | |__    |  \| | | |  __    | |   |  \| | | |__   
 |  __  |   / /\ \   |  ___/     | |      | |   | |      |  __|   | . ` | | | |_ |   | |   | . ` | |  __|  
 | |  | |  / ____ \  | |         | |     _| |_  | |____  | |____  | |\  | | |__| |  _| |_  | |\  | | |____ 
 |_|  |_| /_/    \_\ |_|         |_|    |_____|  \_____| |______| |_| \_|  \_____| |_____| |_| \_| |______|
                                                                                                           
                                                                                                           
hapticengingeinterface -h

optional arguments:
  -h, --help        show this help message and exit
  -u, --up          HapticEngine UP signel
  -d, --down        HapticEngine DOWN signel
  -s, --soft        HapticEngine SOFT signel
  -t, --tap         HapticEngine TAP signel
  -dt, --doubletap  HapticEngine DoubleTAP signel
  -sn, --snooze     HapticEngine SNOOZE signel
```

# Your website
You have a custom website, with protected files web folder - like custom dropbox (cloud) on a private drive at home.
Get your internal or extarnal ip address and copy-paste it to your browser.

```
get your ip address on the pi:
sysmonitor -g
```

![website_1.0](https://github.com/BxNxM/rpitools/blob/master/template/demo_images/website1.0.png?raw=true)
![websiteAllDemo](https://github.com/BxNxM/rpitools/blob/master/template/demo_images/webpageDemoAll.png?raw=true)

# Useful links for basics
* RaspberryPi GPIO usage:

```
 https://sourceforge.net/p/raspberry-gpio-python/wiki/BasicUsage/
```

* GPIO pinout

```
https://pinout.xyz/pinout/pin1_3v3_power
```

* Download raspbian image (my project use the light version)

```
https://www.raspberrypi.org/downloads/raspbian/
```

* Raspbain image installation - manual - Windows / Mac / Linux

```
https://www.raspberrypi.org/documentation/installation/installing-images/
```

* My favourite raspberry pi order site (not sponsored - yet :P)

```
https://thepihut.com/products/raspberry-pi-zero-essential-kit
```

* Format disks

```
https://www.raspberrypi.org/forums/viewtopic.php?t=38429
```

* Useful - command line - commands collection

```
http://www.circuitbasics.com/useful-raspberry-pi-commands/
```

* Backup / Restore SDCard

```
https://thepihut.com/blogs/raspberry-pi-tutorials/17789160-backing-up-and-restoring-your-raspberry-pis-sd-card
http://bobbyromeo.com/technology/backup-clone-raspberry-pi-sd-card/
```

* Password protected apache folder setup

```
https://www.cyberciti.biz/faq/howto-setup-apache-password-protect-directory-with-htaccess-file/
```

* Other usefull commands in the system

```
Get Kernel modules load state (spi, i2c)
systemctl status systemd-modules-load.service
```

* Convert pdf to html

```
http://www.pdfonline.com/convert-pdf-to-html/
```

* Set crontab for programs time based execution

```
* * * * * command to be executed
- - - - -
| | | | |
| | | | ----- Day of week (0 - 7) (Sunday=0 or 7)
| | | ------- Month (1 - 12)
| | --------- Day of month (1 - 31)
| ----------- Hour (0 - 23)
------------- Minute (0 - 59)

crontab -e
crontab -l

https://www.cyberciti.biz/faq/how-do-i-add-jobs-to-cron-under-linux-or-unix-oses/
```

* Image convert (convert howtogeek.png -quality 95 howtogeek.jpg)

```
https://www.howtogeek.com/109369/how-to-quickly-resize-convert-modify-images-from-the-linux-terminal/
```

* NFS howto

```
https://www.htpcguides.com/configure-nfs-server-and-nfs-client-raspberry-pi/
```

* Terminal colors

```
https://misc.flogisoft.com/bash/tip_colors_and_formatting
```

* ASCII ART

```
http://patorjk.com/software/taag/#p=display&h=0&f=Big&t=RPITOOLS%0A
```

* DynamicDNS - duck DNS

```
https://www.duckdns.org
```

## GIT
***push repo:*** git push -u origin master
