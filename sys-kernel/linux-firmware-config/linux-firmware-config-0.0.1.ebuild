# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

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
  if use intel-common; then
    newins ${FILESDIR}/intel-common-config linux-firmware    
  elif use amd-common; then
    newins ${FILESDIR}/amd-config linux-firmware
  elif use nvidia-common; then
    newins ${FILESDIR}/nvidia-config linux-firmware
  else
    newins ${FILESDIR}/common-config linux-firmware
  fi
}
