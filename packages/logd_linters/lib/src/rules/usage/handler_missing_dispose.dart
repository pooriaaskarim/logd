// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule C6 — `logd_handler_missing_dispose`.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/type_checkers.dart';

/// **C6** — Fires when an [AsyncHandler] (or stateful [Handler] subclass) is
/// instantiated in a scope without a corresponding call to `dispose()`
/// within the same scope.
///
/// Failing to call `dispose()` on an [AsyncHandler] leaks the underlying
/// background worker isolate and control ports.
///
/// ### Bad
/// ```dart
/// Future<void> setupLogger() async {
///   final handler = AsyncHandler(
///     formatter: const PlainFormatter(),
///     sink: ConsoleSink(),
///   );
///   Logger.configure('app', handlers: [handler]);
///   // ← C6: handler.dispose() never called
/// }
/// ```
///
/// ### Good
/// ```dart
/// Future<void> setupLogger() async {
///   final handler = AsyncHandler(
///     formatter: const PlainFormatter(),
///     sink: ConsoleSink(),
///   );
///   Logger.configure('app', handlers: [handler]);
///   await handler.dispose(); // ✓
/// }
/// ```
class HandlerMissingDispose extends DartLintRule {
  const HandlerMissingDispose() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_handler_missing_dispose',
    problemMessage:
        'AsyncHandler is instantiated but dispose() is never called in scope. '
        'Call await handler.dispose() to release background worker isolates and IPC ports.',
    correctionMessage:
        "Add 'await handler.dispose();' before the instance is abandoned.",
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final ErrorReporter reporter,
    final CustomLintContext context,
  ) {
    final handlers = <String, VariableDeclaration>{};

    context.registry.addVariableDeclaration((final node) {
      // Ignore class field declarations — their lifecycle is tied to the class instance.
      if (node.parent?.parent is FieldDeclaration) {
        return;
      }

      final init = node.initializer;
      if (init == null) {
        return;
      }
      final type = init.staticType;
      if (type == null) {
        return;
      }
      if (!asyncHandlerChecker.isAssignableFromType(type)) {
        return;
      }

      handlers[node.name.lexeme] = node;
    });

    context.registry.addMethodInvocation((final node) {
      if (node.methodName.name != 'dispose') {
        return;
      }
      // realTarget handles both standard method calls (handler.dispose())
      // and cascade expressions (handler..dispose()).
      final target = node.realTarget;
      if (target is SimpleIdentifier) {
        handlers.remove(target.name);
      }
    });

    context.registry.addFunctionBody((final _) {
      for (final entry in handlers.entries) {
        reporter.atNode(entry.value, _code);
      }
      handlers.clear();
    });
  }

  @override
  List<Fix> getFixes() => [_DisposeFix()];
}

class _DisposeFix extends DartFix {
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
        message: "Add 'await $varName.dispose()'",
        priority: 80,
      )
          .addDartFileEdit((final builder) {
        final offset = node.end;
        builder.addSimpleInsertion(offset, '\n    await $varName.dispose();');
      });
    });
  }
}
