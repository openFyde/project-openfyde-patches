# Copyright 2014 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_SUBTREE="common-mk libhwsec-foundation metrics trunks .gn"

PLATFORM_SUBDIR="trunks"

inherit cros-workon platform cros-protobuf user

DESCRIPTION="Trunks service for Chromium OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/trunks/"

LICENSE="BSD-Google"
KEYWORDS="~*"
IUSE="
	cr50_onboard
	cros_host
	fuzzer
	ftdi_tpm
	generic_tpm2
	profiling
	ti50_onboard
	tpm_dynamic
	tpm2_simulator
	key_eviction
"

# This depends on protobuf because it uses protoc and needs to be rebuilt
# whenever the protobuf library is updated since generated source files may be
# incompatible across different versions of the protobuf library.
COMMON_DEPEND="
	>=chromeos-base/metrics-0.0.1-r3152:=
	chromeos-base/minijail:=
	chromeos-base/power_manager-client:=
	chromeos-base/system_api:=
	chromeos-base/libhwsec-foundation:=
	ftdi_tpm? ( dev-embedded/libftdi:= )
	chromeos-base/tpm2:=
	tpm2_simulator? ( chromeos-base/tpm2-simulator:= )
	dev-cpp/abseil-cpp:=
	dev-libs/openssl:=
	fuzzer? (
		dev-cpp/gtest:=
	)
	chromeos-base/pinweaver:=
	chromeos-base/spdm:=
	"

RDEPEND="
	${COMMON_DEPEND}
	generic_tpm2? ( chromeos-base/chromeos-cr50-scripts )
	!tpm_dynamic? ( !app-crypt/tpm-tools )
	chromeos-base/libhwsec-foundation
	"

DEPEND="
	${COMMON_DEPEND}
	chromeos-base/chromeos-ec-headers:=
	"

PDEPEND="
	cr50_onboard? ( chromeos-base/chromeos-cr50 )
	ti50_onboard? ( chromeos-base/chromeos-ti50 )
"

BDEPEND="
	chromeos-base/chromeos-dbus-bindings
	chromeos-base/minijail
"

src_install() {
	platform_src_install

	insinto /etc/dbus-1/system.d
	doins org.chromium.Trunks.conf

	if use tpm_dynamic; then
		sed -i '/env TPM_DYNAMIC=/s:=.*:=true:' \
			"${D}/etc/init/trunksd.conf" ||
			die "Can't activate tpm_dynamic in trunksd.conf"
	fi

	dosbin "${OUT}"/pinweaver_client
	dosbin "${OUT}"/trunks_client
	dosbin "${OUT}"/trunks_send
	if use tpm_dynamic; then
		newsbin tpm_version tpm2_version
	else
		dosbin tpm_version
	fi
	dosbin "${OUT}"/trunksd
	dolib.so "${OUT}"/lib/libtrunks.so

	# trunks_test library implements trunks mocks which
	# are used by unittest and fuzzer.
	use cros_host || into /build
	dolib.a "${OUT}"/libtrunks_test.a
	dolib.a "${OUT}"/libtrunksd_lib.a

	insinto /usr/share/policy
	newins "trunksd-seccomp-${ARCH}.policy" trunksd-seccomp.policy

	insinto /usr/include/trunks
	doins ./*.h
	doins "${OUT}"/gen/include/trunks/*.h

	insinto /usr/include/proto
	doins "${S}"/pinweaver.proto

	insinto /usr/include/chromeos/dbus/trunks
	doins "${S}"/trunks_interface.proto

	insinto "/usr/$(get_libdir)/pkgconfig"
	doins "${OUT}"/obj/trunks/libtrunks.pc
	local fuzzer_component_id="1281105"
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/trunks_creation_blob_fuzzer \
		--comp "${fuzzer_component_id}"
	platform_fuzzer_install "${S}"/OWNERS \
		"${OUT}"/trunks_hmac_authorization_delegate_fuzzer \
		--comp "${fuzzer_component_id}"
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/trunks_key_blob_fuzzer \
		--comp "${fuzzer_component_id}"
	platform_fuzzer_install "${S}"/OWNERS \
		"${OUT}"/trunks_password_authorization_delegate_fuzzer \
		--comp "${fuzzer_component_id}"
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/trunks_resource_manager_fuzzer \
		--comp "${fuzzer_component_id}"
	platform_fuzzer_install "${S}"/OWNERS "${OUT}"/trunks_tpm_pinweaver_fuzzer \
		--comp "${fuzzer_component_id}"
	# Allow specific syscalls for profiling.
	# TODO (b/242806964): Need a better approach for fixing up the seccomp policy
	# related issues (i.e. fix with a single function call)
	if use profiling; then
		echo -e "\n# Syscalls added for profiling case only.\nmkdir: 1\nftruncate: 1\nuname: 1\n" >> \
		"${D}/usr/share/policy/trunksd-seccomp.policy"
	fi

	if use key_eviction; then
		sed -i '/env KEY_EVICTION=/s:=.*:=true:' \
			"${D}/etc/init/trunksd.conf" ||
			die "Can't replace env variable KEY_EVICTION in trunksd.conf"
	fi
}

platform_pkg_test() {
	"${S}/generator/generator_test.py" || die

	local tests=(
		trunks_testrunner
	)

	local test_bin
	for test_bin in "${tests[@]}"; do
		platform_test "run" "${OUT}/${test_bin}"
	done
}

pkg_preinst() {
	enewuser trunks
	enewgroup trunks
}
