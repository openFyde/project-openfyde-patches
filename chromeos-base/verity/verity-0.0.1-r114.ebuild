# Copyright (c) 2012 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

CROS_WORKON_COMMIT="393cd4d510256b0bb2bdd0acd9656105cfd28771"
CROS_WORKON_TREE="1f77ce9d4bf7400f3d5f5a5f42698fee57abbd6d"
CROS_WORKON_PROJECT="chromiumos/platform/dm-verity"
CROS_WORKON_OUTOFTREE_BUILD=1

inherit cros-workon cros-common.mk

DESCRIPTION="File system integrity image generator for Chromium OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform/dm-verity"

LICENSE="BSD-Google GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="test"

RDEPEND=""
DEPEND="${RDEPEND}
	test? (
		dev-cpp/gtest:=
	)"

src_install() {
	dolib.a "${OUT}"/libdm-bht.a
	insinto /usr/include/verity
	doins dm-bht.h dm-bht-userspace.h
	insinto /usr/include/verity
	cd include
	doins -r linux asm asm-generic crypto
	cd ..
	into /
	dobin "${OUT}"/verity
}
