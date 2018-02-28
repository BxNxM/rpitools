#!/bin/bash

echo -e "\n=======================  RPITOOLS INFORMATIONS =============================="
echo -e "ssh pi@raspberrypi.local"
echo -e "[!] Firt reneme your pi with: sudo raspy-config"
echo -e "WARNING - After rename your raspberry pi, this script will not work!"
echo -e "=======================  RPITOOLS INFORMATIONS ==============================\n"
sleep 3
ssh pi@raspberrypi.local
