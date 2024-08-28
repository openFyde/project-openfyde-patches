# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_pre_src_prepare_openfyde_patches() {
  # the patch is not available in r126, and will cause a js error, end up with a blank page, so remove it for now
  # eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/001-prefer-to-use-navigator-language-for-i18n.patch
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/002-change-some-zh-CN-i18n-messages.patch
}
