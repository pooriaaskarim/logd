// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Tests for A2 — `logd_missing_release_in_engine`.
///
/// Uses the `// expect_lint:` directive from `custom_lint_builder`.
library;

import 'package:logd/logd.dart';

// ---------------------------------------------------------------------------
// VIOLATION: execute() body without try-finally
// ---------------------------------------------------------------------------

// expect_lint: logd_missing_release_in_engine
class LeakyEngine implements LogEngine {
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

void main() {}
