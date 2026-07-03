// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Integration test for B3 — `logd_formatter_not_immutable`.
library;

import 'package:logd/logd.dart';
import 'package:meta/meta.dart';

// expect_lint: logd_formatter_not_immutable
class MutableFormatter implements LogFormatter {
  MutableFormatter({required this.metadata});

  @override
  final Set<LogMetadata> metadata;

  // ignore: prefer_final_fields
  int callCount = 0; // Mutable field

  @override
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogPipelineFactory factory,
  ) {
    callCount++;
    document.text(entry.message);
  }
}

// expect_lint: logd_formatter_not_immutable
class MissingAnnotationFormatter implements LogFormatter {
  const MissingAnnotationFormatter({required this.metadata});

  @override
  final Set<LogMetadata> metadata;

  @override
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogPipelineFactory factory,
  ) {
    document.text(entry.message);
  }
}

@immutable
class ValidFormatter implements LogFormatter {
  const ValidFormatter({required this.metadata});

  @override
  final Set<LogMetadata> metadata;

  @override
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogPipelineFactory factory,
  ) {
    document.text(entry.message);
  }
}
