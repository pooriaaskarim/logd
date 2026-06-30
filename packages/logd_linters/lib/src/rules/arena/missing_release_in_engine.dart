// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule A2 — `logd_missing_release_in_engine`.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/ast_helpers.dart';
import '../../utils/type_checkers.dart';

/// **A2** — Fires when a class implementing [LogEngine] has an `execute`
/// method body that does not contain a `try-finally` block with a
/// `releaseRecursive` call.
///
/// Every custom engine MUST call `document.releaseRecursive(factory)` in a
/// `finally` block. Without this, any exception in the formatter or sink
/// leaves the arena in a partially-filled, corrupted state.
///
/// ### Bad
/// ```dart
/// class LeakyEngine implements LogEngine {
///   @override
///   Future<void> execute(entry, formatter, decorators, sink) async {
///     final doc = factory.checkoutDocument();
///     formatter.format(entry, doc, factory);
///     await sink.output(doc, entry, entry.level, factory);
///     doc.releaseRecursive(factory); // ← A2: not in a finally block
///   }
/// }
/// ```
///
/// ### Good
/// ```dart
/// @override
/// Future<void> execute(...) async {
///   final doc = factory.checkoutDocument();
///   try {
///     formatter.format(entry, doc, factory);
///     await sink.output(doc, entry, entry.level, factory);
///   } finally {
///     doc.releaseRecursive(factory); // ✓
///   }
/// }
/// ```
class MissingReleaseInEngine extends DartLintRule {
  const MissingReleaseInEngine() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_missing_release_in_engine',
    problemMessage:
        'LogEngine.execute() must call document.releaseRecursive(factory) '
        'inside a try-finally block to guarantee arena cleanup on exceptions.',
    correctionMessage: 'Wrap the execute body in try-finally and call '
        'document.releaseRecursive(factory) in the finally block.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final ErrorReporter reporter,
    final CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((final classDecl) {
      final element = classDecl.declaredFragment?.element;
      if (element == null) {
        return;
      }
      if (!logEngineChecker.isSuperOf(element)) {
        return;
      }

      for (final member in classDecl.members) {
        if (member is MethodDeclaration && member.name.lexeme == 'execute') {
          final body = member.body;
          if (body is BlockFunctionBody) {
            final hasRelease =
                hasTryFinallyWithCall(body.block, 'releaseRecursive');
            if (!hasRelease) {
              reporter.atToken(member.name, _code);
            }
          }
        }
      }
    });
  }
}
