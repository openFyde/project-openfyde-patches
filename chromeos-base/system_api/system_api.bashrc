#!/bin/bash

cros_pre_src_prepare_private_fydeos_patches() {
  if [ "${PV}" == "9999" ]; then
    return
  fi
  eapply -p2 "${OPENFYDE_PATCHES_BASHRC_FILESDIR}"/dual-boot-dbus-constants.patch
}
