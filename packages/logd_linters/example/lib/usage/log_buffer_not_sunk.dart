// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: cascade_invocations

/// Integration test for C3 — `logd_log_buffer_not_sunk`.
library;

import 'package:logd/logd.dart';

void badUsage(final Logger logger) {
  // expect_lint: logd_log_buffer_not_sunk
  final buf = logger.debugBuffer!;
  buf.write('testing');
}

void goodUsage(final Logger logger) {
  final buf = logger.debugBuffer!;
  buf.write('testing');
  buf.sink();
}
