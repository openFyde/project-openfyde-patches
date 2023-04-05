# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit linux-info systemd toolchain-funcs udev

MY_PN=${PN/_/-}
MY_P=${MY_PN}-${PV/_p*}
#DATA_VER=${PV/*_p}
DATA_VER="20191128"

DESCRIPTION="Tool for controlling 'flip flop' (multiple devices) USB gear like UMTS sticks"
HOMEPAGE="https://www.draisberghof.de/usb_modeswitch/ https://www.draisberghof.de/usb_modeswitch/device_reference.txt"
SRC_URI="https://www.draisberghof.de/${PN}/${MY_P}.tar.bz2"

S="${WORKDIR}/${MY_P}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm arm64 x86"
IUSE=""

RDEPEND="
	virtual/udev
	virtual/libusb:1
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

CONFIG_CHECK="~USB_SERIAL"

PATCHES=( "${FILESDIR}/usb_modeswitch.sh-tmpdir.patch"
          "${FILESDIR}/for-chromiumos.patch")

src_prepare() {
	default
	sed -i -e '/install.*BIN/s:-s::' Makefile || die
}

src_compile() {
	emake CC="$(tc-getCC)" PKG-CONFIG="$(tc-getPKG_CONFIG)"
}

src_install() {
    emake \
		DESTDIR="${D}" \
		install
}

pkg_postinst() {
	udev_reload
}

pkg_postrm() {
	udev_reload
}
