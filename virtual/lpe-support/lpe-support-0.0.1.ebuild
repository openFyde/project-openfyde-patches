# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=4

DESCRIPTION="Ebuild which pulls in any necessary ebuilds as dependencies
or portage actions."

SLOT="0"
KEYWORDS="-* amd64 x86"
S="${WORKDIR}"
IUSE="skl_lpe apl_lpe kbl_lpe cnl_lpe glk_lpe"
# Add dependencies on other ebuilds from within this board overlay
RDEPEND="
	apl_lpe? ( sys-kernel/linux-firmware[linux_firmware_adsp_apl] )
	cnl_lpe? ( sys-kernel/linux-firmware[linux_firmware_adsp_cnl] )
	glk_lpe? ( sys-kernel/linux-firmware[linux_firmware_adsp_glk] )
	kbl_lpe? ( sys-kernel/linux-firmware[linux_firmware_adsp_kbl] )
  media-libs/lpe-support-topology
	skl_lpe? ( sys-kernel/linux-firmware[linux_firmware_adsp_skl] )
"
DEPEND="${RDEPEND}"
