// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule C1 — `logd_avoid_print_sink_in_production`.
library;

import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/ast_helpers.dart';
import '../../utils/type_checkers.dart';

/// **C1** — Fires when [PrintSink] is used as the `sink:` argument to a
/// [Handler] constructor in non-test code.
///
/// [PrintSink] bypasses the full pipeline encoder (no ANSI, no structured
/// output) and calls `print()` directly. It is intended only for quick
/// debugging and test scenarios.
///
/// ### Bad
/// ```dart
/// final handler = Handler(
///   formatter: StructuredFormatter(metadata: {}),
///   sink: PrintSink(), // ← C1
/// );
/// ```
///
/// ### Good
/// ```dart
/// final handler = Handler(
///   formatter: StructuredFormatter(metadata: {}),
///   sink: ConsoleSink(), // ✓ full pipeline, ANSI-aware
/// );
/// ```
class AvoidPrintSinkInProduction extends DartLintRule {
  const AvoidPrintSinkInProduction() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_avoid_print_sink_in_production',
    problemMessage:
        'PrintSink bypasses the full encoder pipeline and is intended for '
        'debugging only. Use ConsoleSink or FileSink in production code.',
    correctionMessage: "Replace 'PrintSink()' with 'ConsoleSink()'.",
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final ErrorReporter reporter,
    final CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((final node) {
      // Skip test files.
      if (isTestFile(resolver.path)) {
        return;
      }

      final type = node.staticType;
      if (type == null) {
        return;
      }
      if (!printSinkChecker.isExactlyType(type)) {
        return;
      }

      reporter.atNode(node, _code);
    });
  }

  @override
  List<Fix> getFixes() => [_PrintSinkFix()];
}

class _PrintSinkFix extends DartFix {
  @override
  void run(
    final CustomLintResolver resolver,
    final ChangeReporter reporter,
    final CustomLintContext context,
    final AnalysisError analysisError,
    final List<AnalysisError> others,
  ) {
    context.registry.addInstanceCreationExpression((final node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) {
        return;
      }
      final type = node.staticType;
      if (type == null) {
        return;
      }
      if (!printSinkChecker.isExactlyType(type)) {
        return;
      }

      reporter
          .createChangeBuilder(
        message: "Replace with 'ConsoleSink()'",
        priority: 80,
      )
          .addDartFileEdit((final builder) {
        builder.addSimpleReplacement(node.sourceRange, 'ConsoleSink()');
      });
    });
  }
}
