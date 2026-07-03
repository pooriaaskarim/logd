// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// Integration test for B2 — `logd_decorator_not_immutable`.
library;

import 'package:logd/logd.dart';
import 'package:meta/meta.dart';

// expect_lint: logd_decorator_not_immutable
class MutableDecorator extends ContentDecorator {
  MutableDecorator(this.prefix);

  // ignore: prefer_final_fields
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
