# Copyright (c) 2026 Fyde Innovations Limited and the openFyde Authors.
# Distributed under the license specified in the root directory of this project.

cros_pre_src_prepare_openfyde_patches() {
  if [ $PV == "9999" ]; then
    return
  fi
  # The stock amd64 seccomp policy is missing creat/sched_getattr/sched_setattr
  # (arm/arm64 already carry the sched pair; creat does not exist on aarch64).
  # Without them minijail silently kills the libhwsec worker thread and
  # device_managementd hangs off the bus, breaking enrollment. Unfixed
  # upstream as of 2026-07-19.
  if use amd64; then
    eapply -p2 ${OPENFYDE_PATCHES_BASHRC_FILESDIR}/grant-thread-startup-syscalls-amd64.patch
  fi
}
