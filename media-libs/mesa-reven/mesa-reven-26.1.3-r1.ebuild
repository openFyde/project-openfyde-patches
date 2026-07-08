# Copyright 1999-2019 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# openfyde "reven"/slim Mesa, bumped to 26.1.3 so it ships the DRI driver
# interface (driCreateNewScreen3()/dri_*(), mesa_interface.h) that the Mesa 25+
# minigbm DRI loader (media-libs/minigbm patch 002) links against. Modelled on
# media-libs/mesa-amd; keeps the broad reven gallium driver set.
#   video_cards_llvmpipe -> swrast              video_cards_radeon   -> r300 r600
#   video_cards_intel    -> crocus (gen4-7)     video_cards_amdgpu   -> radeonsi + RADV
#   video_cards_iris     -> iris   (gen8+)      video_cards_virgl    -> virgl
#   video_cards_nouveau  -> nouveau             video_cards_vmware   -> svga
# zink is always built (minigbm's KOPPER/zink loader path dlopens it).
EAPI=7

CROS_WORKON_COMMIT="6984e91b5fe1d1c204e54954a4282fcdc0c44b78"
CROS_WORKON_TREE="4410d8c151d9b163f8929bf66d675ff72415e807"
CROS_WORKON_PROJECT="chromiumos/third_party/mesa"
CROS_WORKON_LOCALNAME="mesa-amd"
CROS_WORKON_EGIT_BRANCH="upstream/26.1.3"

inherit flag-o-matic meson cros-workon

DESCRIPTION="The Mesa 3D Graphics Library"
HOMEPAGE="http://mesa3d.org/"

# Rust crates pulled in by NVK's NAK compiler; only needed when building the
# nouveau Vulkan driver. Staged into meson's subproject packagecache in
# src_unpack so the build stays offline.
CRATE_URIS="
	https://crates.io/api/v1/crates/paste/1.0.14/download -> paste-1.0.14.crate
	https://crates.io/api/v1/crates/proc-macro2/1.0.86/download -> proc-macro2-1.0.86.crate
	https://crates.io/api/v1/crates/quote/1.0.35/download -> quote-1.0.35.crate
	https://crates.io/api/v1/crates/rustc-hash/2.1.1/download -> rustc-hash-2.1.1.crate
	https://crates.io/api/v1/crates/syn/2.0.87/download -> syn-2.0.87.crate
	https://crates.io/api/v1/crates/unicode-ident/1.0.12/download -> unicode-ident-1.0.12.crate
"
SRC_URI="video_cards_nouveau? ( vulkan? ( ${CRATE_URIS} ) )"

LICENSE="MIT LGPL-3 SGI-B-2.0"
SLOT="0"
KEYWORDS="*"

VIDEO_CARDS="amdgpu intel iris llvmpipe nouveau radeon virgl vmware"
for card in ${VIDEO_CARDS}; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS}
	debug +dri +egl gbm gles1 +gles2 kvm_guest libglvnd +shared-glapi
	+vaapi vulkan vkms +zstd"

COMMON_DEPEND="
	dev-libs/expat:=
	sys-libs/zlib:=
	x11-libs/libdrm:=
	dev-util/spirv-tools
	zstd? ( app-arch/zstd )
	vaapi? ( x11-libs/libva:= )
	libglvnd? ( media-libs/libglvnd )
	!libglvnd? ( !media-libs/libglvnd )
	video_cards_amdgpu? ( virtual/libelf:= )
	video_cards_llvmpipe? ( virtual/libelf:= )
	!media-libs/mesa
"

RDEPEND="${COMMON_DEPEND}"

DEPEND="${COMMON_DEPEND}
	dev-libs/libxml2:=
	x11-base/xorg-proto:=
	video_cards_amdgpu? ( sys-devel/llvm:18 )
	video_cards_llvmpipe? ( sys-devel/llvm:18 )
"

BDEPEND="
	sys-devel/bison
	sys-devel/flex
	virtual/pkgconfig
	video_cards_intel? ( dev-util/mesa_clc )
	video_cards_iris? ( dev-util/mesa_clc )
	video_cards_nouveau? (
		dev-util/mesa_clc
		vulkan? (
			dev-util/bindgen
			dev-util/cbindgen
			virtual/rust
		)
	)
"

# Join the arguments with commas (for meson's *-drivers / video-codecs lists).
_mesa_commas() { local IFS=','; echo "$*"; }

# Vulkan driver names built for the current VIDEO_CARDS (empty if -vulkan).
# iris (gen8+) -> ANV "intel"; crocus (gen4-7.5) -> legacy "intel_hasvk".
_mesa_vulkan_drivers() {
	use vulkan || return 0
	local drivers=()
	use video_cards_iris    && drivers+=( intel )
	use video_cards_intel   && drivers+=( intel_hasvk )
	use video_cards_amdgpu  && drivers+=( amd )
	use video_cards_nouveau && drivers+=( nouveau )
	echo "${drivers[@]}"
}

# Gallium driver names built for the current VIDEO_CARDS. Used by both
# src_configure (-Dgallium-drivers) and src_install (dri/*.so symlinks).
_mesa_gallium_drivers() {
	local drivers=()
	# zink is GL-on-Vulkan; it dlopens a Vulkan ICD at runtime, so only build it
	# when we also build a Vulkan driver for it to sit on (e.g. not the svga-only
	# vmware config, which has no Vulkan driver).
	[[ -n "$(_mesa_vulkan_drivers)" ]] && drivers+=( zink )
	use video_cards_llvmpipe && drivers+=( swrast )
	use video_cards_intel    && drivers+=( crocus )
	use video_cards_iris     && drivers+=( iris )
	use video_cards_nouveau  && drivers+=( nouveau )
	use video_cards_radeon   && drivers+=( r300 r600 )
	use video_cards_amdgpu   && drivers+=( radeonsi )
	use video_cards_virgl    && drivers+=( virgl )
	use video_cards_vmware   && drivers+=( svga )
	echo "${drivers[@]}"
}

# True when any gallium driver here needs LLVM (radeonsi or llvmpipe/swrast).
_mesa_needs_llvm() {
	use video_cards_amdgpu || use video_cards_llvmpipe
}

src_prepare() {
	default

	# VMware/SVGA-only fixes (merged from the former project-vmware mesa-reven):
	# force the draw-framebuffer target for ANGLE, and map R8G8B8A8_UNORM as an
	# SVGA screen-target format. Only relevant when the svga driver is built.
	if use video_cards_vmware; then
		eapply "${FILESDIR}"/angle_draw.patch
		eapply "${FILESDIR}"/svga_format_v20.patch
	fi
}

src_unpack() {
	cros-workon_src_unpack

	# Stage the NVK/NAK Rust crates into meson's subproject package cache
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
	cros_optimize_package_for_speed

	local gallium_drivers=( $(_mesa_gallium_drivers) )
	local vulkan_drivers=( $(_mesa_vulkan_drivers) )

	emesonargs+=(
		$(meson_use libglvnd glvnd)
		-Dshader-cache-default=false
		-Dglx=disabled
		-Dplatforms=
		$(meson_feature egl)
		$(meson_feature gbm)
		$(meson_feature gles1)
		$(meson_feature gles2)
		$(meson_feature zstd)
		-Ddisplay-info=disabled
		-Dgallium-drivers=$(_mesa_commas "${gallium_drivers[@]}")
		-Dvulkan-drivers=$(_mesa_commas "${vulkan_drivers[@]}")
		--buildtype $(usex debug debug release)
		-Db_ndebug=$(usex debug false true)
	)

	# radeonsi and llvmpipe/swrast need LLVM; nothing else here does.
	if _mesa_needs_llvm; then
		export LLVM_CONFIG="${SYSROOT}/usr/lib/llvm/bin/llvm-config-host"
		emesonargs+=( -Dllvm=enabled -Dshared-llvm=disabled )
	else
		emesonargs+=( -Dllvm=disabled )
	fi

	# intel (crocus/iris) and nouveau compile internal OpenCL-C shaders with the
	# host mesa_clc tool (dev-util/mesa_clc).
	if use video_cards_intel || use video_cards_iris || use video_cards_nouveau; then
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

	# VA-API decode/encode. radeonsi (VCN) does decode + encode including AV1;
	# nouveau's fixed-function VP/VDEC does legacy decode only.
	if use vaapi && { use video_cards_amdgpu || use video_cards_nouveau; }; then
		local codecs=( mpeg12dec vc1dec h264dec h265dec vp9dec )
		use video_cards_amdgpu && codecs+=( jpegdec av1dec h264enc h265enc av1enc )
		emesonargs+=(
			-Dgallium-va=enabled
			-Dva-libs-path="/usr/$(get_libdir)/va/drivers"
			-Dvideo-codecs=$(_mesa_commas "${codecs[@]}")
		)
	else
		emesonargs+=( -Dgallium-va=disabled )
	fi

	# Intel ray tracing (grl) is not needed for the ChromeOS compositor.
	{ use video_cards_intel || use video_cards_iris; } && [[ "${ABI:-amd64}" == amd64 ]] &&
		emesonargs+=( -Dintel-rt=disabled )

	# Crostini/VM guests load DRI modules from the container path.
	use kvm_guest && emesonargs+=( -Ddri-search-path=/opt/google/cros-containers/lib )

	meson_src_configure
}

src_install() {
	meson_src_install

	# Megadriver + loader symlinks. libgallium is versioned; point the DRI
	# loaders and the GL/GLAPI stubs at it. Meson does not create the per-driver
	# dri/*.so symlinks in this config.
	local libdir="/usr/$(get_libdir)"
	dosym libgallium-${PV}.so "${libdir}"/libgallium_dri.so
	dosym libgallium-${PV}.so "${libdir}"/libglapi.so

	_dri_link() { dosym ../libgallium-${PV}.so "${libdir}"/dri/"$1"_dri.so; }
	[[ -n "$(_mesa_vulkan_drivers)" ]] && _dri_link zink
	use video_cards_llvmpipe && { _dri_link swrast; _dri_link kms_swrast; }
	use video_cards_intel    && _dri_link crocus
	use video_cards_iris     && _dri_link iris
	use video_cards_nouveau  && _dri_link nouveau
	use video_cards_radeon   && { _dri_link r300; _dri_link r600; }
	use video_cards_amdgpu   && _dri_link radeonsi
	use video_cards_virgl    && _dri_link virgl
	use video_cards_vmware   && _dri_link svga

	# Keep the driver-interface headers that minigbm's DRI loader needs;
	# upstream Mesa does not install these. Drop mesa's GL/GLES/EGL headers so
	# they do not collide with media-libs/libglvnd.
	rm -v -rf "${ED}"/usr/include/GL/*.h
	rm -v -rf "${ED}"/usr/include/{EGL,GLES2,GLES3,KHR}
	insinto /usr/include
	doins "${S}"/src/gallium/include/mesa_interface.h
	doins "${S}"/include/kopper_interface.h

	# driconf: force-enable S3TC on the legacy Intel drivers.
	insinto /etc
	doins "${FILESDIR}"/drirc

	# VM boards use vkms for display output; load kms-swrast instead of swrast.
	if use vkms; then
		insinto /usr/share/drirc.d
		doins "${FILESDIR}"/01-vkms.conf
	fi
}
