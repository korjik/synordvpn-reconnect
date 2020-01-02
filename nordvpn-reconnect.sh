#!/bin/bash

PREV_SERVER_FILE='/tmp/last-nordvpn-hostname'

function reconnect {

  client=$(grep -Eo 'o[0-9]+' /usr/syno/etc/synovpnclient/openvpn/ovpnclient.conf)
  name=$(grep 'conf_name' /usr/syno/etc/synovpnclient/openvpn/ovpnclient.conf | awk -F '=' '{print $2}')
  proto=$(grep '^proto\ ' /usr/syno/etc/synovpnclient/openvpn/client_${client} | awk '{print $2}')

  synovpnc get --name "${name}" | grep -v '\ \ Password'
  synovpnc get_conn 
  tail -30 /var/log/messages
  tail -100 /var/log/nordvpn.txt

  /volume1/\@appstore/DownloadStation/scripts/S25download.sh stop

  synovpnc kill_client --name="${name}"

  until [[ $(synovpnc get_conn | grep 'No connection!!') ]]; do
    sleep 2
  done
  
  [[ -f ${PREV_SERVER_FILE} && $(cat ${PREV_SERVER_FILE}) ]] && prev_hostname=$(tail -1 "${PREV_SERVER_FILE}") || prev_hostname='abcdef'
  hostname=$(curl --silent --interface eth0 "https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_groups\]\[identifier\]=legacy_standard&filters\[servers_technologies\]\[identifier\]=openvpn_${proto}&limit=8" \
    | jq --slurp -r ".[] | sort_by(.load) | .[].hostname" | grep -v "${prev_hostname}" | head -1)

  echo "${hostname}" > "${PREV_SERVER_FILE}"
  echo "Choosing server hostname: ${hostname}"
  wget https://downloads.nordcdn.com/configs/files/ovpn_${proto}/servers/${hostname}.${proto}.ovpn

cat >>${hostname}.${proto}.ovpn<<END
up /usr/syno/etc.defaults/synovpnclient/scripts/ovpn-up
route-up /usr/syno/etc.defaults/synovpnclient/scripts/route-up
redirect-gateway
script-security 2
plugin /lib/openvpn/openvpn-down-root.so /usr/syno/etc.defaults/synovpnclient/scripts/ip-down
log-append /var/log/nordvpn.txt
END

sed -i 's/auth-user-pass/auth-user-pass\ \/tmp\/ovpn_client_up/' ${hostname}.${proto}.ovpn
mv ${hostname}.${proto}.ovpn /usr/syno/etc/synovpnclient/openvpn/client_${client} 

address=$(grep '^remote\ ' /usr/syno/etc/synovpnclient/openvpn/client_${client} | awk '{print $2}')

  cat >/usr/syno/etc/synovpnclient/vpnc_connecting <<END
conf_id=${client}
conf_name=${name}
proto=openvpn
END

  sed -i "s/remote=.*/remote=${address}/" /usr/syno/etc/synovpnclient/openvpn/ovpnclient.conf

  synovpnc connect --id=${client}

  echo "Address before reconnect: ${curr_ip} (timed out if empty)"
  echo "New address: ${address}"

  curr_ip=$(curl -s --max-time 10 https://ifconfig.io)

  if [[ "${curr_ip}" != "${home_ip}" ]]; then
    /volume1/\@appstore/DownloadStation/scripts/S25download.sh start > /dev/null
  fi

  exit 123
}

curr_ip=$(curl -s --max-time 10 https://ifconfig.io)
home_ip=$(curl -s --interface eth0 https://ifconfig.io)

[[ "${curr_ip}" ]] \
  && [[ "${curr_ip}" != "${home_ip}" ]] \
  || reconnect
