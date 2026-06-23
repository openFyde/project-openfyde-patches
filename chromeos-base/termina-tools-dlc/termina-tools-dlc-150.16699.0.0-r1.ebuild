# Copyright 2022 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

# A DLC package for distributing vm tools for termina.

EAPI=7

inherit dlc cros-workon edo

# This ebuild is upreved via PuPR, so disable the normal uprev process for
# cros-workon ebuilds.
CROS_WORKON_MANUAL_UPREV="1"

# "cros_workon info" expects these variables to be set, but we don't have a git
# repo, so use the standard empty project.
CROS_WORKON_PROJECT="chromiumos/infra/build/empty-project"
CROS_WORKON_LOCALNAME="platform/empty-project"

DESCRIPTION="DLC package for vm tools for termina."

# FydeOS: r150 split termina into termina-dlc (vm_rootfs.img) and
# termina-tools-dlc (vm_tools.img + vm_kernel). Upstream termina-tools-dlc pulls
# Google's guest-vm-base from gs://termina-component-testing and is served via
# DLC_FORCE_OTA, which FydeOS has no backend for, so it fails verification and
# blocks termina setup. We instead reuse the SAME guest-vm-base tarball our
# termina-dlc fork already ships (it contains vm_tools.img + vm_kernel) and
# factory-install it like termina-dlc. No separate prebuilt is published.
if [[ ${PV} == 9999 ]]; then
	SRC_URI=""
else
  SRC_URI="
    amd64? (
      !fydeos_com? ( ${OPENFYDE_PREBUILT_PKGS_HOST_URL}/termina-dlc/termina-dlc-io-amd64-${PV}.tar.xz -> termina_io_amd64_fydeos_${PV}.tar.xz )
      fydeos_com? ( ${OPENFYDE_PREBUILT_PKGS_HOST_URL}/termina-dlc/termina-dlc-com-amd64-${PV}.tar.xz -> termina_com_amd64_fydeos_${PV}.tar.xz )
    )
    arm? (
      !fydeos_com? ( ${OPENFYDE_PREBUILT_PKGS_HOST_URL}/termina-dlc/termina-dlc-io-arm-${PV}.tar.xz -> termina_io_arm_fydeos_${PV}.tar.xz )
      fydeos_com? ( ${OPENFYDE_PREBUILT_PKGS_HOST_URL}/termina-dlc/termina-dlc-com-arm-${PV}.tar.xz -> termina_com_arm_fydeos_${PV}.tar.xz )
    )
    arm64? (
      !fydeos_com? ( ${OPENFYDE_PREBUILT_PKGS_HOST_URL}/termina-dlc/termina-dlc-io-arm-${PV}.tar.xz -> termina_io_arm_fydeos_${PV}.tar.xz )
      fydeos_com? ( ${OPENFYDE_PREBUILT_PKGS_HOST_URL}/termina-dlc/termina-dlc-com-arm-${PV}.tar.xz -> termina_com_arm_fydeos_${PV}.tar.xz )
    )
  "
fi

RESTRICT="mirror"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
S="${WORKDIR}"

IUSE="kvm_host dlc amd64 arm -fydeos_com"
REQUIRED_USE="
	dlc
	kvm_host
	^^ ( amd64 arm arm64 )
"

# Only vm_tools.img (~78 MiB) + vm_kernel (~13 MiB) ship here (~92 MiB total);
# the ~1.5 GiB vm_rootfs.img stays in termina-dlc. 200 MiB is a ~2x buffer.
# 1MiB = 256 x 4KiB blocks
DLC_PREALLOC_BLOCKS="$((200 * 256))"

DLC_PRELOAD=true
DLC_FORCE_OTA=false
DLC_FACTORY_INSTALL=true

# We need to inherit from cros-workon so people can do "cros-workon-${BOARD}
# start termina-tools-dlc", but we don't want to actually run any of the
# cros-workon steps, so we override pkg_setup and src_unpack with the default
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
		vm_board="tatl-fydeos"
	else
		vm_board="tael-fydeos"
	fi
	image_path="/mnt/host/source/src/build/images/${vm_board}/latest/chromiumos_test_image.bin"
	[[ ! -f "${image_path}" ]] && die "Couldn't find VM image at ${image_path}, try building a test image: cros build-image --board=${vm_board}"
	# Use the same subdir name (guest-vm-base) as termina-dlc.
	edo /mnt/host/source/src/platform/container-guest-tools/termina/termina_build_image.py "${image_path}" "${S}/guest-vm-base"
}

src_install() {
	# This is the subpath underneath the location that dlc mounts the image,
	# so we dont need additional directories.
	local install_dir="/"
	into "$(dlc_add_path ${install_dir})"
	insinto "$(dlc_add_path ${install_dir})"
	exeinto "$(dlc_add_path ${install_dir})"
	# Only install vm tools image and kernel; vm_rootfs.img ships in termina-dlc.
	doins "${WORKDIR}/guest-vm-base/vm_tools.img"
	doins "${WORKDIR}/guest-vm-base/vm_kernel"
	dlc_src_install
}
