# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_pre_src_prepare_openfyde_patches() {
  epatch ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/ignore_errors.patch
}