#!/bin/bash

connection_ip=($SSH_CLIENT)
host_ip=${connection_ip[0]}
if [[ $host_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
then
    echo -e "$host_ip"
    echo -e "$host_ip" > ~/.myip
else
    echo -e "$host_ip"
    echo -e "$host_ip" > ~/.mymac
fi
