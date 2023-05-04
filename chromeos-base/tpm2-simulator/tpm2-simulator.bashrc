# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_pre_src_prepare_openfyde_patches() {
  if use arm; then
    eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/tpm2-simulator-0.0.1-fix-arm-policy.patch
  fi

  if use arm64; then
    eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/tpm2-simulator-0.0.1-fix-arm64-policy.patch
  fi
}
