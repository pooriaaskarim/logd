// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule D1 — `logd_freeze_on_unconfigured_logger`.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/ast_helpers.dart';

/// **D1** — Fires when `freezeInheritance()` is called directly on the return
/// value of `Logger.get(name)` without any intervening `Logger.configure`
/// call — the "ghost node" pattern.
///
/// `Logger.get(name)` silently materialises an empty `LoggerConfig` if the
/// logger has never been configured. Immediately calling `freezeInheritance()`
/// on such a ghost node copies globally-resolved values into all descendants,
/// making the `exportHierarchy()` output misleading (ghost appears configured).
///
/// ### Bad
/// ```dart
/// Logger.get('app').freezeInheritance(); // ← D1: ghost node freeze
/// ```
///
/// ### Good
/// ```dart
/// Logger.configure('app', logLevel: LogLevel.debug);
/// Logger.get('app').freezeInheritance(); // ✓ explicit config first
/// ```
///
/// > **Note**: This rule uses a simple single-statement cascade pattern
/// > detector. It will not catch multi-statement ghost-freeze sequences where
/// > `get` and `freezeInheritance` are on separate lines without configure in
/// > between. That analysis is deferred to v2.
class FreezeOnUnconfiguredLogger extends DartLintRule {
  const FreezeOnUnconfiguredLogger() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_freeze_on_unconfigured_logger',
    problemMessage:
        'freezeInheritance() called on a Logger that has never been '
        'configured. This creates a ghost node that misrepresents the '
        'hierarchy in exportHierarchy() and printHierarchy().',
    correctionMessage:
        'Call Logger.configure(name, ...) before freezeInheritance(), '
        'or use the InternalLogger.warning to audit ghost nodes.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final ErrorReporter reporter,
    final CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((final node) {
      if (node.methodName.name != 'freezeInheritance') {
        return;
      }

      // Check if the target is a direct Logger.get(...) call.
      final target = node.target;
      if (target is! MethodInvocation) {
        return;
      }
      if (!isStaticCall(target, 'Logger', 'get')) {
        return;
      }

      reporter.atNode(node, _code);
    });
  }
}
