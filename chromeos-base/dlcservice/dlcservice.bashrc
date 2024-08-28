# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_pre_src_prepare_openfyde_patches() {
  if [ $PV == "9999" ]; then
    return
  fi
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/try_to_copy_dlc_image_from_inactive_slot.patch
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/do_not_remove_factory_install_path.patch
}
