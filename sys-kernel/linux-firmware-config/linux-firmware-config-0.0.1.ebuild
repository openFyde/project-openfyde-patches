# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

EAPI="5"

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="intel-common amd-common nvidia-common"

RDEPEND=""

DEPEND="${RDEPEND}"

S=${WORKDIR}

src_install() {
  insinto /usr/local/etc/portage/savedconfig/sys-kernel
  target_config=linux-firmware-20220310
  if use intel-common; then
    newins ${FILESDIR}/intel-common-config $target_config
  elif use amd-common; then
    newins ${FILESDIR}/amd-config $target_config
  elif use nvidia-common; then
    newins ${FILESDIR}/nvidia-config $target_config
  else
    newins ${FILESDIR}/common-config $target_config 
  fi
}
