cros_post_src_install_openfyde_patches() {
  if [ $PV == "9999" ]; then
    return
  fi

  if use tpm2_simulator_deprecated; then
    insinto /etc/init
    newins ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/init/lockbox-cache.conf.tpm2_simulator_deprecated lockbox-cache.conf
    exeinto /usr/share/cros/init
    newexe ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/init/lockbox-cache.sh.tpm2_simulator_deprecated lockbox-cache.sh
   fi
}
