# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="ea4ece04cb84d426c1ddf1b6a06dd5ba22115871"
CROS_WORKON_TREE="17601aed7b4648a91a61c5a5ef433fc3af341264"
CROS_WORKON_PROJECT="chromiumos/platform/vpd"
CROS_WORKON_LOCALNAME="platform/vpd"

inherit cros-workon systemd

DESCRIPTION="ChromeOS vital product data utilities"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform/vpd/"
SRC_URI=""

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="static systemd"

# util-linux is for libuuid.
DEPEND="sys-apps/util-linux:="
# shflags for dump_vpd_log.
# chromeos-activate-date for ActivateDate upstart and script.
RDEPEND="
	sys-apps/flashrom
	dev-util/shflags
	virtual/chromeos-activate-date
	"
VPD_TEMPLATE="oem_licence.tmp"
src_compile() {
	tc-export CC
	use static && append-ldflags -static
	emake all
  cat ${VPD_TEMPLATE} | gzip > "vpd.gz"
}

src_install() {
	# This target list should be architecture specific
	# (no ACPI stuff on ARM for instance)
	dosbin vpd vpd_s
	dosbin util/check_rw_vpd util/dump_vpd_log util/update_rw_vpd
	dosbin util/vpd_get_value util/vpd_icc

	# install the init script
	if use systemd; then
		systemd_dounit init/vpd-log.service
		systemd_enable_service boot-services.target vpd-log.service
	else
		insinto /etc/init
		doins init/check-rw-vpd.conf
		doins init/vpd-icc.conf
		doins init/vpd-log.conf
    doins ${FILESDIR}/check_serial_number.conf
	fi
  insinto /usr/share/cros/init
  doins vpd.gz
  doins ${FILESDIR}/check_serial_number.sh
}

src_test() {
	if ! use x86 && ! use amd64; then
		ewarn "Skipping unittests for non-x86 arches"
		return
	fi
	emake test
}

src_prepare() {
  default
  eapply ${FILESDIR}/*.patch
  cp ${FILESDIR}/${VPD_TEMPLATE} ${S}
}
