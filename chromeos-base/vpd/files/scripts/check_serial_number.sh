#!/usr/bin/env bash

declare -r OEM_PATH=/usr/share/oem
declare -r LICENCE=${OEM_PATH}/.oem_licence

declare -r NET_NODE=/sys/class/net
declare -r LAN_MAC_NODE=$NET_NODE/eth0/address
declare -r WLAN_MAC_NODE=$NET_NODE/wlan0/address

declare -r ZTE_CONF_FILE="$OEM_PATH/flex_config/config.json"

# this file should be deleted on every boot
declare -r FINISHED_MARKER=/var/run/check_serial_number.finished

die() {
  logger -t "${UPSTART_JOB}" "Error:" "$@"
  exit 1
}

info() {
  logger -t "${UPSTART_JOB}" "$@"
}

get_system_mac() {
  local mac

  # On the first boot, the upstart service machine-info which will call this script starts so early
  # that the NIC drivers may not even loaded, so it failed to get a mac address. This is to workaround
  # that issue, by keep trying for about 1min until get one. This does not impact subsequential boots
  # as the mac is stored.
  for i in $(seq 20); do
    if [ -e $LAN_MAC_NODE ]; then
      mac=$(cat $LAN_MAC_NODE)
    elif [ -e $WLAN_MAC_NODE ]; then
      mac=$(cat $WLAN_MAC_NODE)
    else
      mac=$(ifconfig -a | awk '/ether/ {print $2;exit}')
    fi

    if [ -n "$mac" ]; then
      echo "$mac"
      break
    fi

    info "Cannot get mac, maybe NIC driver is not ready yet, waiting to retry $i times"
    sleep 1s
  done
}

get_serial_number() {
  local sn=""
  sn=$(get_system_mac | sed "s/://g")
  echo "$sn"
}

# serial_number_helper.sh contains the function get_seirl_number
# shellcheck source=/dev/null
[[ -f /usr/share/cros/init/serial_number_helper.sh ]] && source "/usr/share/cros/init/serial_number_helper.sh"

is_booting_from_usb() {
  udevadm info "$(rootdev -d)" | grep ID_BUS |grep -q usb
}

remount_oem_writable() {
  mount -o remount,rw "$OEM_PATH"
}

remount_oem_readonly() {
  mount -o remount,ro "$OEM_PATH"
}

dump_vpd() {
  dump_vpd_log --force
}

update_serial_number() {
  local serial=$1
  remount_oem_writable || die "Remount OEM partition failed"
  vpd -i RO_VPD -s "serial_number=${serial}"
  remount_oem_readonly

  dump_vpd
}

check_vpd() {
  if [[ ! -s "${LICENCE}" ]]; then
    remount_oem_writable || die "Remount OEM partition failed"
    gzip -d -c /usr/share/cros/init/vpd.gz > ${LICENCE}
  fi
}

should_block() {
  true
}

update_serial_number_if_necessary() {
  local serial=""
  if [[ $# -eq 1 ]]; then
    serial=$1
  else
    serial=$(vpd -i RO_VPD -g serial_number 2>/dev/null)
  fi
  local new_sn=""
  new_sn=$(get_serial_number)
  if [ -z "$new_sn" ]; then
    exit 1
  fi
  if [ "$serial" != "$new_sn" ]; then
    update_serial_number "$new_sn"
  fi
}

main() {
  if [[ -f "$FINISHED_MARKER" ]]; then
    return 0
  fi
  check_vpd || die "Cann't init vpd system"
  if should_block; then
    local serial=""
    serial=$(vpd -i RO_VPD -g serial_number 2>/dev/null)
    if [[ -n "$serial" ]]; then
      info "serial number exists, running in background, update if necessary"
      update_serial_number_if_necessary "$serial" &
    else
      info "Trying to get serial number and update if necessary, running in block mode"
      update_serial_number_if_necessary "$serial"
    fi
  else
    # will not reach here, if should_block always return true
    info "Trying to get serial number and update if necessary, running in background"
    update_serial_number_if_necessary &
  fi

  touch "$FINISHED_MARKER"
}

main "$@"
