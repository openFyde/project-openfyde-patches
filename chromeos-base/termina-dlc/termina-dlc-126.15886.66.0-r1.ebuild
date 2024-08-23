# Copyright 2020 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

# A DLC package for distributing termina.

EAPI=7

inherit dlc cros-workon edo

# This ebuild is upreved via PuPR, so disable the normal uprev process for
# cros-workon ebuilds.
CROS_WORKON_MANUAL_UPREV="1"

# "cros_workon info" expects these variables to be set, but we don't have a git
# repo, so use the standard empty project.
CROS_WORKON_PROJECT="chromiumos/infra/build/empty-project"
CROS_WORKON_LOCALNAME="platform/empty-project"

DESCRIPTION="DLC package for termina."

if [[ ${PV} == 9999 ]]; then
	SRC_URI=""
else
	SRC_URI="
		amd64? ( gs://termina-component-testing/uprev-test/amd64/${PV}/guest-vm-base.tar.xz -> termina_amd64_${PV}.tar.xz )
		arm? ( gs://termina-component-testing/uprev-test/arm/${PV}/guest-vm-base.tar.xz -> termina_arm_${PV}.tar.xz )
		arm64? ( gs://termina-component-testing/uprev-test/arm/${PV}/guest-vm-base.tar.xz -> termina_arm_${PV}.tar.xz )
	"
fi

RESTRICT="mirror"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
S="${WORKDIR}"

IUSE="kvm_host dlc amd64 arm"
REQUIRED_USE="
	dlc
	kvm_host
	^^ ( amd64 arm arm64 )
"

# Termina now contains 2 copies of LXD, pulling the image size up to
# ~185 MiB. Test builds need extra space for test utilities.
#
# To check the current size, run "file" on a deployed DLC image. The
# output will tell you the size of the squashfs filesystem.
#
# 1MiB = 256 x 4KiB blocks
if [[ ${PV} == 9999 ]]; then
	DLC_PREALLOC_BLOCKS="$((250 * 256))"
else
	DLC_PREALLOC_BLOCKS="$((200 * 256))"
fi

DLC_PRELOAD=true
# Use the scaled infrastructure for serving DLC contents.
DLC_FORCE_OTA=true

# `termina-dlc` should be added to `chromite/lib/dlc_allowlist.py`
DLC_FACTORY_INSTALL=true

# We need to inherit from cros-workon so people can do "cros-workon-${BOARD}
# start termina-dlc", but we don't want to actually run any of the cros-workon
# steps, so we override pkg_setup and src_unpack with the default
# implementations.
pkg_setup() {
	return
}

src_unpack() {
	if [[ -n ${A} ]]; then
		# $A should be tokenised here as it may contain multiple files
		# shellcheck disable=SC2086
		unpack ${A}
	fi
}

src_compile() {
	if [[ ${PV} != 9999 ]]; then
		return
	fi
	if use amd64; then
		vm_board="tatl"
	else
		vm_board="tael"
	fi
	image_path="/mnt/host/source/src/build/images/${vm_board}/latest/chromiumos_test_image.bin"
	[[ ! -f "${image_path}" ]] && die "Couldn't find VM image at ${image_path}, try building a test image: cros build-image --board=${vm_board}"
	# Use the same subdir name (guest-vm-base) as infra/recipes/recipes/uprev_guest_vm_pin.py
	edo /mnt/host/source/src/platform/container-guest-tools/termina/termina_build_image.py "${image_path}" "${S}/guest-vm-base"
}

src_install() {
	# This is the subpath underneath the location that dlc mounts the image,
	# so we dont need additional directories.
	local install_dir="/"
	into "$(dlc_add_path ${install_dir})"
	insinto "$(dlc_add_path ${install_dir})"
	exeinto "$(dlc_add_path ${install_dir})"
	# about_os_credits.html is used by chrome://crostini-credits/
	doins "${WORKDIR}/guest-vm-base/about_os_credits.html"
	doins "${WORKDIR}/guest-vm-base/lsb-release"
	doins "${WORKDIR}/guest-vm-base/vm_kernel"
	doins "${WORKDIR}/guest-vm-base/vm_rootfs.img"
	doins "${WORKDIR}/guest-vm-base/vm_tools.img"
	dlc_src_install
}
