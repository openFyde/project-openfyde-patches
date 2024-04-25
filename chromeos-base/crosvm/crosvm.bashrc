cros_pre_src_prepare_openfyde_patches() {
  if [[ "${PV}" != "9999" ]]; then
    eapply -p1 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/001-add-support-pipe-file-as-serial-input.patch
  fi
}
