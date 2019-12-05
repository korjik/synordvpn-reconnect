#/bin/bash

function reconnect {

  client=$(grep -Eo 'o[0-9]+' /usr/syno/etc/synovpnclient/openvpn/ovpnclient.conf)
  name=$(grep 'conf_name' /usr/syno/etc/synovpnclient/openvpn/ovpnclient.conf | awk -F '=' '{print $2}')
  proto=$(grep '^proto\ ' /usr/syno/etc/synovpnclient/openvpn/client_${client} | awk '{print $2}')

  synovpnc get --name "${name}"
  synovpnc get_conn
  tail -30 /var/log/messages
  tail -100 /var/log/nordvpn.txt

  /volume1/@appstore/DownloadStation/scripts/S25download.sh stop

  synovpnc kill_client --name="${name}"

  until [[ $(synovpnc get_conn | grep 'No connection!!') ]]; do
    sleep 2
  done

  hostname=$(curl --silent --interface eth0 "https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_groups\]\[identifier\]=legacy_standard&filters\[servers_technologies\]\[identifier\]=openvpn_${proto}&limit=8" | jq -r --slurp '.[] | sort_by(.load) | limit(1;.[]) | .hostname');
  wget https://downloads.nordcdn.com/configs/files/ovpn_${proto}/servers/${hostname}.${proto}.ovpn

cat >>${hostname}.${proto}.ovpn<<END
up /usr/syno/etc.defaults/synovpnclient/scripts/ovpn-up
route-up /usr/syno/etc.defaults/synovpnclient/scripts/route-up
redirect-gateway
script-security 2
plugin /lib/openvpn/openvpn-down-root.so /usr/syno/etc.defaults/synovpnclient/scripts/ip-down
log-append /var/log/nordvpn.txt
END

mv ${hostname}.${proto}.ovpn /usr/syno/etc/synovpnclient/openvpn/client_${client} 

  cat >/usr/syno/etc/synovpnclient/vpnc_connecting <<END
conf_id=${client}
conf_name=${name}
proto=openvpn
END

  synovpnc connect --id=${client}

  echo "Current address: ${cur_ip} (timed out if empty)"
  echo "New Server: ${server}"

  /volume1/@appstore/DownloadStation/scripts/S25download.sh start >> /dev/null

  exit 123
}

curr_ip=$(curl -s --max-time 10 https://ifconfig.io)
home_ip=$(curl -s --interface eth0 https://ifconfig.io)

[[ "${curr_ip}" ]] \
  && [[ "${curr_ip}" != "${home_ip}" ]] \
  || reconnect