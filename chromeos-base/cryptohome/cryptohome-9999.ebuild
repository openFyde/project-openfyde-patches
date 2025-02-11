# Copyright 2014 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{8..11} )

CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_DESTDIR="${S}/platform2"
CROS_WORKON_INCREMENTAL_BUILD=1
# TODO(crbug.com/809389): Avoid directly including headers from other packages.
CROS_WORKON_SUBTREE="common-mk cryptohome libhwsec libhwsec-foundation .gn"

PLATFORM_NATIVE_TEST="yes"
PLATFORM_SUBDIR="cryptohome"

inherit python-any-r1 tmpfiles cros-workon cros-unibuild platform cros-protobuf systemd udev user

DESCRIPTION="Encrypted home directories for Chromium OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/cryptohome/"
SRC_URI=""

LICENSE="BSD-Google"
KEYWORDS="~*"
IUSE="device-mapper -direncription_allow_v2 -direncryption fuzzer
	generic_tpm2 kernel-6_10-enablement kernel-6_6 kernel-6_1 kernel-5_15
	kernel-5_10 kernel-5_4 kernel-upstream lvm_application_containers
	lvm_stateful_partition mount_oop pinweaver profiling slow_mount
	systemd test tpm tpm_dynamic tpm_insecure_fallback tpm2
	uprev-4-to-5 user_session_isolation +vault_legacy_mount"

REQUIRED_USE="
	device-mapper
	tpm_dynamic? ( tpm tpm2 )
	!tpm_dynamic? ( ?? ( tpm tpm2 ) )
"

COMMON_DEPEND="
	!chromeos-base/chromeos-cryptohome
	chromeos-base/biod_proxy:=
	chromeos-base/bootlockbox-client:=
	chromeos-base/cbor:=
	chromeos-base/chaps:=
	chromeos-base/chromeos-config-tools:=
	chromeos-base/featured:=
	chromeos-base/libbrillo:=[fuzzer?]
	chromeos-base/libhwsec:=[test?]
	chromeos-base/libhwsec-foundation:=
	chromeos-base/libstorage:=
	>=chromeos-base/metrics-0.0.1-r3152:=
	chromeos-base/privacy:=
	chromeos-base/secure-erase-file:=
	dev-cpp/abseil-cpp:=
	>=dev-libs/flatbuffers-2.0.0-r1:=
	dev-libs/libxml2:=
	dev-libs/openssl:=
	sys-apps/dbus:=
	sys-apps/flashmap:=
	sys-apps/keyutils:=
	sys-apps/rootdev:=
	sys-fs/e2fsprogs:=
	sys-fs/ecryptfs-utils:=
	sys-fs/lvm2:=
"

RDEPEND="${COMMON_DEPEND}
	chromeos-base/tpm_manager:=
"

DEPEND="${COMMON_DEPEND}
	test? (
		app-crypt/trousers:=
		app-shells/dash:=
		chromeos-base/chromeos-base:=
	)
	tpm2? ( chromeos-base/trunks:= )
	chromeos-base/attestation-client:=
	chromeos-base/cryptohome-client:=
	chromeos-base/device_management-client:=
	chromeos-base/power_manager-client:=
	chromeos-base/protofiles:=
	chromeos-base/system_api:=[fuzzer?]
	chromeos-base/tpm_manager-client:=
	chromeos-base/vboot_reference:=
	chromeos-base/libhwsec:=
"

# shellcheck disable=SC2016
BDEPEND="
	chromeos-base/chromeos-dbus-bindings
	dev-libs/flatbuffers
	$(python_gen_any_dep '
		dev-python/flatbuffers[${PYTHON_USEDEP}]
	')
"

python_check_deps() {
	python_has_version -b "dev-python/flatbuffers[${PYTHON_USEDEP}]"
}

src_install() {
	if use direncription_allow_v2 && ( (use !kernel-5_4 && use !kernel-5_10 && use !kernel-5_15 && use !kernel-6_1 && use !kernel-6_6 && use !kernel-6_10-enablement && use !kernel-upstream) || use uprev-4-to-5); then
		die "direncription_allow_v2 is enabled where it shouldn't be. Do you need to change the board overlay? Note, uprev boards should have it disabled!"
	fi

	if use !direncription_allow_v2 && (use kernel-5_4 || use kernel-5_10 || use kernel-5_15 || use kernel-6_1 || use kernel-6_6 || use kernel-6_10-enablement || use kernel-upstream) && use !uprev-4-to-5; then
		die "direncription_allow_v2 is not enabled where it should be. Do you need to change the board overlay? Note, uprev boards should have it disabled!"
	fi

	# Install init scripts
	if use systemd; then
		if use tpm2; then
			sed 's/tcsd.service/attestationd.service/' \
				init/cryptohomed.service \
				> "${T}/cryptohomed.service"
			systemd_dounit "${T}/cryptohomed.service"
		else
			systemd_dounit init/cryptohomed.service
		fi
		systemd_enable_service boot-services.target cryptohomed.service
		systemd_enable_service system-services.target mount-encrypted.service
	else
		insinto /etc/init
		doins init/cryptohomed-client.conf
		doins init/cryptohomed.conf
		doins init/init-homedirs.conf
		if use tpm_dynamic; then
			newins init/lockbox-cache.conf.tpm_dynamic lockbox-cache.conf
		else
			doins init/lockbox-cache.conf
		fi

		if use direncryption; then
			sed -i '/env DIRENCRYPTION_FLAG=/s:=.*:="--direncryption":' \
				"${D}/etc/init/cryptohomed.conf" ||
				die "Can't replace direncryption flag in cryptohomed.conf"
		fi
		if use !vault_legacy_mount; then
			sed -i '/env NO_LEGACY_MOUNT_FLAG=/s:=.*:="--nolegacymount":' \
				"${D}/etc/init/cryptohomed.conf" ||
				die "Can't replace nolegacymount flag in cryptohomed.conf"
		fi
		if use direncription_allow_v2; then
			sed -i '/env FSCRYPT_V2_FLAG=/s:=.*:="--fscrypt_v2":' \
				"${D}/etc/init/cryptohomed.conf" ||
				die "Can't replace fscrypt_v2 flag in cryptohomed.conf"
		fi
		if use lvm_application_containers; then
			sed -i '/env APPLICATION_CONTAINERS=/s:=.*:="--application_containers":' \
				"${D}/etc/init/cryptohomed.conf" ||
				die "Can't replace application_containers flag in cryptohomed.conf"
		fi
	fi
	exeinto /usr/share/cros/init

	local fuzzer_component_id="1088399"
	platform_fuzzer_install "${S}"/OWNERS \
		"${OUT}"/cryptohome_cryptolib_blob_to_hex_fuzzer \
		--comp "${fuzzer_component_id}"

	platform_fuzzer_install "${S}"/OWNERS \
		"${OUT}"/cryptohome_userdataauth_fuzzer \
		--comp "${fuzzer_component_id}"

	platform_fuzzer_install "${S}"/OWNERS \
		"${OUT}"/cryptohome_user_secret_stash_parser_fuzzer \
		--comp "${fuzzer_component_id}"

	platform_fuzzer_install "${S}"/OWNERS \
		"${OUT}"/cryptohome_recovery_id_fuzzer \
		--comp "${fuzzer_component_id}"

	platform_fuzzer_install "${S}"/OWNERS \
		"${OUT}"/cryptohome_backend_cert_parser_fuzzer \
		--comp "${fuzzer_component_id}"

	platform_src_install
}

pkg_preinst() {
	enewuser "cryptohome"
	enewgroup "cryptohome"
}
