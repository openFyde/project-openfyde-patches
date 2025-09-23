# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

apply_io_spcified_patches() {
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/007-change-kBandaidUrl.patch
}

cros_pre_src_prepare_openfyde_patches() {
  if [[ "$PV" = "9999" ]]; then
    return
  fi
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/001-update_engine_fydeos.patch
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/002-bypass_should_ignore_update_fp_check.patch
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/003-ota-checker.patch
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/004-local-ota.patch
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/005-set-is-official-build-false.patch
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/006-skip_SetFirstActiveOmahaPingSent_to_avoid_tons_of_vpd_errors.patch

  apply_io_spcified_patches

  # skip_removable patch from r96 was removed here
  # if more patches needed by specified overlay(board), define a new hook with
  # different name in the overlay itself, then load from profile.bashrc of the
  # overlay

}
