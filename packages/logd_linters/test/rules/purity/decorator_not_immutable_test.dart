// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Tests for B2 — `logd_decorator_not_immutable`.
library;

import 'package:logd/logd.dart';
import 'package:meta/meta.dart';

// expect_lint: logd_decorator_not_immutable
class MutableDecorator extends ContentDecorator {
  MutableDecorator(this.prefix);

  String prefix; // Mutable field

  @override
  void decorate(
    final LogDocument document,
    final LogEntry entry,
    final LogPipelineFactory factory,
  ) {
    document.text(prefix);
  }
}

// expect_lint: logd_decorator_not_immutable
class MissingAnnotationDecorator extends ContentDecorator {
  const MissingAnnotationDecorator({required this.prefix});

  final String prefix;

  @override
  void decorate(
    final LogDocument document,
    final LogEntry entry,
    final LogPipelineFactory factory,
  ) {
    document.text(prefix);
  }
}

@immutable
class ValidDecorator extends ContentDecorator {
  const ValidDecorator({required this.prefix});

  final String prefix;

  @override
  void decorate(
    final LogDocument document,
    final LogEntry entry,
    final LogPipelineFactory factory,
  ) {
    document.text(prefix);
  }
}

void main() {}
