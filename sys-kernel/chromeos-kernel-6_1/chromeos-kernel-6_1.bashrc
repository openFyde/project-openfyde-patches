cros_post_src_prepare_openfyde_patches() {
  if [ ${PV} == "9999" -o "${SKIP_OPENFYDE_KERNEL_PATCHES}" == "1" ]; then
    return
  fi
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/*.patch
}
