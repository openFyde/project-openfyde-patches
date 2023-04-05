# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI=7

EGIT_REPO_URI="https://salsa.debian.org/debian/usb-modeswitch-data.git"
#EGIT_COMMIT="62ef131011c4b3ef01f3932076e5cb3c0f075f27"

inherit git-r3 udev

KEYWORDS="amd64 arm arm64 x86"
LICENSE="Apache-2.0"
LICENSE="GPL-2"
SLOT="0"
IUSE=""

RDEPEND="sys-apps/usb-modeswitch"

DEPEND="${RDEPEND}"

src_install() {
        emake \
		DESTDIR="${D}" \
		RULESDIR="${D}/${EPREFIX}$(get_udevdir)/rules.d" \
		files-install db-install
}
