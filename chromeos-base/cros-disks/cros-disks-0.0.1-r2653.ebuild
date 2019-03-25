# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=6
CROS_WORKON_COMMIT="ff6532b9bafea6c0b643a545303ef3b7e9352e1a"
CROS_WORKON_TREE=("310a710d6c1f02a93504b35b3d8371875f253b6a" "4e933a052414d62639f29a7e009d1ff4997549ea" "c459546a3fca6f1687b5b18184a715bfa9270731" "dc1506ef7c8cfd2c5ffd1809dac05596ec18773c")
CROS_WORKON_INCREMENTAL_BUILD="1"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk cros-disks metrics .gn"

PLATFORM_SUBDIR="cros-disks"

inherit cros-workon platform user

DESCRIPTION="Disk mounting daemon for Chromium OS"
HOMEPAGE="http://www.chromium.org/"
LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="asan chromeless_tty fuzzer +seccomp"

RDEPEND="
	app-arch/unrar
	chromeos-base/libbrillo
	chromeos-base/metrics
	chromeos-base/minijail
	chromeos-base/session_manager-client
	net-fs/sshfs
	sys-apps/rootdev
	sys-apps/util-linux
	sys-fs/avfs
	sys-fs/dosfstools
	sys-fs/exfat-utils
	sys-fs/fuse-exfat
	sys-fs/ntfs3g
	virtual/udev
"

DEPEND="${RDEPEND}
	chromeos-base/system_api"

pkg_preinst() {
	enewuser "cros-disks"
	enewgroup "cros-disks"

	enewuser "ntfs-3g"
	enewgroup "ntfs-3g"

	enewuser "avfs"
	enewgroup "avfs"

	enewuser "fuse-exfat"
	enewgroup "fuse-exfat"

	enewuser "fuse-sshfs"
	enewgroup "fuse-sshfs"

	enewuser "fuse-drivefs"
	enewgroup "fuse-drivefs"
}

src_prepare() {
    default
    epatch ${FILESDIR}/hide_unremovable_disk.patch    
}

src_install() {
	dobin "${OUT}"/cros-disks

	# Install USB device IDs file.
	insinto /usr/share/cros-disks
	doins usb-device-info

	# Install seccomp policy file.
	insinto /usr/share/policy
	use seccomp && newins avfsd-seccomp-${ARCH}.policy avfsd-seccomp.policy

	# Install upstart config file.
	insinto /etc/init
	doins cros-disks.conf
	# Insert the --no-session-manager flag if needed.
	if use chromeless_tty; then
		sed -i -E "s/(CROS_DISKS_OPTS=')/\1--no_session_manager /" "${D}"/etc/init/cros-disks.conf || die
	fi

	# Install D-Bus config file.
	insinto /etc/dbus-1/system.d
	doins org.chromium.CrosDisks.conf

	# Install setuid restrictions file.
	insinto /usr/share/cros/startup/process_management_policies
	doins setuid_restrictions/cros_disks_whitelist.txt

	local fuzzers=(
		mount_options_fuzzer
	)

	local fuzzer
	for fuzzer in "${fuzzers[@]}"; do
		platform_fuzzer_install "${S}"/OWNERS "${OUT}/${PN}_${fuzzer}"
	done
}

platform_pkg_test() {
	local gtest_filter_qemu_common=""
	gtest_filter_qemu_common+="DiskManagerTest.*"
	gtest_filter_qemu_common+=":ExternalMounterTest.*"
	gtest_filter_qemu_common+=":UdevDeviceTest.*"
	gtest_filter_qemu_common+=":MountInfoTest.RetrieveFromCurrentProcess"
	gtest_filter_qemu_common+=":GlibProcessTest.*"

	local gtest_filter_user_tests="-*.RunAsRoot*:"
	! use x86 && ! use amd64 && gtest_filter_user_tests+="${gtest_filter_qemu_common}"

	local gtest_filter_root_tests="*.RunAsRoot*-"
	! use x86 && ! use amd64 && gtest_filter_root_tests+="${gtest_filter_qemu_common}"

	platform_test "run" "${OUT}/disks_testrunner" "1" \
		"${gtest_filter_root_tests}"
	platform_test "run" "${OUT}/disks_testrunner" "0" \
		"${gtest_filter_user_tests}"
}
