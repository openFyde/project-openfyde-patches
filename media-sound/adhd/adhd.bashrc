# Copyright (c) 2023 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_pre_src_prepare_openfyde_patches() {
  eapply -p1 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/adhd.patch
}
