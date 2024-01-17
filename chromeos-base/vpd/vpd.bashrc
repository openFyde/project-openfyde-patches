# Copyright (c) 2023 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

VPD_TEMPLATE="oem_licence.tmp"
cros_pre_src_prepare_openfyde_patches() {
  eapply ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/*.patch
  cp ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/${VPD_TEMPLATE} ${S}
}

cros_pre_src_compile_openfyde_patches() {
  cat ${VPD_TEMPLATE} | gzip > "vpd.gz"
}

cros_post_src_install_openfyde_patches() {
	insinto /etc/init
  doins ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/check_serial_number.conf
  insinto /usr/share/cros/init
  doins vpd.gz
  doins ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/check_serial_number.sh
}
