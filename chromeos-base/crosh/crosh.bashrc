# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_pre_src_prepare_openfyde_patches() {
  eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/001_crosh_intro.patch
  eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/002_remove_unused_sudo_info.patch
}
