// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule B3 — `logd_formatter_not_immutable`.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
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

      if (!logFormatterChecker.isAssignableFrom(element)) {
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

  @override
  List<Fix> getFixes() => [_MakeFormatterImmutableFix()];
}

class _MakeFormatterImmutableFix extends DartFix {
  _MakeFormatterImmutableFix();

  @override
  void run(
    final CustomLintResolver resolver,
    final ChangeReporter reporter,
    final CustomLintContext context,
    final AnalysisError analysisError,
    final List<AnalysisError> others,
  ) {
    context.registry.addClassDeclaration((final classDecl) {
      if (analysisError.sourceRange.offset < classDecl.offset ||
          analysisError.sourceRange.offset > classDecl.end) {
        return;
      }

      reporter
          .createChangeBuilder(
        message: 'Make formatter class immutable',
        priority: 80,
      )
          .addDartFileEdit((final builder) {
        // 1. Add @immutable annotation
        if (!hasImmutableAnnotation(classDecl)) {
          final unit = classDecl.parent as CompilationUnit;
          final hasMeta = unit.directives.whereType<ImportDirective>().any(
              (final dir) => dir.uri.stringValue == 'package:meta/meta.dart');

          if (!hasMeta) {
            final firstDirective =
                unit.directives.isEmpty ? null : unit.directives.first;
            final insertOffset = firstDirective?.offset ?? 0;
            builder.addSimpleInsertion(
                insertOffset, "import 'package:meta/meta.dart';\n");
          }

          final insertOffset = classDecl.metadata.isNotEmpty
              ? classDecl.metadata.first.offset
              : classDecl.classKeyword.offset;
          builder.addSimpleInsertion(insertOffset, '@immutable\n');
        }

        // 2. Make non-static mutable fields final
        for (final member in classDecl.members) {
          if (member is FieldDeclaration && !member.isStatic) {
            final fields = member.fields;
            if (!fields.isFinal && !fields.isConst) {
              final keyword = fields.keyword;
              if (keyword != null && keyword.lexeme == 'var') {
                builder.addSimpleReplacement(
                  SourceRange(keyword.offset, keyword.length),
                  'final',
                );
              } else if (keyword == null) {
                final insertOffset =
                    fields.type?.offset ?? fields.variables.first.offset;
                builder.addSimpleInsertion(insertOffset, 'final ');
              }
            }
          }
        }
      });
    });
  }
}
