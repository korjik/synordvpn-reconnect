#!/bin/bash

curr_ip=$(curl -s --max-time 10 https://ifconfig.io)
home_ip=$(curl -s --interface eth0 https://ifconfig.io)

if [[ "${curr_ip}" == "${home_ip}" ]]; 
  /volume1/\@appstore/DownloadStation/scripts/S25download.sh stop > /dev/null
fi
