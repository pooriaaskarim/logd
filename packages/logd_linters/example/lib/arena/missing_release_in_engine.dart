// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Integration test for A2 — `logd_missing_release_in_engine`.
library;

import 'package:logd/logd.dart';

// ---------------------------------------------------------------------------
// VIOLATION: execute() body without try-finally
// ---------------------------------------------------------------------------

class LeakyEngine implements LogEngine {
  @override
  LogPipelineFactory get factory => const StandardEngine().factory;

  @override
  // expect_lint: logd_missing_release_in_engine
  Future<void> execute(
    final LogEntry entry,
    final LogFormatter formatter,
    final List<LogDecorator> decorators,
    final LogSink sink,
  ) async {
    // expect_lint: logd_checkout_without_release
    final doc = factory.checkoutDocument();
    formatter.format(entry, doc, factory);
    await sink.output(doc, entry, entry.level, factory);
    // ← Missing try-finally + releaseRecursive
  }
}

// ---------------------------------------------------------------------------
// OK: correct try-finally pattern
// ---------------------------------------------------------------------------

class CorrectEngine implements LogEngine {
  @override
  LogPipelineFactory get factory => const StandardEngine().factory;

  @override
  Future<void> execute(
    final LogEntry entry,
    final LogFormatter formatter,
    final List<LogDecorator> decorators,
    final LogSink sink,
  ) async {
    final doc = factory.checkoutDocument();
    try {
      formatter.format(entry, doc, factory);
      await sink.output(doc, entry, entry.level, factory);
    } finally {
      doc.releaseRecursive(factory); // ✓
    }
  }
}
