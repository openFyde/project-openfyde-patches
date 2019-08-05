# Copyright (c) 2011 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="5"
CROS_WORKON_COMMIT="d78631ed69dfb70cd913c8686cce32084c232cbc"
CROS_WORKON_TREE=("7c2672e7fd88678931ee5c3ebbcc5e20699264c1" "6c0403a4e6d03bb70e3a027aa9dce3372039ee19" "4b46a612f38c049072fb2356f8b1d2110d211b10" "dc1506ef7c8cfd2c5ffd1809dac05596ec18773c")
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_INCREMENTAL_BUILD=1
# TODO(crbug.com/809389): Avoid #include-ing platform2 headers directly.
CROS_WORKON_SUBTREE="common-mk init metrics .gn"

PLATFORM_NATIVE_TEST="yes"
PLATFORM_SUBDIR="init"

inherit cros-workon platform user

DESCRIPTION="Upstart init scripts for Chromium OS"
HOMEPAGE="http://www.chromium.org/"
SRC_URI=""

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="
	cros_embedded +debugd +encrypted_stateful frecon
	kernel-3_8 kernel-3_10 kernel-3_14 kernel-3_18 +midi
	-s3halt +syslog systemd +udev vivid vtconsole fydeos_factory_install fixcgroup"

# shunit2 should be a dependency only if USE=test, but cros_run_unit_test
# doesn't calculate dependencies when emerging packages.
# secure-erase-file, vboot_reference, and rootdev are needed for clobber-state.
DEPEND="chromeos-base/libbrillo
	chromeos-base/metrics
	chromeos-base/secure-erase-file
	chromeos-base/vboot_reference
	dev-util/shunit2
	sys-apps/rootdev
"

RDEPEND="${DEPEND}
	app-arch/tar
	app-misc/jq
	chromeos-base/bootstat
	!chromeos-base/chromeos-disableecho
	chromeos-base/chromeos-common-script
	chromeos-base/tty
	sys-apps/upstart
	sys-process/lsof
	virtual/chromeos-bootcomplete
	!cros_embedded? (
		chromeos-base/common-assets
		chromeos-base/chromeos-storage-info
		chromeos-base/swap-init
		sys-fs/e2fsprogs
	)
	frecon? (
		sys-apps/frecon
	)
	test? (
		sys-process/psmisc
	)
"

platform_pkg_test() {
	local shell_tests=(
		periodic_scheduler_unittest
		killers_unittest
		tests/chromeos-disk-metrics-test.sh
		tests/send-kernel-errors-test.sh
	)

	local test_bin
	for test_bin in "${shell_tests[@]}"; do
		platform_test "run" "./${test_bin}"
	done

	local cpp_tests=(
		clobber_state_test
		file_attrs_cleaner_test
		usermode-helper_test
	)

	for test_bin in "${cpp_tests[@]}"; do
		platform_test "run" "${OUT}/${test_bin}"
	done
}

src_install_upstart() {
	insinto /etc/init

	if use cros_embedded; then
		doins upstart/startup.conf
		doins upstart/embedded-init/boot-services.conf

		doins upstart/report-boot-complete.conf
		doins upstart/failsafe-delay.conf upstart/failsafe.conf
		doins upstart/pre-shutdown.conf upstart/pre-startup.conf
		doins upstart/pstore.conf upstart/reboot.conf
		doins upstart/system-services.conf
		doins upstart/uinput.conf

		if use syslog; then
			doins upstart/log-rotate.conf upstart/syslog.conf upstart/journald.conf
		fi
		if use !systemd; then
      if use fixcgroup; then
        doins ${FILESDIR}/cgroups.conf
      else
			 doins upstart/cgroups.conf
      fi
			doins upstart/dbus.conf
			if use udev; then
				doins upstart/udev.conf upstart/udev-trigger.conf
				doins upstart/udev-trigger-early.conf
			fi
		fi
		if use frecon; then
			doins upstart/boot-splash.conf
		fi
	else
		doins upstart/*.conf

		dosbin chromeos-disk-metrics
		dosbin chromeos-send-kernel-errors
		dosbin display_low_battery_alert
	fi

	if ! use debugd; then
		sed -i '/^env PSTORE_GROUP=/s:=.*:=root:' \
			"${D}/etc/init/pstore.conf" || \
			die "Failed to replace PSTORE_GROUP in pstore.conf"
	fi

	if use midi; then
		if use kernel-3_8 || use kernel-3_10 || use kernel-3_14 || use kernel-3_18; then
			doins upstart/workaround-init/midi-workaround.conf
		fi
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
	# Install helper to run periodic tasks.
	dobin periodic_scheduler

	if use syslog; then
		# Install log cleaning script and run it daily.
		dosbin chromeos-cleanup-logs

		insinto /etc
		doins rsyslog.chromeos
	fi

	insinto /usr/share/cros
	doins *_utils.sh

	exeinto /usr/share/cros/init
	doexe is_feature_enabled.sh

	into /	# We want /sbin, not /usr/sbin, etc.

	# Install various utility files.
	dosbin killers

	# Install various helper programs.
	dosbin "${OUT}"/static_node_tool
	dosbin "${OUT}"/net_poll_tool
	dosbin "${OUT}"/file_attrs_cleaner_tool
	dosbin "${OUT}"/usermode-helper

	# Install startup/shutdown scripts.
	dosbin chromeos_startup chromeos_shutdown

	dosbin "${OUT}"/clobber-state

	dosbin clobber-log
	dosbin chromeos-boot-alert

	# Install Upstart scripts.
	src_install_upstart

	insinto /usr/share/cros
	doins $(usex encrypted_stateful encrypted_stateful \
		unencrypted_stateful)/startup_utils.sh
  if use fydeos_factory_install; then
    doins ${FILESDIR}/fydeos_factory_install.sh
    insinto /usr/share/chromeos-assets/text/boot_messages
    doins -r ${FILESDIR}/zh-CN
    doins -r ${FILESDIR}/en
  fi
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
}

src_prepare() {
  if use fydeos_factory_install; then
    epatch ${FILESDIR}/insert_factory_install_script.patch 
    epatch ${FILESDIR}/set_default_language_to_zh.patch
  fi
}
