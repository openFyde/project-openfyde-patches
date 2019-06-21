#!/bin/bash
INSTALL_TARGET_DEV=""
KERN_ARG="fydeos_factory_install"

log_install() {
  echo $@ >>/tmp/fydeos_factory_install.log
}

get_efi_dev() {
    /usr/bin/cgpt find -t efi $INSTALL_TARGET_DEV
}

mount_efi() {
  local mp=$1
  [ -d $mp ] || mkdir -p $mp
  mount $(get_efi_dev) $mp
}

fydeos_post_install() {
  local mp="/tmp/efi_mnt"
  local sp_str="$KERN_ARG=$INSTALL_TARGET_DEV"
  local grub_cfg="${mp}/efi/boot/grub.cfg"
  mount_efi $mp
  for cfg in $(find $mp -name \*.cfg);
  do
    sed -i "s#${sp_str}##g" $cfg
  done
  sed -i "s/timeout=2/timeout=0/g" $grub_cfg
  umount $mp
}

check_and_install() {
for karg in $(cat /proc/cmdline);
do
  log_install "\"${karg%%=*}\":\"${karg#*=}\""
  if [ -n "$(echo $karg | grep $KERN_ARG)" ]; then
    INSTALL_TARGET_DEV="${karg#*=}"
    log_install "find target disk information:$INSTALL_TARGET_DEV"
    break
  else
    log_install "$KERN_ARG:${karg%%=*}"
  fi
done
if [ -n "${INSTALL_TARGET_DEV}" ]; then
  log_install "command line flag detected:$INSTALL_TARGET_DRV"
  if [ -n "$(rootdev -d | grep $INSTALL_TARGET_DEV)" ]; then
  # system is running on target disk;
    return 0
  fi
  if [ ! -w "${INSTALL_TARGET_DEV}" ]; then
    log_install "can't find the target disk"
    display_boot_message fydeos_target_failure 'zh-CN en'
    read -n 1 man_input
    reboot
    exit 1
  fi
  chromeos-boot-alert update_firmware
  log_install "begin install"
  /usr/sbin/chromeos-install --dst ${INSTALL_TARGET_DEV} --yes >> /tmp/fydeos_factory_install.log
  log_install "end install"
  if [ $? -ne 0 ]; then
     log_install "error occured" 
     display_boot_message fydeos_install_failure 'zh-CN en'
     read -n 1 man_input
     reboot
     exit 1
  fi    
  fydeos_post_install 
  display_boot_message fydeos_install_success 'zh-CN en'
  sleep 3
  reboot
  exit 0
fi
}

log_install "check and install"
check_and_install
log_install "nothing happened"
