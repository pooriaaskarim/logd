// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule A1 — `logd_document_retained_across_cycles`.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/ast_helpers.dart';
import '../../utils/type_checkers.dart';

/// **A1** — Fires when a [LogDocument] or [LogNode] value is assigned to an
/// instance field or captured in a closure, which would retain the
/// arena-owned object beyond its log cycle.
///
/// Arena-pooled objects are reset after `releaseRecursive` is called.
/// Retaining a reference causes reading stale / zeroed data.
///
/// ### Bad
/// ```dart
/// class BadFormatter implements LogFormatter {
///   LogDocument? _lastDoc;
///
///   @override
///   void format(LogEntry entry, LogDocument document, LogPipelineFactory f) {
///     _lastDoc = document; // ← A1
///     document.text(entry.message);
///   }
/// }
/// ```
///
/// ### Good
/// ```dart
/// void format(LogEntry entry, LogDocument document, LogPipelineFactory f) {
///   document.text(entry.message); // use only within the call frame
/// }
/// ```
class DocumentRetainedAcrossCycles extends DartLintRule {
  const DocumentRetainedAcrossCycles() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_document_retained_across_cycles',
    problemMessage:
        'A LogDocument or LogNode must not be stored in a field or closure — '
        'arena-owned objects are reset after the log cycle completes.',
    correctionMessage:
        'Use the document only within the format() / decorate() call frame.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final ErrorReporter reporter,
    final CustomLintContext context,
  ) {
    context.registry.addAssignmentExpression((final node) {
      final rightType = node.rightHandSide.staticType;
      if (rightType == null) {
        return;
      }

      final isPooledType = logDocumentChecker.isAssignableFromType(rightType) ||
          logNodeChecker.isAssignableFromType(rightType);
      if (!isPooledType) {
        return;
      }

      // Check if assigned to a field (instance or static — both retain
      // the arena-owned object beyond its log cycle).
      final left = node.leftHandSide;
      if (left is SimpleIdentifier) {
        var element = node.writeElement ?? left.element;
        if (element is PropertyAccessorElement) {
          element = element.variable;
        }
        if (element is FieldElement || element is TopLevelVariableElement) {
          reporter.atNode(node, _code);
          return;
        }
      }

      // Check if captured in a closure.
      final enclosingBody = enclosingFunctionBody(node);
      if (enclosingBody != null) {
        final method = enclosingMethod(node);
        if (method != null) {
          final isInsideClosure = enclosingBody != method.body;
          if (isInsideClosure) {
            reporter.atNode(node, _code);
          }
        }
      }
    });
  }
}
