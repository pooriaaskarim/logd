// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule C2 — `logd_logtag_use_bitmask`.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// **C2** — Fires when a `LogTag` constant is compared using `==` or `!=`
/// instead of a bitwise `&` check.
///
/// `LogTag` values are int bitmasks. Using equality comparison (`==`) only
/// matches an exact single-tag value and silently fails for compound tags
/// (e.g., `LogTag.error | LogTag.timestamp`).
///
/// ### Bad
/// ```dart
/// if (entry.tags == LogTag.error) { ... }    // ← C2
/// if (entry.tags != LogTag.timestamp) { ... } // ← C2
/// ```
///
/// ### Good
/// ```dart
/// if (entry.tags & LogTag.error != 0) { ... }     // ✓ bitmask check
/// if (entry.tags & LogTag.timestamp == 0) { ... }  // ✓ bitmask absence
/// ```
class LogtagUseBitmask extends DartLintRule {
  const LogtagUseBitmask() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_logtag_use_bitmask',
    problemMessage:
        'LogTag values are int bitmasks. Use bitwise & instead of == or != '
        'to avoid false negatives with compound tags.',
    correctionMessage:
        "Replace 'tags == LogTag.x' with 'tags & LogTag.x != 0'.",
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final ErrorReporter reporter,
    final CustomLintContext context,
  ) {
    context.registry.addBinaryExpression((final node) {
      final op = node.operator.type.lexeme;
      if (op != '==' && op != '!=') {
        return;
      }

      if (_referencesLogTag(node.leftOperand) ||
          _referencesLogTag(node.rightOperand)) {
        reporter.atNode(node, _code);
      }
    });
  }

  bool _referencesLogTag(final Expression expr) {
    if (expr is! PrefixedIdentifier && expr is! PropertyAccess) {
      return false;
    }
    final type = expr.staticType;
    if (type == null) {
      return false;
    }
    // LogTag constants are ints on the LogTag class. Check the enclosing
    // element name rather than the type (which is just int).
    if (expr is PrefixedIdentifier) {
      return expr.prefix.name == 'LogTag';
    }
    if (expr is PropertyAccess) {
      final target = expr.target;
      if (target is SimpleIdentifier) {
        return target.name == 'LogTag';
      }
    }
    return false;
  }

  @override
  List<Fix> getFixes() => [_BitmaskFix()];
}

class _BitmaskFix extends DartFix {
  @override
  void run(
    final CustomLintResolver resolver,
    final ChangeReporter reporter,
    final CustomLintContext context,
    final AnalysisError analysisError,
    final List<AnalysisError> others,
  ) {
    context.registry.addBinaryExpression((final node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) {
        return;
      }

      final op = node.operator.type.lexeme;
      if (op != '==' && op != '!=') {
        return;
      }

      // Determine which operand is the LogTag reference.
      Expression tagExpr;
      Expression tagsExpr;
      if (_isLogTagRef(node.rightOperand)) {
        tagExpr = node.rightOperand;
        tagsExpr = node.leftOperand;
      } else if (_isLogTagRef(node.leftOperand)) {
        tagExpr = node.leftOperand;
        tagsExpr = node.rightOperand;
      } else {
        return;
      }

      final resultOp = op == '==' ? '!= 0' : '== 0';
      final replacement =
          '${tagsExpr.toSource()} & ${tagExpr.toSource()} $resultOp';

      reporter
          .createChangeBuilder(
        message: 'Use bitwise & check',
        priority: 80,
      )
          .addDartFileEdit((final builder) {
        builder.addSimpleReplacement(node.sourceRange, replacement);
      });
    });
  }

  bool _isLogTagRef(final Expression expr) {
    if (expr is PrefixedIdentifier) {
      return expr.prefix.name == 'LogTag';
    }
    if (expr is PropertyAccess) {
      final t = expr.target;
      return t is SimpleIdentifier && t.name == 'LogTag';
    }
    return false;
  }
}
