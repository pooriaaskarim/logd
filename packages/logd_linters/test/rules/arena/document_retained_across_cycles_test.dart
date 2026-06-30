// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Tests for A1 — `logd_document_retained_across_cycles`.
library;

import 'package:logd/logd.dart';

class BadFormatter implements LogFormatter {
  const BadFormatter({required this.metadata});

  @override
  final Set<LogMetadata> metadata;

  // Formatter instances are shared; retaining document in a field is a violation
  // ignore: unused_field
  static LogDocument? _lastDoc;

  @override
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogPipelineFactory factory,
  ) {
    // expect_lint: logd_document_retained_across_cycles
    _lastDoc = document;
    document.text(entry.message);
  }
}

class GoodFormatter implements LogFormatter {
  const GoodFormatter({required this.metadata});

  @override
  final Set<LogMetadata> metadata;

  @override
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogPipelineFactory factory,
  ) {
    // Correct usage
    document.text(entry.message);
  }
}

void main() {}
