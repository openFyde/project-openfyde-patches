// Copyright 2025 The ChromiumOS Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package main

// b/296092419: Flags that used to be in global CFLAGS, pushed down to a per-package level.
func warningSuppressionsForLLVM_b296092419(packageNameAndCategory string) []string {
	switch packageNameAndCategory {
	// Manually identified & suppressed.
	case "app-arch/zip", "net-misc/taylor-uucp":
		return []string{"-Wno-error=implicit-function-declaration"}
	case "dev-util/bazel":
		return []string{"-Wno-implicit-function-declaration"}
	case "media-libs/libcamera-mtkisp7", "media-libs/libcamera-upstream", "media-libs/libcamera-reven":
		return []string{"-Wno-vla-cxx-extension"}

	// Automatically suppressed.
	// Observed and suppressed on 63 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "app-arch/sharutils":
		return []string{"-Wno-implicit-function-declaration", "-Wno-int-conversion"}
	// Observed and suppressed on 62 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "app-benchmarks/lmbench":
		return []string{"-Wno-implicit-function-declaration", "-Wno-implicit-int"}
	// Observed and suppressed on 62 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "app-benchmarks/stress-ng":
		return []string{"-Wno-implicit-function-declaration"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., staging-build-chromiumos-sdk: https://ci.chromium.org/b/8712322756730423329.
	case "app-crypt/efitools":
		return []string{"-Wno-implicit-function-declaration"}
	// Observed and suppressed on 3 builders during testing.
	// e.g., betty-fuzzer-cq: https://ci.chromium.org/b/8712322022231622129.
	case "app-crypt/trousers":
		return []string{"-Wno-implicit-function-declaration"}
	// Observed and suppressed on 64 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "app-misc/screen":
		return []string{"-Wno-implicit-function-declaration"}
	// Observed and suppressed on 47 builders during testing.
	// e.g., asurada-cq: https://ci.chromium.org/b/8712322021989573537.
	case "app-text/ghostscript-gpl":
		return []string{"-Wno-int-conversion"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., staging-build-chromiumos-sdk: https://ci.chromium.org/b/8712322756730423329.
	case "app-text/xmlto":
		return []string{"-Wno-implicit-int"}
	// Observed and suppressed on 3 builders during testing.
	// e.g., betty-fuzzer-cq: https://ci.chromium.org/b/8712322022231622129.
	case "chromeos-base/chromeos-ec":
		return []string{"-Wno-deprecated-declarations"}
	// Observed and suppressed on 19 builders during testing.
	// e.g., betty-arc-r-container-cq: https://ci.chromium.org/b/8712322022102235857.
	case "chromeos-base/chromeos-fpmcu-bloonchipper-unittests":
		return []string{"-Wno-deprecated-declarations"}
	// Observed and suppressed on 19 builders during testing.
	// e.g., betty-arc-r-container-cq: https://ci.chromium.org/b/8712322022102235857.
	case "chromeos-base/chromeos-fpmcu-dartmonkey-unittests":
		return []string{"-Wno-deprecated-declarations"}
	// Observed and suppressed on 28 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "chromeos-base/chromeos-fpmcu-helipilot-unittests":
		return []string{"-Wno-deprecated-declarations", "-Wno-int-conversion"}
	// Observed and suppressed on 62 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "chromeos-base/drm-tests":
		return []string{"-Wno-incompatible-function-pointer-types", "-Wno-int-conversion"}
	// Observed and suppressed on 3 builders during testing.
	// e.g., brya-cq: https://ci.chromium.org/b/8712322022875644913.
	case "chromeos-base/epstps2iap":
		return []string{"-Wno-implicit-function-declaration"}
	// Observed and suppressed on 14 builders during testing.
	// e.g., brya-cq: https://ci.chromium.org/b/8712322022875644913.
	case "chromeos-base/fibocom-firmware":
		return []string{"-Wno-int-conversion"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., staging-build-chromiumos-sdk: https://ci.chromium.org/b/8712322756730423329.
	case "cross-arm-none-eabi/newlib":
		return []string{"-Wno-implicit-function-declaration", "-Wno-int-conversion"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., staging-build-chromiumos-sdk: https://ci.chromium.org/b/8712322756730423329.
	case "cross-armv7m-cros-eabi/newlib":
		return []string{"-Wno-implicit-function-declaration", "-Wno-int-conversion"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., staging-build-chromiumos-sdk: https://ci.chromium.org/b/8712322756730423329.
	case "cross-riscv32-cros-elf/newlib":
		return []string{"-Wno-implicit-function-declaration", "-Wno-int-conversion"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., fizz-labstation-cq: https://ci.chromium.org/b/8712322023911080081.
	case "dev-embedded/openocd":
		return []string{"-Wno-incompatible-function-pointer-types"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., staging-build-chromiumos-sdk: https://ci.chromium.org/b/8712322756730423329.
	case "dev-python/m2crypto":
		return []string{"-Wno-implicit-function-declaration"}
	// Observed and suppressed on 88 builders during testing.
	// e.g., amd64-generic-bazel-lite-cq: https://ci.chromium.org/b/8712322028887715809.
	case "dev-util/hdctools":
		return []string{"-Wno-unknown-warning-option"}
	// Observed and suppressed on 63 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "gnome-base/librsvg":
		return []string{"-Wno-incompatible-function-pointer-types"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., fatcat-cq: https://ci.chromium.org/b/8712322023708719137.
	case "media-libs/cros-camera-hal-internal":
		return []string{"-Wno-vla-cxx-extension"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., kukui-cq: https://ci.chromium.org/b/8712322024881464657.
	case "media-libs/cros-camera-hal-mtk":
		return []string{"-Wno-vla-cxx-extension"}
	// Observed and suppressed on 62 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "media-libs/freeimage":
		return []string{"-Wno-implicit-function-declaration"}
	// Observed and suppressed on 65 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "net-dialup/xl2tpd":
		return []string{"-Wno-int-conversion"}
	// Observed and suppressed on 44 builders during testing.
	// e.g., asurada-cq: https://ci.chromium.org/b/8712322021989573537.
	case "net-misc/fibocom-tools":
		return []string{"-Wno-int-conversion"}
	// Observed and suppressed on 9 builders during testing.
	// e.g., brox-cq: https://ci.chromium.org/b/8712322022691673841.
	case "net-misc/qdl":
		return []string{"-Wno-implicit-function-declaration"}
	// Observed and suppressed on 65 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "net-print/cups":
		return []string{"-Wno-int-conversion"}
	// Observed and suppressed on 60 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "net-print/cups-filter-rastertoescpos":
		return []string{"-Wno-deprecated-declarations"}
	// Observed and suppressed on 60 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "net-print/custom-cupsdrv":
		return []string{"-Wno-implicit-function-declaration"}
	// Observed and suppressed on 60 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "net-print/epson-inkjet-printer-colorworks":
		return []string{"-Wno-int-conversion"}
	// Observed and suppressed on 59 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "net-print/tsc-cupsdrv":
		return []string{"-Wno-implicit-function-declaration"}
	// Observed and suppressed on 65 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "net-proxy/tayga":
		return []string{"-Wno-int-conversion"}
	// Observed and suppressed on 65 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "net-wireless/bluez":
		return []string{"-Wno-incompatible-function-pointer-types"}
	// Observed and suppressed on 68 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "sys-apps/coreutils":
		return []string{"-Wno-incompatible-function-pointer-types"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., endeavour-cq: https://ci.chromium.org/b/8712322023457534401.
	case "sys-apps/logitech-updater":
		return []string{"-Wno-vla-cxx-extension"}
	// Observed and suppressed on 35 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "sys-apps/upstart":
		return []string{"-Wno-int-conversion"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., guybrush-cq: https://ci.chromium.org/b/8712322024069525057.
	case "sys-boot/amd-cezanne-fsp":
		return []string{"-Wno-unknown-warning-option"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., skyrim-cq: https://ci.chromium.org/b/8712322026145001825.
	case "sys-boot/amd-mendocino-fsp":
		return []string{"-Wno-unknown-warning-option"}
	// Observed and suppressed on 2 builders during testing.
	// e.g., brask-cq: https://ci.chromium.org/b/8712322022540760321.
	case "sys-boot/intel-adlfsp":
		return []string{"-Wno-unknown-warning-option"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., nissa-cq: https://ci.chromium.org/b/8712322025081100593.
	case "sys-boot/intel-adlnfsp":
		return []string{"-Wno-unknown-warning-option"}
	// Observed and suppressed on 2 builders during testing.
	// e.g., hatch-cq: https://ci.chromium.org/b/8712322024723137313.
	case "sys-boot/intel-cmlfsp":
		return []string{"-Wno-unknown-warning-option"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., dedede-cq: https://ci.chromium.org/b/8712322023242142449.
	case "sys-boot/intel-jslfsp":
		return []string{"-Wno-unknown-warning-option"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., volteer-cq: https://ci.chromium.org/b/8712322027744687841.
	case "sys-boot/intel-tglfsp":
		return []string{"-Wno-unknown-warning-option"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., nissa-cq: https://ci.chromium.org/b/8712322025081100593.
	case "sys-boot/intel-twlfsp":
		return []string{"-Wno-unknown-warning-option"}
	// Observed and suppressed on 39 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "sys-firmware/edk2-ovmf-crosvm":
		return []string{"-Wno-unknown-warning-option"}
	// Observed and suppressed on 6 builders during testing.
	// e.g., amd64-generic-kernel-v6_6-buildtest-cq: https://ci.chromium.org/b/8712322019074416753.
	case "sys-kernel/chromeos-kernel-6_6":
		return []string{"-Wno-int-conversion"}
	// Observed and suppressed on 63 builders during testing.
	// e.g., amd64-generic-cq: https://ci.chromium.org/b/8712322028830920497.
	case "sys-process/lsof":
		return []string{"-Wno-implicit-int"}
	// Observed and suppressed on 23 builders during testing.
	// e.g., atlas-cq: https://ci.chromium.org/b/8712322022030315345.
	case "x11-libs/libva-intel-media-driver":
		return []string{"-Wno-vla-cxx-extension"}
	default:
		return nil
	}
}
