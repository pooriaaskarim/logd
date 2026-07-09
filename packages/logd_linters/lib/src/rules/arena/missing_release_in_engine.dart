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
      if (!logEngineChecker.isAssignableFrom(element)) {
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

  @override
  List<Fix> getFixes() => [_WrapInTryFinallyFix()];
}

class _WrapInTryFinallyFix extends DartFix {
  _WrapInTryFinallyFix();

  @override
  void run(
    final CustomLintResolver resolver,
    final ChangeReporter reporter,
    final CustomLintContext context,
    final AnalysisError analysisError,
    final List<AnalysisError> others,
  ) {
    context.registry.addMethodDeclaration((final member) {
      if (member.name.lexeme != 'execute') {
        return;
      }
      if (!analysisError.sourceRange.intersects(member.name.sourceRange)) {
        return;
      }

      final body = member.body;
      if (body is! BlockFunctionBody) {
        return;
      }

      final block = body.block;

      // 1. Identify checkout statement and doc variable name
      VariableDeclaration? checkoutVar;
      Statement? checkoutStmt;
      for (final stmt in block.statements) {
        if (stmt is VariableDeclarationStatement) {
          for (final variable in stmt.variables.variables) {
            final init = variable.initializer;
            if (init is MethodInvocation &&
                init.methodName.name == 'checkoutDocument') {
              checkoutVar = variable;
              checkoutStmt = stmt;
              break;
            }
          }
        }
        if (checkoutVar != null) {
          break;
        }
      }

      final docName = checkoutVar?.name.lexeme ?? 'doc';

      // 2. Identify and separate statements
      final beforeOrIncludingCheckout = <Statement>[];
      final targetStatements = <Statement>[];
      bool seenCheckout = false;

      for (final stmt in block.statements) {
        if (checkoutStmt != null) {
          if (!seenCheckout) {
            beforeOrIncludingCheckout.add(stmt);
            if (stmt == checkoutStmt) {
              seenCheckout = true;
            }
          } else {
            if (_isReleaseCall(stmt, docName)) {
              continue;
            }
            targetStatements.add(stmt);
          }
        } else {
          if (_isReleaseCall(stmt, docName)) {
            continue;
          }
          targetStatements.add(stmt);
        }
      }

      reporter
          .createChangeBuilder(
        message: 'Wrap execute body in try-finally',
        priority: 80,
      )
          .addDartFileEdit((final builder) {
        final buffer = StringBuffer();
        buffer.writeln('{');

        // Write statements before/including checkout
        for (final stmt in beforeOrIncludingCheckout) {
          buffer.writeln('  ${stmt.toSource()}');
        }

        // Write try block
        buffer.writeln('  try {');
        for (final stmt in targetStatements) {
          buffer.writeln('    ${stmt.toSource()}');
        }
        buffer.writeln('  } finally {');
        buffer.writeln('    $docName.releaseRecursive(factory);');
        buffer.writeln('  }');
        buffer.write('}');

        builder.addSimpleReplacement(body.sourceRange, buffer.toString());
      });
    });
  }

  bool _isReleaseCall(final Statement stmt, final String docName) {
    if (stmt is ExpressionStatement) {
      var expr = stmt.expression;
      if (expr is AwaitExpression) {
        expr = expr.expression;
      }
      if (expr is MethodInvocation &&
          expr.methodName.name == 'releaseRecursive') {
        final target = expr.target;
        if (target is SimpleIdentifier && target.name == docName) {
          return true;
        }
      }
    }
    return false;
  }
}
