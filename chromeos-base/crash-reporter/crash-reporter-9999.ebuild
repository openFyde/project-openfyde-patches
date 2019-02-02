# Copyright 2014 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk crash-reporter metrics .gn"

PLATFORM_SUBDIR="crash-reporter"

inherit cros-i686 cros-workon platform systemd udev

DESCRIPTION="Crash reporting service that uploads crash reports with debug information"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/crash-reporter/"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="~*"
IUSE="cheets cros_embedded -direncryption systemd"

RDEPEND="
	chromeos-base/minijail
	chromeos-base/google-breakpad[cros_i686?]
	chromeos-base/libbrillo
	chromeos-base/metrics
	dev-libs/libpcre
	net-misc/curl
	direncryption? ( sys-apps/keyutils )
"
DEPEND="
	${RDEPEND}
	chromeos-base/debugd-client
	chromeos-base/session_manager-client
	chromeos-base/system_api
	sys-devel/flex
"
RDEPEND+="
	chromeos-base/chromeos-ca-certificates
"

src_configure() {
	platform_src_configure
	use cheets && use_i686 && platform_src_configure_i686
}

src_compile() {
	platform_src_compile
	use cheets && use_i686 && platform_src_compile_i686 "core_collector"
}

src_install() {
	into /
	dosbin "${OUT}"/crash_reporter
	dosbin "${OUT}"/crash_sender
	dosbin crash_sender.sh

	into /usr
	use cros_embedded || dobin "${OUT}"/list_proxies
	use cros_embedded || dobin "${OUT}"/anomaly_collector
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
			systemd_dounit init/anomaly-collector.service
			systemd_enable_service multi-user.target anomaly-collector.service
		fi
	else
		insinto /etc/init
		doins init/crash-reporter.conf
		doins init/crash-boot-collect.conf
		doins init/crash-sender.conf
		use cros_embedded || doins init/anomaly-collector.conf
	fi

	insinto /etc
	doins crash_reporter_logs.conf

	udev_dorules 99-crash-reporter.rules
}

platform_pkg_test() {
	platform_test "run" "${OUT}/crash_reporter_test"
	platform_test "run" "${OUT}/anomaly_collector_test.sh"
}
