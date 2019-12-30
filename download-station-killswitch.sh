#!/bin/bash

function checkds {
  ps axu | grep 'DownloadStation download' | grep -v grep
}

if [[ $(checkds) ]]; then
  curr_ip=$(curl -s --max-time 10 https://ifconfig.io)
  home_ip=$(curl -s --interface eth0 https://ifconfig.io)

  if [[ "${curr_ip}" == "${home_ip}" ]]; then 
    echo -e 'VPN is not working.\nShutting down Download station...'
    
    /volume1/\@appstore/DownloadStation/scripts/S25download.sh stop > /dev/null
	sleep 3
    if [[ $(checkds) ]]; then
      echo 'Warning: Download station is working! Was not able to shut it down.'
    else
      echo 'Download station is shut down.'
    fi
    exit 456
  fi
fi
