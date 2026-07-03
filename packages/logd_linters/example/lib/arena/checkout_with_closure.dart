// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Integration test for scope-based false positives in checkout_without_release.
library;

import 'package:logd/logd.dart';

void outerFunction(final LogPipelineFactory factory) {
  final doc = factory.checkoutDocument();
  try {
    final list = [1, 2, 3];
    // ignore: avoid_function_literals_in_foreach_calls
    list.forEach((final x) {
      // nested closure: its exit will trigger addFunctionBody in the old rule,
      // falsely reporting doc as unreleased and clearing the checkouts map.
    });
  } finally {
    doc.releaseRecursive(factory);
  }
}
