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

  eapply -p2 ${FILESDIR}/keep_dlc_factory_image_and_remove_encrypted_block_for_clobber.patch
  eapply -p2 ${FILESDIR}/powerwash_keep_dev_image_and_var_ovarlay.patch
  eapply -p2 ${FILESDIR}/remove_files_in_oem_partition_for_remote_powerwash.patch

  if ! use upper_case_product_uuid; then
    eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/tpm/prevent_product_uuid_uppercase_convert.patch
  fi
  if use tpm2_simulator_deprecated; then
    eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/tpm/use_insecure_system_key_for_tpm2_simualtor_deprecated_compitable.patch
  fi
}

cros_post_src_install_openfyde_patches() {
	insinto /usr/share/chromeos-assets
	doins ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/splash_background
}
