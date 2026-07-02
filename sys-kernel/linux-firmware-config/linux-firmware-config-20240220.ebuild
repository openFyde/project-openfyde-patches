# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

EAPI=7

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="intel-common amd-common nvidia-common surface-common"
SLOT="${PV}"

RDEPEND=""

DEPEND="${RDEPEND}"

S=${WORKDIR}

TARGET_CONFIG="linux-firmware-${PV}"

src_compile() {
  local file_list="${FILESDIR}/linux_firmware_list_${PV}"
  if use intel-common; then
    # Intel CPU + all graphics cards: keep every GPU (i915/amdgpu/radeon/nvidia),
    # drop AMD CPU-only firmware (microcode/SEV/TEE/PMF).
    cat $file_list | grep -v -E "amd-ucode|amd[_-]sev|amdtee|amd_pmf" > $TARGET_CONFIG
  elif use amd-common; then
    # AMD CPU + AMD/NVIDIA graphics: keep AMD CPU firmware, drop Intel GPUs (i915/xe).
    cat $file_list | grep -v -E "i915|^xe/|LICENSE\.xe" > $TARGET_CONFIG
  elif use nvidia-common; then
    cat $file_list | grep -v -E "i915|amdgpu|radeon" > $TARGET_CONFIG
  elif use surface-common; then
    cat $file_list | grep -v -E "amdgpu|amd-ucode|radeon|nvidia|amdtee|cirrus|iwlwifi-[1-9]|rtw8|brcm|b43|mediatek|amd_sev" > $TARGET_CONFIG
  else
    cat $file_list > $TARGET_CONFIG
  fi
}

src_install() {
  insinto /usr/local/etc/portage/savedconfig/sys-kernel
  doins $TARGET_CONFIG
}
