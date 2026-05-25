cros_post_src_prepare_openfyde_patches() {
  if [ ${PV} == "9999" -o "${SKIP_OPENFYDE_KERNEL_PATCHES}" == "1" ]; then
    return
  fi
  for krn_patch in `ls ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/*.patch`; do
    eapply $krn_patch
  done
}
