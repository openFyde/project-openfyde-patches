# Copyright 2020 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="d93d7a9e81c01b800b7304e7dce0005fe1139e86"
CROS_WORKON_TREE="6ce2ccd87a61c221e8e063cb6b9e2bd598ea4915"
CROS_WORKON_PROJECT="chromiumos/third_party/kernel"
CROS_WORKON_LOCALNAME="kernel/upstream"

# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit cros-workon cros-kernel

HOMEPAGE="https://www.chromium.org/chromium-os/chromiumos-design-docs/chromium-os-kernel"
DESCRIPTION="Chrome OS Linux Kernel latest upstream rc"
KEYWORDS="*"
