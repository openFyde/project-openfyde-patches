# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic toolchain-funcs

DESCRIPTION="GPT partition table manipulator for Linux"
HOMEPAGE="https://www.rodsbooks.com/gdisk/"
SRC_URI="mirror://sourceforge/${PN}/${PN}/${PV}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~loong ~mips ppc ppc64 ~riscv sparc x86 ~amd64-linux ~x86-linux"
IUSE="ncurses static"

# libuuid from util-linux is required.
RDEPEND="!static? (
		dev-libs/popt
		ncurses? ( sys-libs/ncurses:=[unicode(+)] )
		kernel_linux? ( sys-apps/util-linux )
	)"
DEPEND="
	${RDEPEND}
	static? (
		dev-libs/popt[static-libs(+)]
		ncurses? ( sys-libs/ncurses:=[unicode(+),static-libs(+)] )
		kernel_linux? ( sys-apps/util-linux[static-libs(+)] )
	)
	virtual/pkgconfig
"

PATCHES=(
	"${FILESDIR}/${PN}-1.0.9-libuuid.patch" #844073
	"${FILESDIR}/${PN}-1.0.9-popt_segv.patch" #872131
	"${FILESDIR}"/${PN}-1.0.9-musl-1.2.4.patch
)

src_prepare() {
	default

	tc-export CXX PKG_CONFIG

	if ! use ncurses ; then
		sed -i \
			-e '/^all:/s: cgdisk::' \
			Makefile || die
	fi

	sed \
		-e '/g++/s:=:?=:g' \
		-e 's:-lncursesw:$(shell $(PKG_CONFIG) --libs ncursesw):g' \
		-i Makefile || die

	use static && append-ldflags -static
}

src_install() {
	dosbin gdisk sgdisk $(usex ncurses cgdisk '') fixparts
	doman *.8
	dodoc NEWS README
}
