cros_pre_src_prepare_openfyde_patches() {
  if [ $PV == "9999" ]; then
    return
  fi
  if use tpm2_simulator_deprecated; then
    eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/patches/contain_tpm_simulator_handle.patch
  fi
}

cros_post_src_install_openfyde_patches() {
  if [ $PV == "9999" ]; then
    return
  fi
  insinto /etc/init
  if use tpm2_simulator_deprecated; then
    newins ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/trunksd.conf.tpm2_simulator trunksd.conf
  fi
}
