cros_pre_src_prepare_openfyde_patches_minigbm() {
  if [ ${PV} == 9999 ]; then
    return
  fi
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/001-fix-DRI-FORMAT.patch
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/002-rewrite-amdgpu-dri-loader-for-mesa25-zink.patch
}
