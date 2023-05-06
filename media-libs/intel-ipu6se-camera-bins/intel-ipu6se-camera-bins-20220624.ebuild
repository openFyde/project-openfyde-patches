# Copyright 2021 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Proprietary binaries for IPU6SE on Intel JSL platforms"
SRC_URI="https://github.com/intel/ipu6-camera-bins/archive/Chrome_jsl_${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD-Intel+patent-grant"
SLOT="0"
KEYWORDS="-* amd64"

RDEPEND="
	!media-libs/intel-ipu6se-libs-bin
	!media-libs/ipu6se-firmware
"

S="${WORKDIR}/../distdir"

src_install() {
    insinto usr/share/
    newins ${P}.tar.gz ${PN}.tar.gz

    insinto "/etc/init"
    doins ${FILESDIR}/fix-camera-for-jsl.conf

    exeinto "/usr/sbin"
    doexe ${FILESDIR}/fix-intel-ipu6se-camera.sh
}
