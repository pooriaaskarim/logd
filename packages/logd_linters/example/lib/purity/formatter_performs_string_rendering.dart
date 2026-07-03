// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Integration test for B1 — `logd_formatter_performs_string_rendering`.
library;

import 'dart:io' as io;

import 'package:logd/logd.dart';
import 'package:meta/meta.dart';

@immutable
class BadFormatter implements LogFormatter {
  const BadFormatter({required this.metadata});

  @override
  final Set<LogMetadata> metadata;

  @override
  void format(
    final LogEntry entry,
    final LogDocument document,
    final LogPipelineFactory factory,
  ) {
    // expect_lint: logd_formatter_performs_string_rendering
    final width = io.stdout.terminalColumns;
    document.text(entry.message.substring(0, width));

    // expect_lint: logd_formatter_performs_string_rendering
    io.stdout.writeln('Direct write');
  }
}

@immutable
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
    document.text(entry.message);
  }
}
