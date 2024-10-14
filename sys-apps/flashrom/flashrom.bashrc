cros_pre_src_prepare_openfyde_skip_running_cli() {
  if [ ${PV} != "9999" ]; then
    eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/001-bypass-cli-to-speed-up-booting.patch
  fi
}
