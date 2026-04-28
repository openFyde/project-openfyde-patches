# Copyright 2025 The FydeOS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Remove debug printf left in CHROMIUM-losetup-autoclear.patch
# which causes "FINDING FREE!!!" to be printed on every `losetup -f` call.
post_src_prepare() {
	sed -i '/printf("FINDING FREE!!!\\n");/d' sys-utils/losetup.c
}
