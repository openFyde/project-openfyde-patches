# Copyright 2017 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5
CROS_WORKON_COMMIT="fadba088eff4c4bcdc8f8a4cea02cce7ba08bccc"
CROS_WORKON_TREE=("01ff687fb16fa973568009bb8676ccfda32b65bd" "7c2672e7fd88678931ee5c3ebbcc5e20699264c1" "351d92d7016b5c6eabac887e13c6ceb4105f576c" "dc1506ef7c8cfd2c5ffd1809dac05596ec18773c")
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_INCREMENTAL_BUILD=1
# TODO(crbug.com/809389): Remove arc/network from this list.
CROS_WORKON_SUBTREE="arc/network common-mk vm_tools .gn"

PLATFORM_SUBDIR="vm_tools"

inherit cros-workon platform udev user

DESCRIPTION="VM host tools for Chrome OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/vm_tools"
CREDITS_SRC="linux_credits-10895.tar.bz2"
SRC_URI="gs://chromeos-localmirror/distfiles/${CREDITS_SRC}"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
# The crosvm-wl-dmabuf USE flag is used when preprocessing concierge source.
IUSE="+kvm_host +seccomp +crosvm-wl-dmabuf fuzzer workaround_crbug_909793"
REQUIRED_USE="kvm_host"

RDEPEND="
	!!chromeos-base/vm_tools
	chromeos-base/arc-networkd
	chromeos-base/crosvm
	chromeos-base/libbrillo
	chromeos-base/minijail
	net-libs/grpc:=
	dev-libs/protobuf:=
	dev-rust/9s
"
DEPEND="
	${RDEPEND}
	chromeos-base/shill-client
	>=chromeos-base/system_api-0.0.1-r3360
	fuzzer? ( dev-libs/libprotobuf-mutator )
"

src_unpack() {
	platform_src_unpack

	unpack "${CREDITS_SRC}"
}

src_install() {
	dobin "${OUT}"/cicerone_client
	dobin "${OUT}"/concierge_client
	dobin "${OUT}"/maitred_client
	dobin "${OUT}"/seneschal
	dobin "${OUT}"/seneschal_client
	dobin "${OUT}"/vm_cicerone
	dobin "${OUT}"/vm_concierge
	dobin "${OUT}"/vmlog_forwarder
	dobin "${OUT}"/vsh

	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/cicerone_container_listener_fuzzer

	insinto /etc/init
	doins init/*.conf

	insinto /etc/dbus-1/system.d
	doins dbus/*.conf

	insinto /usr/share/policy
	if use seccomp; then
		newins "init/vm_cicerone-seccomp-${ARCH}.policy" vm_cicerone-seccomp.policy
	fi

	udev_dorules udev/99-vm.rules

	# TODO(crbug.com/876898): Remove hardcoded credits file.
	local credits_arch="unknown"
	case ${ARCH} in
		amd64) credits_arch=x86;;
		arm) credits_arch=arm;;
		arm64) credits_arch=arm;;
	esac
	insinto /opt/google/chrome/resources
	newins "${WORKDIR}/credits_${credits_arch}.html" linux_credits.html
}

platform_pkg_test() {
	local tests=(
		cicerone_test
		concierge_test
		syslog_forwarder_test
	)

	local test_bin
	for test_bin in "${tests[@]}"; do
		platform_test "run" "${OUT}/${test_bin}"
	done
}

pkg_preinst() {
	# We need the syslog user and group for both host and guest builds.
	enewuser syslog
	enewgroup syslog

	enewuser vm_cicerone
	enewgroup vm_cicerone

	enewuser seneschal
	enewgroup seneschal
	enewuser seneschal-dbus
	enewgroup seneschal-dbus

	enewuser pluginvm
	enewgroup pluginvm

	enewgroup virtaccess
}
