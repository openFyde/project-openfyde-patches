# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

CROS_WORKON_PROJECT="chromiumos/third_party/virglrenderer"
CROS_WORKON_EGIT_BRANCH="main"

# Prevent automatic uprevs of this package since upstream is out of our control.
CROS_WORKON_MANUAL_UPREV="1"

PYTHON_COMPAT=( python3_11 )
inherit cros-fuzzer cros-sanitizers eutils flag-o-matic meson cros-workon python-any-r1

DESCRIPTION="library used implement a virtual 3D GPU used by qemu"
HOMEPAGE="https://virgil3d.github.io/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~*"
IUSE="debug fuzzer profiling test virtgpu_native_context vulkan"

# We need scudo for Venus render server to enable GWP-ASan
RDEPEND="
	chromeos-base/percetto
	>=x11-libs/libdrm-2.4.50
	media-libs/libepoxy
	media-libs/minigbm
	fuzzer? (
		virtual/opengles
	)
	vulkan? (
		media-libs/vulkan-loader
		virtual/vulkan-icd
		!fuzzer? ( sys-libs/scudo )
	)
"
# We need autoconf-archive for @CODE_COVERAGE_RULES@. #568624
DEPEND="${RDEPEND}
	sys-devel/autoconf-archive
	x11-drivers/opengles-headers
	fuzzer? ( >=dev-libs/check-0.9.4 )
	test? ( >=dev-libs/check-0.9.4 )
	vulkan? ( dev-util/vulkan-headers )
"

BDEPEND="
	virtual/pkgconfig
	$(python_gen_any_dep '
		dev-python/pyyaml[${PYTHON_USEDEP}]
	')
"

PATCHES=(
	"${FILESDIR}"/0001-vrend-disable-GL_EXT_external_object_fd-path-on-GLES.patch
	"${FILESDIR}"/0002-vrend-clear-stale-GL-errors-before-multisample-caps-.patch
)

python_check_deps() {
	python_has_version -b \
		"dev-python/pyyaml[${PYTHON_USEDEP}]"
}

pkg_setup() {
	python-any-r1_pkg_setup
}

src_prepare() {
	default
}

src_configure() {
	sanitizers-setup-env

	# Use meson's default optimization level for each buildtype. This is `-O0` for
	# `USE=debug`, and `-O3` otherwise. Per go/cr-os, the `-O3` is desirable, given
	# the hotness of this package.
	#
	# To placate monitoring that files bugs when hot ebuilds aren't optimized for
	# speed, mention the following:
	# cros_optimize_package_for_speed
	filter-flags -O?

	# flto flag added under condition due to llvm open issue
	# https://github.com/llvm/llvm-project/issues/57944
	#
	# avoid appending -flto overwrite if thinlto is used
	if ! use fuzzer && ! use thinlto; then
		append-flags -flto
	fi

	if use profiling; then
		append-flags -fprofile-instr-generate -fcoverage-mapping
		append-ldflags -fprofile-instr-generate -fcoverage-mapping
	fi

	emesonargs+=(
		-Dtracing=percetto
		-Dminigbm_allocation="true"
		-Dplatforms="egl"
		-Dcheck-gl-errors="false"
		$(meson_use fuzzer)
		--buildtype $(usex debug debug release)
	)

	if use virtgpu_native_context; then
		emesonargs+=( -Ddrm-renderers="msm" )
	fi

	if use vulkan; then
		emesonargs+=(
			-Dvenus="true"
			-Drender-server-worker="process"
		)
	fi

	# virgl_fuzzer is only built with tests.
	if use test || use fuzzer; then
		emesonargs+=( -Dtests="true" )
	fi

	meson_src_configure
}

src_install() {
	meson_src_install

	local fuzzer_component_id="964076"
	fuzzer_install "${FILESDIR}/fuzzer-OWNERS" \
		"${WORKDIR}/${P}-build"/tests/fuzzer/virgl_fuzzer \
		--options "${FILESDIR}/virgl_fuzzer.options" \
		--comp "${fuzzer_component_id}"
	fuzzer_install "${FILESDIR}/fuzzer-OWNERS" \
		"${WORKDIR}/${P}-build"/vtest/vtest_fuzzer \
		--options "${FILESDIR}/vtest_fuzzer.options" \
		--comp "${fuzzer_component_id}"

	find "${ED}"/usr -name 'lib*.la' -delete
}
