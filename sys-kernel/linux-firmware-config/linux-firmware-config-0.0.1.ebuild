# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

EAPI=7

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="intel-common amd-common nvidia-common"

RDEPEND=""

DEPEND="${RDEPEND}"

S=${WORKDIR}

TARGET_CONFIG="linux-firmware-20240220"

src_compile() {
  local file_list="${FILESDIR}/linux_firmware_list"
  if use intel-common; then
    cat $file_list | grep -v -E "amdgpu|nvidia|radeon" > $TARGET_CONFIG
  elif use amd-common; then
    cat $file_list | grep -v -E "i915|nvidia" > $TARGET_CONFIG
  elif use nvidia-common; then
    cat $file_list | grep -v -E "i915|amdgpu|radeon" > $TARGET_CONFIG
  else
    cat $file_list > $TARGET_CONFIG
  fi
}

src_install() {
  insinto /usr/local/etc/portage/savedconfig/sys-kernel
  doins $TARGET_CONFIG
}
