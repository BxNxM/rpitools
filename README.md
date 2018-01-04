# rpitools
git push -u origin master

###############################################################
######################## HOW TO USE ###########################
###############################################################
ON macOS/Linux:
---------------
git clone https://github.com/BxNxM/rpitools.git
cd rpitools/prepare_sd
cp ~/Downloads/*raspbian*.img raspbian_img/
./raspbian_imager.bash
./boot_config.bash
-> manually (wifi) setup /Volumes/boot/wpa_supplicant.conf file.

===============================================================
unmount SD card, tut it in to the rpi zero w
===============================================================

copy rpitools:
(ssh-keygen -R raspberrypi.local)
rm -f raspbian_img/*.img && scp -r ../../rpitools/ pi@raspberrypi.local:~/
(default pwd: raspberry)

then connect over ssh:
ssh pi@raspberrypi.local

ON RASPBIAN:
------------
cd rpitools/
source setup
(if you use raspbain lite, and you want a GUI)
./install_PIXEL.bash
(if you want remote desktop access)
./install_vnc.bash

manually setups with raspi-config:
set default login console/desktop
location
expand file system
screen resolution
set local name
