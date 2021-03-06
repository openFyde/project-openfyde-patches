# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="6"
inherit savedconfig

if [[ ${PV} == 99999999* ]]; then
	inherit git-r3
	SRC_URI=""
	EGIT_REPO_URI="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/${PN}.git"
else
  if [[ -n "${MY_COMMIT}" ]]; then
    SRC_URI="https://git.kernel.org/cgit/linux/kernel/git/firmware/linux-firmware.git/snapshot/${MY_COMMIT}.tar.gz -> ${P}.tar.gz"
  else
    SRC_URI="https://mirrors.edge.kernel.org/pub/linux/kernel/firmware/${P}.tar.xz"
  fi
	KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
fi

SRC_URI+=" ${OPENFYDE_PREBUILT_PKGS_HOST_URL}/linux-firmware-nvidia/linux-firmware-nvidia-amd64-92.0.0.0.tar.gz"

DESCRIPTION="Linux firmware files"
HOMEPAGE="https://git.kernel.org/?p=linux/kernel/git/firmware/linux-firmware.git"

LICENSE="linux-firmware ( BSD ISC MIT ) GPL-2 GPL-2+"
SLOT="0"
IUSE="savedconfig"

DEPEND="
  savedconfig? ( sys-kernel/linux-firmware-config )
"
RDEPEND="!savedconfig? (
		!sys-firmware/alsa-firmware[alsa_cards_ca0132]
		!sys-firmware/alsa-firmware[alsa_cards_korg1212]
		!sys-firmware/alsa-firmware[alsa_cards_maestro3]
		!sys-firmware/alsa-firmware[alsa_cards_sb16]
		!sys-firmware/alsa-firmware[alsa_cards_ymfpci]
		!media-tv/cx18-firmware
		!<sys-firmware/ivtv-firmware-20080701-r1
		!media-tv/linuxtv-dvb-firmware[dvb_cards_cx231xx]
		!media-tv/linuxtv-dvb-firmware[dvb_cards_cx23885]
		!media-tv/linuxtv-dvb-firmware[dvb_cards_usb-dib0700]
		!net-dialup/ueagle-atm
		!net-dialup/ueagle4-atm
		!net-wireless/ar9271-firmware
		!net-wireless/i2400m-fw
		!net-wireless/libertas-firmware
		!sys-firmware/rt61-firmware
		!net-wireless/rt73-firmware
		!net-wireless/rt2860-firmware
		!net-wireless/rt2870-firmware
		!sys-block/qla-fc-firmware
		!sys-firmware/amd-ucode
		!sys-firmware/iwl1000-ucode
		!sys-firmware/iwl2000-ucode
		!sys-firmware/iwl2030-ucode
		!sys-firmware/iwl3945-ucode
		!sys-firmware/iwl4965-ucode
		!sys-firmware/iwl5000-ucode
		!sys-firmware/iwl5150-ucode
		!sys-firmware/iwl6000-ucode
		!sys-firmware/iwl6005-ucode
		!sys-firmware/iwl6030-ucode
		!sys-firmware/iwl6050-ucode
		!sys-firmware/iwl3160-ucode
		!sys-firmware/iwl7260-ucode
		!sys-firmware/iwl7265-ucode
		!sys-firmware/iwl3160-7260-bt-ucode
		!sys-firmware/radeon-ucode
	)
"
#add anything else that collides to this

RESTRICT="binchecks strip mirror"

src_unpack() {
	if [[ ${PV} == 99999999* ]]; then
		git-r3_src_unpack
	else
		default
		# rename directory from git snapshot tarball
    if [[ ${#GIT_COMMIT} -gt 8 ]]; then
		  mv ${PN}-*/ ${P} || die
    fi
	fi
}

src_prepare() {
	default

	echo "# Remove files that shall not be installed from this list." > ${PN}.conf
	find * \( \! -type d -and \! -name ${PN}.conf \) >> ${PN}.conf

	if use savedconfig; then
		restore_config ${PN}.conf
		ebegin "Removing all files not listed in config"

		local file delete_file preserved_file preserved_files=()

		while IFS= read -r file; do
			# Ignore comments.
			if [[ ${file} != "#"* ]]; then
				preserved_files+=("${file}")
			fi
		done < ${PN}.conf || die

		while IFS= read -d "" -r file; do
			delete_file=true
			for preserved_file in "${preserved_files[@]}"; do
				if [[ "${file}" == "${preserved_file}" ]]; then
					delete_file=false
				fi
			done

			if ${delete_file}; then
				rm "${file}" || die
			fi
		done < <(find * \( \! -type d -and \! -name ${PN}.conf \) -print0 || die)

		eend || die

		# remove empty directories, bug #396073
		find -type d -empty -delete || die
	fi
  cp -r ../nvidia .
}

src_install() {
	if use !savedconfig; then
		save_config ${PN}.conf
	fi
	rm ${PN}.conf || die
	insinto /lib/firmware/
	doins -r *
}

pkg_preinst() {
	if use savedconfig; then
		ewarn "USE=savedconfig is active. You must handle file collisions manually."
	fi
}

pkg_postinst() {
	elog "If you are only interested in particular firmware files, edit the saved"
	elog "configfile and remove those that you do not want."
}
