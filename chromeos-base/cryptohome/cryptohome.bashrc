# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_pre_src_prepare_openfyde_patches() {
  if ! use upper_case_product_uuid; then
    eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/prevent_product_uuid_uppercase_convert.patch
  fi
  eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/use_insecure_system_key_for_tpm2_simualtor_deprecated_compitable.patch
}
