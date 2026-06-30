// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule C5 — `logd_handler_missing_engine`.
library;

import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/ast_helpers.dart';
import '../../utils/type_checkers.dart';

/// **C5** — Fires when a [Handler] is constructed with an [IsolateSink] or
/// [NativeIsolateSink] as its `sink:` argument but the `engine:` parameter
/// is absent (defaulting to [StandardEngine]).
///
/// [IsolateSink] and [NativeIsolateSink] are designed for high-throughput
/// async I/O. Without [ArenaEngine], every log cycle allocates a fresh
/// [LogDocument] from the heap, defeating the sink's performance benefit.
///
/// ### Bad
/// ```dart
/// final handler = Handler(
///   formatter: StructuredFormatter(metadata: {}),
///   sink: IsolateSink(worker), // ← C5: missing engine: ArenaEngine()
/// );
/// ```
///
/// ### Good
/// ```dart
/// final handler = Handler(
///   formatter: StructuredFormatter(metadata: {}),
///   sink: IsolateSink(worker),
///   engine: ArenaEngine(), // ✓
/// );
/// ```
class HandlerMissingEngine extends DartLintRule {
  const HandlerMissingEngine() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_handler_missing_engine',
    problemMessage:
        'IsolateSink / NativeIsolateSink are high-throughput sinks that '
        'work best with ArenaEngine. Add engine: ArenaEngine() to Handler.',
    correctionMessage:
        "Add 'engine: ArenaEngine()' to the Handler constructor.",
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final ErrorReporter reporter,
    final CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((final node) {
      final type = node.staticType;
      if (type == null) {
        return;
      }
      if (!handlerChecker.isExactlyType(type)) {
        return;
      }

      final args = node.argumentList;

      // Check if engine: is already specified.
      if (namedArg(args, 'engine') != null) {
        return;
      }

      // Check if sink: is an isolate sink type.
      final sinkArg = namedArg(args, 'sink');
      if (sinkArg == null) {
        return;
      }

      final sinkType = sinkArg.expression.staticType;
      if (sinkType == null) {
        return;
      }

      final isIsolateSink = isolateSinkChecker.isAssignableFromType(sinkType) ||
          nativeIsolateSinkChecker.isAssignableFromType(sinkType);
      if (!isIsolateSink) {
        return;
      }

      reporter.atNode(node, _code);
    });
  }

  @override
  List<Fix> getFixes() => [_AddArenaEngineFix()];
}

class _AddArenaEngineFix extends DartFix {
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
      if (!handlerChecker.isExactlyType(type)) {
        return;
      }

      reporter
          .createChangeBuilder(
        message: "Add 'engine: ArenaEngine()'",
        priority: 80,
      )
          .addDartFileEdit((final builder) {
        // Append engine: ArenaEngine() before the closing paren.
        final closingParen = node.argumentList.rightParenthesis;
        builder.addSimpleInsertion(
          closingParen.offset,
          '\n    engine: ArenaEngine(),\n  ',
        );
      });
    });
  }
}
