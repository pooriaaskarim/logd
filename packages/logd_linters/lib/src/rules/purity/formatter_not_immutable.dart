// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule B3 — `logd_formatter_not_immutable`.
library;

import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/ast_helpers.dart';
import '../../utils/type_checkers.dart';

/// **B3** — Fires when a class implementing [LogFormatter] is not annotated
/// with `@immutable` or contains non-`final` instance fields.
///
/// Formatters must be stateless and `@immutable`. A formatter instance is
/// shared across all log cycles for the same [Handler]; mutable state would
/// create data races in concurrent or isolate-based logging.
///
/// > **Arena Exception**: [ArenaDocument] and other pool-managed classes on
/// > the `arena_refinement` branch deliberately drop `@immutable`. This rule
/// > excludes classes whose name contains `ArenaDocument` or `ArenaNode` to
/// > avoid false positives on internal logd code.
///
/// ### Bad
/// ```dart
/// class StatefulFormatter implements LogFormatter {
///   int _callCount = 0; // ← B3: mutable state
///   // ...
/// }
/// ```
///
/// ### Good
/// ```dart
/// @immutable
/// class StructuredFormatter implements LogFormatter {
///   const StructuredFormatter({required this.metadata});
///   @override
///   final Set<LogMetadata> metadata; // ✓ final
/// }
/// ```
class FormatterNotImmutable extends DartLintRule {
  const FormatterNotImmutable() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_formatter_not_immutable',
    problemMessage:
        'LogFormatter implementations must be @immutable with only final '
        'fields. Mutable state creates data races in shared formatter '
        'instances.',
    correctionMessage: 'Add @immutable and make all instance fields final. '
        'Pass configuration through constructor parameters.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  /// Internal logd class names that are exempt from this rule
  /// (arena branch poolable objects).
  static const _arenaExemptions = {
    'StandardDocument',
    'ArenaDocument',
  };

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

      if (!logFormatterChecker.isSuperOf(element)) {
        return;
      }
      if (_arenaExemptions.contains(element.name)) {
        return;
      }

      final missingAnnotation = !hasImmutableAnnotation(classDecl);
      final hasMutable = hasMutableFields(classDecl);

      if (missingAnnotation || hasMutable) {
        reporter.atToken(classDecl.name, _code);
      }
    });
  }
}
