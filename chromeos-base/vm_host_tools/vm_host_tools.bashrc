# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_pre_src_prepare_openfyde_patches() {
  if [[ "${PV}" != "9999" ]]; then
    eapply -p1 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/borealis-skip-untrusted-vm-error.patch
    eapply -p1 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/disable_smt.patch
  fi
}

# cros_pre_src_prepare_openfyde_patches_fix_syntax_error() {
  # the syntax error still exists in r102
  # eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/r96_fix_vm_concierge_if_syntax_error.patch
# }
