#!/bin/bash

curr_ip=$(curl -s --max-time 10 https://ifconfig.io)
home_ip=$(curl -s --interface eth0 https://ifconfig.io)

if [[ "${curr_ip}" == "${home_ip}" ]]; then 
  echo 'VPN is not working.'

  /volume1/\@appstore/DownloadStation/scripts/S25download.sh stop > /dev/null
  if [[ $(ps aux | grep DownloadStation) ]]; then
    echo 'Warning: Download station is working! Was not able to shut it down.'
  else
    echo 'Download station is shut down.'
  fi
  exit 456
fi
