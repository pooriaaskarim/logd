// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule C3 — `logd_log_buffer_not_sunk` (experimental).
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/type_checkers.dart';

/// **C3 (experimental)** — Fires when a [LogBuffer] is obtained via
/// `logger.buffer(...)` but its `sink()` method is not called within the
/// same visible scope.
///
/// An un-sunk buffer causes the GC finalizer to trigger `LoggerMetrics`
/// `_bufferLeaks++` and may silently drop data if `autoSinkBuffer` is
/// `false`. Explicit `sink()` is always preferred.
///
/// This rule performs a **single-function scope scan**. It will not detect
/// leaks where the buffer is passed to another function without sinking.
///
/// ### Bad
/// ```dart
/// Future<void> doWork() async {
///   final buf = logger.buffer(LogLevel.debug);
///   buf.write('work started');
///   // ← C3: buf.sink() never called
/// }
/// ```
///
/// ### Good
/// ```dart
/// Future<void> doWork() async {
///   final buf = logger.buffer(LogLevel.debug);
///   buf.write('work started');
///   buf.sink(); // ✓
/// }
/// ```
///
/// > **Note**: Marked `experimental`. Promote to stable after validation
/// > against real consumer code in v2.
class LogBufferNotSunk extends DartLintRule {
  const LogBufferNotSunk() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_log_buffer_not_sunk',
    problemMessage: 'LogBuffer obtained from logger.buffer() was never sunk. '
        'Call buf.sink() to flush the buffer and prevent data loss.',
    correctionMessage: "Add 'buf.sink()' before the buffer goes out of scope.",
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final ErrorReporter reporter,
    final CustomLintContext context,
  ) {
    // Track local variable name → the VariableDeclaration node.
    final buffers = <String, VariableDeclaration>{};

    context.registry.addVariableDeclaration((final node) {
      final init = node.initializer;
      if (init == null) {
        return;
      }
      final type = init.staticType;
      if (type == null) {
        return;
      }
      if (!logBufferChecker.isAssignableFromType(type)) {
        return;
      }

      buffers[node.name.lexeme] = node;
    });

    context.registry.addMethodInvocation((final node) {
      if (node.methodName.name != 'sink') {
        return;
      }
      final target = node.target;
      if (target is SimpleIdentifier) {
        buffers.remove(target.name);
      }
    });

    // At the end of each function body, flag any un-sunk buffers.
    context.registry.addFunctionBody((final _) {
      for (final entry in buffers.entries) {
        reporter.atNode(entry.value, _code);
      }
      buffers.clear();
    });
  }

  @override
  List<Fix> getFixes() => [_SinkFix()];
}

class _SinkFix extends DartFix {
  @override
  void run(
    final CustomLintResolver resolver,
    final ChangeReporter reporter,
    final CustomLintContext context,
    final AnalysisError analysisError,
    final List<AnalysisError> others,
  ) {
    context.registry.addVariableDeclaration((final node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) {
        return;
      }
      final varName = node.name.lexeme;

      reporter
          .createChangeBuilder(
        message: "Add '$varName.sink()'",
        priority: 80,
      )
          .addDartFileEdit((final builder) {
        // Insert sink() call on the line after the variable declaration.
        final offset = node.end;
        builder.addSimpleInsertion(offset, '\n    $varName.sink();');
      });
    });
  }
}
