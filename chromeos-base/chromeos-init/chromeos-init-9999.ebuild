# Copyright 2011 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_INCREMENTAL_BUILD=1
# TODO(crbug.com/809389): Avoid #include-ing platform2 headers directly.
CROS_WORKON_SUBTREE="common-mk dlcservice imageloader init libcrossystem libhwsec-foundation libstorage metrics .gn"

# Tests probe the root device.
PLATFORM_HOST_DEV_TEST="yes"
PLATFORM_SUBDIR="init"

inherit tmpfiles cros-workon platform user

DESCRIPTION="Upstart init scripts for Chromium OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/init/"
SRC_URI=""

LICENSE="BSD-Google"
SLOT="0/0"
KEYWORDS="~*"
IUSE="
	cros_embedded device-mapper direncryption disable_lvm_install +encrypted_stateful
	+encrypted_reboot_vault frecon fsverity lvm_migration lvm_stateful_partition default_key_stateful
	+oobe_config prjquota -s3halt +syslog systemd tpm tpm_dynamic tpm_insecure_fallback tpm2 tpm2_simulator
	+udev unibuild vivid vtconsole vtpm_proxy"

REQUIRED_USE="
	tpm_dynamic? ( tpm tpm2 )
	!tpm_dynamic? ( ?? ( tpm tpm2 ) )
	unibuild
	default_key_stateful? ( !lvm_stateful_partition !encrypted_stateful )
	lvm_stateful_partition? ( !default_key_stateful )
	encrypted_stateful? ( !default_key_stateful )
"

# secure-erase-file, vboot_reference, and rootdev are needed for clobber-state.
# re2 is needed for process_killer.
COMMON_DEPEND="
	chromeos-base/bootstat:=
	chromeos-base/dlcservice:=
	chromeos-base/imageloader-client:=
	chromeos-base/libcrossystem:=
	chromeos-base/libhwsec-foundation:=
	chromeos-base/libstorage:=
	>=chromeos-base/metrics-0.0.1-r3152:=
	chromeos-base/secure-erase-file:=
	chromeos-base/system_api:=
	chromeos-base/vboot_reference:=
	chromeos-base/vpd:=
	dev-cpp/abseil-cpp:=
	dev-libs/openssl:=
	dev-libs/re2:=
	sys-apps/rootdev:=
	sys-libs/libselinux:=
"

DEPEND="${COMMON_DEPEND}
	test? (
		dev-util/shflags
		sys-apps/diffutils
	)
"

RDEPEND="${COMMON_DEPEND}
	acct-group/bpf-access
	app-arch/tar
	app-misc/jq
	!chromeos-base/chromeos-disableecho
	chromeos-base/chromeos-common-script
	chromeos-base/chromeos-config
	lvm_migration? ( chromeos-base/thinpool_migrator )
	chromeos-base/tty
	oobe_config? ( chromeos-base/oobe_config )
	sys-apps/upstart
	!systemd? ( sys-apps/systemd-utils )
	sys-process/lsof
	virtual/chromeos-bootcomplete
	!cros_embedded? (
		chromeos-base/common-assets
		chromeos-base/chromeos-storage-info
		chromeos-base/swap_management
		sys-fs/e2fsprogs
	)
	frecon? (
		sys-apps/frecon
	)
"

platform_pkg_test() {
	local shell_tests=(
		tests/chromeos-disk-metrics-test.sh
		tests/send-kernel-errors-test.sh
	)

	local test_bin
	for test_bin in "${shell_tests[@]}"; do
		platform_test "run" "./${test_bin}"
	done

	platform test_all
}

src_install_upstart() {
	insinto /etc/init
	into /  # We want /sbin, not /usr/sbin, etc.

	if use cros_embedded; then
		doins upstart/startup.conf
		dotmpfiles tmpfiles.d/chromeos.conf
		doins upstart/embedded-init/boot-services.conf

		doins upstart/report-boot-complete.conf
		doins upstart/failsafe-delay.conf upstart/failsafe.conf
		doins upstart/pre-shutdown.conf upstart/pre-startup.conf
		doins upstart/pstore.conf upstart/reboot.conf
		doins upstart/system-services.conf
		doins upstart/uinput.conf
		doins upstart/sysrq-init.conf

		if use syslog; then
			doins upstart/collect-early-logs.conf
			doins upstart/log-rotate.conf upstart/syslog.conf
			dotmpfiles tmpfiles.d/syslog.conf
		fi
		if use !systemd; then
			doins upstart/cgroups.conf
			doins upstart/dbus.conf
			dotmpfiles tmpfiles.d/dbus.conf
			if use udev; then
				doins upstart/udev*.conf
			fi
		fi
		if use frecon; then
			doins upstart/boot-splash.conf
		fi
	else
		doins upstart/*.conf
		dotmpfiles tmpfiles.d/*.conf

		dosbin chromeos-disk-metrics
		dosbin chromeos-send-kernel-errors
		dosbin display_low_battery_alert
	fi

	if use s3halt; then
		newins upstart/halt/s3halt.conf halt.conf
	else
		doins upstart/halt/halt.conf
	fi

	if use vivid; then
		doins upstart/vivid/vivid.conf
	fi

	use vtconsole && doins upstart/vtconsole/*.conf
}

src_install() {
	platform_src_install

	insinto /usr/share/cros
	doins ./*_utils.sh

	# Install Upstart scripts.
	src_install_upstart

	insinto /usr/share/cros
	doins $(usex encrypted_stateful encrypted_stateful \
		unencrypted_stateful)/startup_utils.sh
}

pkg_preinst() {
	# Add the syslog user
	enewuser syslog
	enewgroup syslog

	# Create debugfs-access user and group, which is needed by the
	# chromeos_startup script to mount /sys/kernel/debug.  This is needed
	# by bootstat and ureadahead.
	enewuser "debugfs-access"
	enewgroup "debugfs-access"

	# Create pstore-access group.
	enewgroup pstore-access
}
