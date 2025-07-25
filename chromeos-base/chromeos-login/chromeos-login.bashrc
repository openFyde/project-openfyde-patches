# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_pre_src_prepare_openfyde_patches() {
  if [ "${PV}" == "9999" ]; then
    return
  fi
  eapply  ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/arc_sideload.patch
  eapply  ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/login_manager_ui_pre_start.patch
  eapply  ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/write-machine-info-get-serial_number-by-vpd-first.patch
  eapply  ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/login_manager_default_wallpaper_png_format.patch
  eapply  ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/login_manager_add_dynamic_default_wallpaper_flag.patch

  eapply  ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/mount_widevine.patch
  eapply  ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/apply-chrome-dev-flags-in-base-mode.patch

  eapply -p2 "${OPENFYDE_PATCHES_BASHRC_FILESDIR}"/init_scripts_write_fydeos_license_id_to_machine_info_file.patch
  eapply -p2 "${OPENFYDE_PATCHES_BASHRC_FILESDIR}"/add_fyde_basic_license_device_flag.patch
}
