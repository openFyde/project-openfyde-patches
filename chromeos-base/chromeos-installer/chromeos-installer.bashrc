# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_post_src_install_openfyde_mark_clean_overlay() {
  exeinto /usr/sbin
  doexe ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/mark_clean_overlay.sh
}

cros_pre_src_prepare_openfyde_patches() {
  eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/postinst.patch
}
