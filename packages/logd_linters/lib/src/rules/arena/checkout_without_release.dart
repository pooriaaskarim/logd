// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule A3 — `logd_checkout_without_release`.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/type_checkers.dart';

/// **A3** — Fires when a `checkout*()` call result is stored in a local
/// variable that has no corresponding `release()` or `releaseRecursive()`
/// call visible in the same scope.
///
/// Most common in test code that manually exercises the pipeline.
///
/// ### Bad
/// ```dart
/// test('renders header', () {
///   final doc = factory.checkoutDocument(); // ← A3: no release
///   // ...assertions...
/// });
/// ```
///
/// ### Good
/// ```dart
/// test('renders header', () {
///   final doc = factory.checkoutDocument();
///   try {
///     // ...assertions...
///   } finally {
///     doc.releaseRecursive(factory); // ✓
///   }
/// });
/// ```
///
/// > **Note**: This rule performs a simple single-function scan (it does not
/// > trace cross-call-site dataflow). It may produce false negatives when the
/// > release happens in a helper method.
class CheckoutWithoutRelease extends DartLintRule {
  const CheckoutWithoutRelease() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_checkout_without_release',
    problemMessage:
        'A checked-out LogDocument has no visible releaseRecursive() call '
        'in this scope. This may cause arena pool exhaustion.',
    correctionMessage:
        'Call doc.releaseRecursive(factory) in a finally block after use.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  /// Names of all factory checkout methods that return pooled arena objects.
  static const _checkoutMethods = {
    'checkoutDocument',
    'checkoutHeader',
    'checkoutMessage',
    'checkoutError',
    'checkoutFooter',
    'checkoutMetadata',
    'checkoutBox',
    'checkoutIndentation',
    'checkoutGroup',
    'checkoutDecorated',
    'checkoutParagraph',
    'checkoutRow',
    'checkoutSection',
    'checkoutFiller',
    'checkoutMap',
    'checkoutList',
    'checkoutAlignment',
    'checkoutTable',
    'checkoutTableRow',
    'checkoutTableCell',
    'checkoutPhysicalDocument',
    'checkoutPhysicalLine',
  };

  @override
  void run(
    final CustomLintResolver resolver,
    final ErrorReporter reporter,
    final CustomLintContext context,
  ) {
    // Track: local variable name → checkout MethodInvocation node.
    final checkouts = <String, MethodInvocation>{};

    context.registry.addVariableDeclaration((final node) {
      final init = node.initializer;
      if (init is! MethodInvocation) {
        return;
      }
      if (!_checkoutMethods.contains(init.methodName.name)) {
        return;
      }

      // Only track calls on a LogPipelineFactory receiver.
      final targetType = init.target?.staticType;
      if (targetType != null &&
          !logPipelineFactoryChecker.isAssignableFromType(targetType)) {
        return;
      }

      final name = node.name.lexeme;
      checkouts[name] = init;
    });

    context.registry.addMethodInvocation((final node) {
      final name = node.methodName.name;
      if (name != 'releaseRecursive' && name != 'release') {
        return;
      }

      // Mark the variable as released.
      final target = node.target;
      if (target is SimpleIdentifier) {
        checkouts.remove(target.name);
      }
    });

    // After visiting the function body, anything remaining in checkouts
    // was never released.
    context.registry.addFunctionBody((final _) {
      for (final entry in checkouts.entries) {
        reporter.atNode(entry.value, _code);
      }
      checkouts.clear();
    });
  }
}
