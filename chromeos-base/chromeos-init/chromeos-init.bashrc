cros_post_src_prepare_openfyde_patches() {
  if use fydeos_factory_install; then
    eapply ${FILESDIR}/insert_factory_install_script.patch
    eapply ${FILESDIR}/set_default_language_to_zh.patch
    if [ -n "${FYDEOS_FACTORY_INSTALL}" ]; then
      echo $FYDEOS_FACTORY_INSTALL > $FYDEOS_INSTALL_FILE
    fi
  fi
  if use fixcgroup; then
    eapply ${FILESDIR}/cgroups_cpuset.patch
  fi
  if use fixcgroup-memory; then
    eapply ${FILESDIR}/fix_cgroup_memory.patch
  fi
  if ! use kvm_host; then
    eapply ${FILESDIR}/remove_cgroup_crosvm.patch
  fi
  eapply ${FILESDIR}/skip_call_ExtendPCRForVersionAttestation.patch
}

cros_post_src_install_openfyde_patches() {
	insinto /usr/share/chromeos-assets
	doins ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/splash_background
}
