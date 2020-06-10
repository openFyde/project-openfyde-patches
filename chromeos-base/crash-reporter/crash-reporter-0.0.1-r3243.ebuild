# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="a0f172755fa87b358d1f913f3f898d8d9a25e001"
CROS_WORKON_TREE=("dea48af07754556aac092c0830de0b1ab410077b" "fb0800ce12bfcbafea51e96bdbf923152ebe419a" "c218b19793213fbc08daad20dce926cf44766c10" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk crash-reporter metrics .gn"

PLATFORM_SUBDIR="crash-reporter"

inherit cros-i686 cros-workon platform systemd udev user

DESCRIPTION="Crash reporting service that uploads crash reports with debug information"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/crash-reporter/"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="cheets chromeless_tty cros_embedded -direncryption kvm_guest systemd fuzzer"

COMMON_DEPEND="
	chromeos-base/minijail:=
	chromeos-base/google-breakpad:=[cros_i686?]
	chromeos-base/metrics:=
	dev-libs/libpcre:=
	dev-libs/protobuf:=
	dev-libs/re2:=
	kvm_guest? ( net-libs/grpc:= )
	net-misc/curl:=
	sys-libs/zlib:=
"
RDEPEND="${COMMON_DEPEND}
	chromeos-base/chromeos-ca-certificates
	|| ( sys-apps/journald:= sys-apps/systemd:= )
	direncryption? ( sys-apps/keyutils:= )
"
DEPEND="
	${COMMON_DEPEND}
	chromeos-base/debugd-client:=
	chromeos-base/session_manager-client:=
	chromeos-base/shill-client:=
	chromeos-base/system_api:=[fuzzer?]
	chromeos-base/vboot_reference:=
	chromeos-base/vm_protos:=
"

src_configure() {
	platform_src_configure
	use cheets && use_i686 && platform_src_configure_i686
}

src_compile() {
	platform_src_compile
	use cheets && use_i686 && platform_src_compile_i686 "core_collector"
}

pkg_setup() {
	# Has to be done in pkg_setup() instead of pkg_preinst() since
	# src_install() will need the crash user and group.
	enewuser "crash"
	enewgroup "crash"
	# A group to manage file permissions for files that crash reporter
	# components need to access.
	enewgroup "crash-access"
	# A group to grant access to the user's crash directory (in /home)
	enewgroup "crash-user-access"
	cros-workon_pkg_setup
}

src_install() {
	into /
	dosbin "${OUT}"/crash_reporter
	dosbin "${OUT}"/crash_sender

	insinto /etc/dbus-1/system.d
	doins dbus/org.chromium.AnomalyEventService.conf

	local daemon_store="/etc/daemon-store/crash"
	dodir "${daemon_store}"
	fperms 3770 "${daemon_store}"
	fowners crash:crash-user-access "${daemon_store}"

	into /usr
	use cros_embedded || dobin "${OUT}"/anomaly_detector
	dosbin kernel_log_collector.sh

	if use cheets; then
		dobin "${OUT}"/core_collector
		use_i686 && newbin "$(platform_out_i686)"/core_collector "core_collector32"
	fi

	if use systemd; then
		systemd_dounit init/crash-reporter.service
		systemd_dounit init/crash-boot-collect.service
		systemd_enable_service multi-user.target crash-reporter.service
		systemd_enable_service multi-user.target crash-boot-collect.service
		systemd_dounit init/crash-sender.service
		systemd_enable_service multi-user.target crash-sender.service
		systemd_dounit init/crash-sender.timer
		systemd_enable_service timers.target crash-sender.timer
		if ! use cros_embedded; then
			systemd_dounit init/anomaly-detector.service
			systemd_enable_service multi-user.target anomaly-detector.service
		fi
	else
		insinto /etc/init
		doins init/crash-reporter.conf
		doins init/crash-reporter-early-init.conf
		doins init/crash-boot-collect.conf
		doins init/crash-sender.conf
		use cros_embedded || doins init/anomaly-detector.conf
	fi

	insinto /etc
	doins crash_reporter_logs.conf

	udev_dorules 99-crash-reporter.rules

	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/crash_sender_fuzzer \
		--dict "${S}"/crash_sender_fuzzer.dict

	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/anomaly_detector_fuzzer \
		--dict "${S}"/anomaly_detector_fuzzer.dict
}

platform_pkg_test() {
	local gtest_filter_user_tests="-*.RunAsRoot*:"
	local gtest_filter_root_tests="*.RunAsRoot*-"

	platform_test "run" "${OUT}/crash_reporter_test" "0" \
		"${gtest_filter_user_tests}"
	platform_test "run" "${OUT}/crash_reporter_test" "1" \
		"${gtest_filter_root_tests}"
	platform_test "run" "${OUT}/anomaly_detector_test"
}

src_prepare() {
  epatch "${FILESDIR}/cros_i686_issue.patch"
  default
}
