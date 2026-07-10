# Copyright (c) 2022 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

EAPI=7

DESCRIPTION="empty project"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="intel-common intel-slim amd-common nvidia-common surface-common"
SLOT="${PV}"

RDEPEND=""

DEPEND="${RDEPEND}"

S=${WORKDIR}

TARGET_CONFIG="linux-firmware-${PV}"

src_compile() {
  local file_list="${FILESDIR}/linux_firmware_list_${PV}"
  if use intel-slim; then
    # Intel CPU, size-constrained rootfs: legacy GPUs only.
    # Drop AMD CPU-only firmware, drop Intel Xe (newest GPUs, ~3M), and drop
    # NVIDIA newer than the 10xx/Pascal series (Turing+ GSP blobs, ~100M).
    cat $file_list | grep -v -E "amd-ucode|amd[_-]sev|amdtee|amd_pmf|amdnpu|^xe/|LICENSE\.xe|nvidia/(gv|tu|ga|ad|gb|gh)" > $TARGET_CONFIG
  elif use intel-common; then
    # Intel CPU + graphics up to NVIDIA 20xx/Turing. Keep i915/xe/amdgpu/radeon
    # and NVIDIA through Turing; drop AMD CPU-only firmware and NVIDIA 30xx and
    # newer (Ampere ga / Ada ad / Blackwell gb / Hopper gh) whose GSP blobs are
    # huge and only serve GPUs FydeOS's old-laptop users don't have.
    cat $file_list | grep -v -E "amd-ucode|amd[_-]sev|amdtee|amd_pmf|amdnpu|nvidia/(ga|ad|gb|gh)" > $TARGET_CONFIG
  elif use amd-common; then
    # AMD CPU + AMD/NVIDIA graphics up to NVIDIA 20xx/Turing. Keep AMD CPU
    # firmware; drop Intel GPUs (i915/xe) and NVIDIA 30xx and newer (Ampere ga /
    # Ada ad / Blackwell gb / Hopper gh) GSP blobs.
    cat $file_list | grep -v -E "i915|^xe/|LICENSE\.xe|nvidia/(ga|ad|gb|gh)" > $TARGET_CONFIG
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
