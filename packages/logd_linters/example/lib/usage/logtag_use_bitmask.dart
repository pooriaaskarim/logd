// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Integration test for C2 — `logd_logtag_use_bitmask`.
library;

import 'package:logd/logd.dart';

void testMethod(final int tags) {
  // expect_lint: logd_logtag_use_bitmask
  if (tags == LogTag.error) {
    // violation
  }

  // expect_lint: logd_logtag_use_bitmask
  if (tags != LogTag.timestamp) {
    // violation
  }

  // OK: Bitwise & check
  if (tags & LogTag.error != 0) {
    // correct
  }

  // OK: Bitwise & check
  if ((tags & LogTag.timestamp) == 0) {
    // correct
  }
}
