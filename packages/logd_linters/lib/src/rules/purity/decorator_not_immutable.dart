// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule B2 — `logd_decorator_not_immutable`.
library;

import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/ast_helpers.dart';
import '../../utils/type_checkers.dart';

/// **B2** — Fires when a class extending a [LogDecorator] subtype
/// ([ContentDecorator], [StructuralDecorator], or [VisualDecorator]) is not
/// annotated with `@immutable` or contains non-`final` instance fields.
///
/// Decorators must be `@immutable` per the logd code-style contract. Mutable
/// state in a decorator creates hidden coupling between log cycles and makes
/// concurrent logging unsafe.
///
/// ### Bad
/// ```dart
/// class CountingDecorator extends ContentDecorator {
///   int _count = 0; // ← B2: mutable field
///   // ...
/// }
/// ```
///
/// ### Good
/// ```dart
/// @immutable
/// class PrefixDecorator extends ContentDecorator {
///   const PrefixDecorator({required this.prefix});
///   final String prefix; // ✓ final
/// }
/// ```
class DecoratorNotImmutable extends DartLintRule {
  const DecoratorNotImmutable() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_decorator_not_immutable',
    problemMessage:
        'LogDecorator subclasses must be @immutable with only final fields.',
    correctionMessage: 'Add @immutable and make all instance fields final. '
        'Extract mutable state into constructor parameters.',
    errorSeverity: ErrorSeverity.WARNING,
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

      final isDecorator = contentDecoratorChecker.isSuperOf(element) ||
          structuralDecoratorChecker.isSuperOf(element) ||
          visualDecoratorChecker.isSuperOf(element);
      if (!isDecorator) {
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
