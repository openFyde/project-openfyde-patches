// Copyright 2025 The ChromiumOS Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package main

func warningSuppressionsForLLVM_r563880(packageNameAndCategory string) []string {
	switch packageNameAndCategory {
	// Observed and suppressed on 3 builders during testing.
	// e.g., fatcat-cq: https://ci.chromium.org/b/8715339982079177585.
	case "chromeos-base/intel-openvino":
		return []string{"-Wno-deprecated-literal-operator"}
	// Observed and suppressed on 7 builders during testing.
	// e.g., brox-cq: https://ci.chromium.org/b/8715339980931440017.
	case "chromeos-base/odml":
		return []string{"-Wno-unused-private-field"}
	// Observed and suppressed on 1 builder during testing.
	// e.g., arm-generic-cq: https://ci.chromium.org/b/8715339977521747697.
	case "dev-python/numpy":
		return []string{"-Wno-unsupported-floating-point-opt"}
	// Observed on many builders during testing.
	// e.g., atlas-cq https://cr-buildbucket.appspot.com/build/8714855299967095297
	case "media-libs/dlm":
		return []string{"-Wno-deprecated-literal-operator"}
	// Observed and suppressed on 39 builders during testing.
	// e.g., asurada-cq: https://ci.chromium.org/b/8715339979823410017.
	case "sys-cluster/fcp":
		return []string{"-Wno-invalid-specialization"}
	default:
		return nil
	}
}
