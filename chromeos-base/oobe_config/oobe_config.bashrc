# Copyright (c) 2024 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_pre_src_prepare_openfyde_patches() {
  if [ $PV == "9999" ]; then
    return
  fi
  if use reven_oobe_config; then
    eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/change_flex_config_path_to_oem_partition.patch
  fi

  if ! use amd64; then
    eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/remove_seccomp_policy_for_arm.patch
  fi
}
