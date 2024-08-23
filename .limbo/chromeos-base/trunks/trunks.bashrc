cros_post_src_prepare_openfyde_patches() {
  if [ ${PV} == "9999" ]; then
    return
  fi
  if use tpm2_simulator; then
    eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/contain_tpm_simulator_handle.patch
  fi
}
