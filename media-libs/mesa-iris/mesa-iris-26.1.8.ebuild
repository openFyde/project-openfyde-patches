# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# Latest Mesa for openfyde, with the enabled drivers selected by VIDEO_CARDS:
#   video_cards_intel    -> gallium iris   + Vulkan ANV
#   video_cards_radeonsi -> gallium radeonsi (LLVM) + Vulkan RADV + AMD VCN VA
#   video_cards_nouveau  -> gallium nouveau + Vulkan NVK + nouveau VP/VDEC VA
# zink is always built. Structure ported from Gentoo's media-libs/mesa-26.1.3
# (EAPI 7, surfaceless), with the openfyde megadriver/minigbm install fixups.
# It intentionally shadows the older chromiumos-overlay media-libs/mesa-iris.
# Kept at the same release as the Notialis guest's cros-mesa (project-notialis
# scripts/packages/cros-mesa), which builds from this same tarball.
EAPI=7

PYTHON_COMPAT=( python3_{8..11} )

inherit flag-o-matic meson python-any-r1 cros-sanitizers

MY_P="mesa-${PV/_/-}"

# Rust crates pulled in by NVK's NAK compiler (matches Gentoo mesa-26.1.3's
# CRATES list). Only needed when building the nouveau Vulkan driver. Mesa's
# meson looks these up as subproject wraps; we stage the fetched .crate files
# into subprojects/packagecache/ in src_unpack so the build stays offline.
CRATE_URIS="
	https://crates.io/api/v1/crates/paste/1.0.14/download -> paste-1.0.14.crate
	https://crates.io/api/v1/crates/proc-macro2/1.0.86/download -> proc-macro2-1.0.86.crate
	https://crates.io/api/v1/crates/quote/1.0.35/download -> quote-1.0.35.crate
	https://crates.io/api/v1/crates/rustc-hash/2.1.1/download -> rustc-hash-2.1.1.crate
	https://crates.io/api/v1/crates/syn/2.0.87/download -> syn-2.0.87.crate
	https://crates.io/api/v1/crates/unicode-ident/1.0.12/download -> unicode-ident-1.0.12.crate
"

DESCRIPTION="The Mesa 3D Graphics Library (Intel iris / AMD radeonsi / NVIDIA nouveau)"
HOMEPAGE="https://mesa3d.org/"
SRC_URI="https://archive.mesa3d.org/${MY_P}.tar.xz
	video_cards_nouveau? ( vulkan? ( ${CRATE_URIS} ) )"

# Most of the code is MIT/X11.
# GLES[2]/gl[2]{,ext,platform}.h are SGI-B-2.0
LICENSE="MIT SGI-B-2.0"
SLOT="0"
KEYWORDS="*"

IUSE_VIDEO_CARDS="video_cards_intel video_cards_nouveau video_cards_radeonsi"
IUSE="debug libglvnd +vaapi +vulkan +zstd ${IUSE_VIDEO_CARDS}"

COMMON_DEPEND="
	dev-libs/expat
	dev-util/spirv-tools
	libglvnd? ( media-libs/libglvnd )
	>=sys-libs/zlib-1.2.8
	>=x11-libs/libdrm-2.4.121
	virtual/libudev:=
	video_cards_radeonsi? ( virtual/libelf )
"

RDEPEND="${COMMON_DEPEND}
	!libglvnd? ( !media-libs/libglvnd )
	!media-libs/mesa
	zstd? ( app-arch/zstd )
	vulkan? ( video_cards_radeonsi? ( !media-libs/mesa-radv ) )
"

DEPEND="${COMMON_DEPEND}
	vaapi? ( x11-libs/libva )
	video_cards_radeonsi? ( sys-devel/llvm:18 )
"

BDEPEND="
	dev-util/glslang
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	video_cards_intel? ( dev-util/mesa_clc )
	video_cards_nouveau? (
		dev-util/mesa_clc
		vulkan? (
			dev-util/bindgen
			dev-util/cbindgen
			virtual/rust
		)
	)
	$(python_gen_any_dep '
		dev-python/mako[${PYTHON_USEDEP}]
		dev-python/packaging[${PYTHON_USEDEP}]
		dev-python/ply[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
	')
"

S="${WORKDIR}/${MY_P}"

# zink's begin_rendering() recurses without bound when an attachment shadow is
# populated from inside a u_blitter blit (mesa#14269, still open upstream).
# Same patch as the Notialis guest Mesa and fydroid's mesa 021.
PATCHES=( "${FILESDIR}"/zink-do-not-shadow-attachments-while-blitting.patch )

# Join the arguments with commas (for meson's *-drivers / video-codecs lists).
_mesa_commas() { local IFS=','; echo "$*"; }

python_check_deps() {
	python_has_version -b \
		"dev-python/mako[${PYTHON_USEDEP}]" \
		"dev-python/packaging[${PYTHON_USEDEP}]" \
		"dev-python/ply[${PYTHON_USEDEP}]" \
		"dev-python/pyyaml[${PYTHON_USEDEP}]"
}

pkg_setup() {
	python-any-r1_pkg_setup
}

src_unpack() {
	default

	# Stage the NVK/NAK Rust crates into the meson subproject package cache
	# (meson cannot be pointed at DISTDIR). Only present when building nouveau
	# Vulkan. Meson's wrap files expect <name>-<version>.tar.gz filenames.
	if use vulkan && use video_cards_nouveau; then
		mkdir -p "${S}"/subprojects/packagecache || die
		local i
		for i in "${DISTDIR}"/*.crate; do
			ln -s "${i}" "${S}/subprojects/packagecache/$(basename "${i%.crate}").tar.gz" || die
		done
	fi
}

src_configure() {
	sanitizers-setup-env
	cros_optimize_package_for_speed

	local gallium_drivers=( zink ) vulkan_drivers=()
	use video_cards_intel    && gallium_drivers+=( iris )
	use video_cards_radeonsi && gallium_drivers+=( radeonsi )
	use video_cards_nouveau  && gallium_drivers+=( nouveau )
	if use vulkan; then
		use video_cards_intel    && vulkan_drivers+=( intel )
		use video_cards_radeonsi && vulkan_drivers+=( amd )
		use video_cards_nouveau  && vulkan_drivers+=( nouveau )
	fi

	emesonargs+=(
		$(meson_use libglvnd glvnd)
		-Dshader-cache-default=false
		-Dglx=disabled
		-Dplatforms=
		-Degl=enabled
		-Dgbm=disabled
		-Dgles1=disabled
		-Dgles2=enabled
		$(meson_feature zstd)
		# Surfaceless ChromeOS build: no libdisplay-info / Vulkan WSI display.
		-Ddisplay-info=disabled
		-Dgallium-drivers=$(_mesa_commas "${gallium_drivers[@]}")
		-Dvulkan-drivers=$(_mesa_commas "${vulkan_drivers[@]}")
		--buildtype $(usex debug debug release)
		-Db_ndebug=$(usex debug false true)
	)

	# radeonsi's gallium driver needs LLVM; nothing else here does. RADV uses
	# its own ACO compiler, so Vulkan-only AMD would not need this.
	if use video_cards_radeonsi; then
		export LLVM_CONFIG="${SYSROOT}/usr/lib/llvm/bin/llvm-config-host"
		emesonargs+=( -Dllvm=enabled -Dshared-llvm=disabled )
	else
		emesonargs+=( -Dllvm=disabled )
	fi

	# intel and nouveau compile internal OpenCL-C shaders with the host
	# mesa_clc tool (dev-util/mesa_clc). radeonsi does not need it.
	if use video_cards_intel || use video_cards_nouveau; then
		emesonargs+=( -Dmesa-clc=system )
	fi

	# NVK (Vulkan nouveau) is written in Rust. CrOS's generated meson cross
	# file has no [binaries] rust entry, and the SDK's dev-rust/bindgen (0.63)
	# is too old (NVK needs >=0.71). Build host and board are the same arch
	# (x86_64), so use the native host rustc with the cros linker, and point
	# meson at the newer dev-util/bindgen (installed as bindgen-mesa).
	if use vulkan && use video_cards_nouveau; then
		cat > "${T}/cros-rust-cross.ini" <<-EOF || die
			[binaries]
			rust = ['rustc', '-C', 'linker=$(tc-getCC)']
			bindgen = '/usr/bin/bindgen-mesa'
		EOF
		emesonargs+=( --cross-file "${T}/cros-rust-cross.ini" )

		# bindgen drives libclang directly (not the cros compiler wrapper), so
		# it has no notion of the board sysroot and fails to find target
		# headers such as libdrm's xf86drm.h. Point clang at the sysroot.
		export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=${SYSROOT} -I${SYSROOT}/usr/include/libdrm"
	fi

	# VA-API decode. radeonsi (VCN) does decode + encode including AV1; the
	# classic nouveau gallium driver's fixed-function VP/VDEC does legacy
	# decode only. Intel video comes from the separate iHD driver, so gallium
	# VA is only useful for radeonsi/nouveau.
	if use vaapi && { use video_cards_radeonsi || use video_cards_nouveau; }; then
		local codecs=( mpeg12dec vc1dec h264dec h265dec vp9dec )
		use video_cards_radeonsi && codecs+=( jpegdec av1dec h264enc h265enc av1enc )
		emesonargs+=(
			-Dgallium-va=enabled
			-Dva-libs-path="/usr/$(get_libdir)/va/drivers"
			-Dvideo-codecs=$(_mesa_commas "${codecs[@]}")
		)
	else
		emesonargs+=( -Dgallium-va=disabled )
	fi

	# Intel ray tracing (grl) is not needed for the ChromeOS compositor.
	use video_cards_intel && [[ "${ABI:-amd64}" == amd64 ]] &&
		emesonargs+=( -Dintel-rt=disabled )

	meson_src_configure
}

src_install() {
	meson_src_install

	# Megadriver + loader symlinks, mirroring media-libs/mesa-amd on openfyde.
	# libgallium is versioned; point the DRI loaders and the GL/GLAPI stubs at
	# it. Meson does not create the per-driver dri/*.so symlinks in this config.
	dosym libgallium-${PV}.so /usr/$(get_libdir)/libgallium_dri.so
	dosym libgallium-${PV}.so /usr/$(get_libdir)/libglapi.so
	dosym ../libgallium-${PV}.so /usr/$(get_libdir)/dri/zink_dri.so
	use video_cards_intel &&
		dosym ../libgallium-${PV}.so /usr/$(get_libdir)/dri/iris_dri.so
	use video_cards_radeonsi &&
		dosym ../libgallium-${PV}.so /usr/$(get_libdir)/dri/radeonsi_dri.so
	use video_cards_nouveau &&
		dosym ../libgallium-${PV}.so /usr/$(get_libdir)/dri/nouveau_dri.so

	# Keep the driver-interface headers that minigbm's DRI loader needs;
	# upstream Mesa does not install these.
	rm -v -rf "${ED}"/usr/include/GL/*.h
	rm -v -rf "${ED}"/usr/include/{EGL,GLES2,GLES3,KHR}
	insinto /usr/include
	doins "${S}"/src/gallium/include/mesa_interface.h
	doins "${S}"/include/kopper_interface.h
}
