# Copyright (c) 2025 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.
#
cros_pre_src_prepare_openfyde_patches() {
  if [[ "$PV" == "9999" ]]; then
    return
  fi
  eapply "${OPENFYDE_PATCHES_BASHRC_FILESDIR}"/display_boot_message_background_color_black.patch
}
