# Copyright 2015 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

CROS_WORKON_COMMIT="f0a8fa83760bd052e3c44f3fbca7ea9282e044d7"
CROS_WORKON_TREE=("fe8d35af30ff1c2484e01cd6235a5d45c627d10d" "659ff958b03625d691bbdac92411d7954413d446" "e031bc0916237739f919f53a1ec2ac5b2d3d0cdc" "2834854981f88e2b81fefd49c590185a31f2b1f1" "df6635d434b56fb1784ba5ab44639de55a9e3fe3" "d106e74b42f56a88eb17dbd227b57c8843c563dd" "e7dba8c91c1f3257c34d4a7ffff0ea2537aeb6bb")
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk libhwsec libtpmcrypto metrics tpm_manager trunks .gn"

PLATFORM_SUBDIR="tpm_manager"

inherit cros-workon platform user

DESCRIPTION="Daemon to manage TPM ownership."
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/master/tpm_manager/"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE="test tpm tpm2"

REQUIRED_USE="tpm2? ( !tpm )"

RDEPEND="
	!tpm2? ( app-crypt/trousers )
	tpm2? (
		chromeos-base/trunks
	)
	>=chromeos-base/metrics-0.0.1-r3152
	chromeos-base/minijail
	chromeos-base/libhwsec
	chromeos-base/libtpmcrypto
	"

DEPEND="${RDEPEND}
	tpm2? ( chromeos-base/trunks[test?] )
	"

pkg_preinst() {
	enewuser tpm_manager
	enewgroup tpm_manager
}

src_install() {
	# Install D-Bus configuration file.
	insinto /etc/dbus-1/system.d
	doins server/org.chromium.TpmManager.conf

	# Install upstart config file.
	insinto /etc/init
	doins server/tpm_managerd.conf
	if use tpm2; then
		sed -i 's/started tcsd/started trunksd/' \
			"${D}/etc/init/tpm_managerd.conf" ||
			die "Can't replace tcsd with trunksd in tpm_managerd.conf"
	fi

	# Install the executables provided by TpmManager
	dosbin "${OUT}"/tpm_managerd
	dosbin "${OUT}"/local_data_migration
	dobin "${OUT}"/tpm_manager_client

	# Install seccomp policy files.
	insinto /usr/share/policy
	newins server/tpm_managerd-seccomp-${ARCH}.policy tpm_managerd-seccomp.policy

	dolib.so "${OUT}"/lib/libtpm_manager.so
	dolib.a "${OUT}"/libtpm_manager_test.a


	# Install header files.
	insinto /usr/include/tpm_manager/client
	doins client/*.h
	insinto /usr/include/tpm_manager/common
	doins common/*.h
}

platform_pkg_test() {
	local tests=(
		tpm_manager_testrunner
	)

	local test_bin
	for test_bin in "${tests[@]}"; do
		platform_test "run" "${OUT}/${test_bin}"
	done
}

src_prepare() {
  default
  epatch ${FILESDIR}/ignore_errors.patch
}
