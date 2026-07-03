// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: cascade_invocations

/// Tests for A3 — `logd_checkout_without_release`.
library;

import 'package:logd/logd.dart';

void badUsage(final LogPipelineFactory factory) {
  // expect_lint: logd_checkout_without_release
  final doc = factory.checkoutDocument();
  doc.text('testing');
}

void goodUsage(final LogPipelineFactory factory) {
  final doc = factory.checkoutDocument();
  try {
    doc.text('testing');
  } finally {
    doc.releaseRecursive(factory);
  }
}

void main() {}
