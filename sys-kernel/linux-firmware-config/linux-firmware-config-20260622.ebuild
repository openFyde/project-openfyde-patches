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
    # Intel CPU, size-constrained rootfs: legacy consumer GPUs only.
    # Drop AMD CPU-only firmware, drop Intel Xe (newest GPUs, ~3M), drop the
    # NVIDIA data-center dies (gp100 = P100, gv100 = V100), and drop NVIDIA newer
    # than the consumer 10xx/Pascal series (Turing+ GSP blobs, ~100M).
    cat $file_list | grep -v -E "amd-ucode|amd[_-]sev|amdtee|amd_pmf|amdnpu|^xe/|LICENSE\.xe|nvidia/(gp100|gv|tu|ga|ad|gb|gh)" > $TARGET_CONFIG
  elif use intel-common; then
    # Intel CPU + NVIDIA graphics up to consumer Ampere. Keep i915/xe/amdgpu/
    # radeon; drop AMD CPU-only firmware, all NVIDIA data-center dies (gp100/
    # gv100/ga100 = P100/V100/A100, plus Hopper gh / Blackwell-DC gb), and Ada
    # (ad) whose GSP blobs are huge and serve GPUs FydeOS users don't have.
    # Keep consumer Ampere ga102/ga106/ga107 (ga102 is also ga106/ga107's GSP-RM
    # symlink target on kernel 6.12 nouveau); drop ga103/ga104. Note ga107 is the
    # "20xx"-branded RTX 2050 / MX550 / MX570 (an Ampere GA107 die).
    # Also drop the 570.144 GSP blobs (nouveau 6.12 loads only 535.113.01).
    cat $file_list | grep -v -E "amd-ucode|amd[_-]sev|amdtee|amd_pmf|amdnpu|nvidia/(gp100|gv100|ga10[034]|ad|gb|gh)|nvidia/.*570\.144" > $TARGET_CONFIG
  elif use amd-common; then
    # AMD CPU + AMD/NVIDIA graphics up to consumer Ampere. Keep AMD CPU firmware;
    # drop Intel GPUs (i915/xe), all NVIDIA data-center dies (gp100/gv100/ga100 =
    # P100/V100/A100, plus Hopper gh / Blackwell-DC gb), and Ada (ad) GSP blobs.
    # Keep consumer Ampere ga102/ga106/ga107 (ga102 is also ga106/ga107's GSP-RM
    # symlink target on kernel 6.12 nouveau); drop ga103/ga104. Note ga107 is the
    # "20xx"-branded RTX 2050 / MX550 / MX570 (an Ampere GA107 die).
    # Also drop the 570.144 GSP blobs (nouveau 6.12 loads only 535.113.01).
    cat $file_list | grep -v -E "i915|^xe/|LICENSE\.xe|nvidia/(gp100|gv100|ga10[034]|ad|gb|gh)|nvidia/.*570\.144" > $TARGET_CONFIG
  elif use nvidia-common; then
    # NVIDIA-dedicated build: keep all consumer NVIDIA firmware, drop Intel/AMD
    # GPUs. Also strip NVIDIA data-center dies (gp100/gv100/ga100/gh100/gb100 =
    # P100/V100/A100/H100/Blackwell-DC) — no consumer GeForce uses those — and
    # the 570.144 GSP blobs (nouveau 6.12 loads only 535.113.01).
    cat $file_list | grep -v -E "i915|amdgpu|radeon|nvidia/(gp100|gv100|ga100|gh100|gb100)|nvidia/.*570\.144" > $TARGET_CONFIG
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
