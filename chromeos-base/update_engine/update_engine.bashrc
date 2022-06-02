# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_pre_src_prepare_openfyde_patches() {
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/001-update_engine_fydeos.patch
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/002-bypass_should_ignore_update_fp_check.patch

  # skip_removable patch from r96 was removed here
  # if more patches needed by specified overlay(board), define a new hook with
  # different name in the overlay itself, then load from profile.bashrc of the
  # overlay
}
