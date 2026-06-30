// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule C6 — `logd_metadata_set_duplicate`.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/type_checkers.dart';

/// **C6** — Fires when a `Set` literal passed as the `metadata:` argument to
/// a formatter constructor contains duplicate [LogMetadata] values.
///
/// `LogMetadata` is an enum used as a `Set<LogMetadata>`. Duplicate values in
/// a set literal are silently deduplicated by Dart, which may mislead the
/// developer into thinking a field is included twice with different effects.
///
/// ### Bad
/// ```dart
/// StructuredFormatter(
///   metadata: {
///     LogMetadata.timestamp,
///     LogMetadata.timestamp, // ← C6: duplicate
///   },
/// )
/// ```
///
/// ### Good
/// ```dart
/// StructuredFormatter(
///   metadata: {
///     LogMetadata.timestamp,
///     LogMetadata.logger,
///   },
/// )
/// ```
class MetadataSetDuplicate extends DartLintRule {
  const MetadataSetDuplicate() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_metadata_set_duplicate',
    problemMessage: "Duplicate LogMetadata value in the 'metadata' set. "
        'Duplicates are silently ignored at runtime.',
    correctionMessage: 'Remove the duplicate LogMetadata entry.',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final ErrorReporter reporter,
    final CustomLintContext context,
  ) {
    context.registry.addNamedExpression((final node) {
      if (node.name.label.name != 'metadata') {
        return;
      }

      final value = node.expression;
      if (value is! SetOrMapLiteral) {
        return;
      }

      // Collect LogMetadata enum value names, report the second occurrence.
      final seen = <String>{};
      for (final element in value.elements) {
        if (element is! Expression) {
          continue;
        }
        final name = _logMetadataName(element);
        if (name == null) {
          continue;
        }
        if (!seen.add(name)) {
          reporter.atNode(element, _code);
        }
      }
    });
  }

  /// Returns the LogMetadata enum constant name for [expr], or null if [expr]
  /// is not a LogMetadata reference.
  String? _logMetadataName(final Expression expr) {
    if (expr is PrefixedIdentifier) {
      if (expr.prefix.name == 'LogMetadata') {
        return expr.identifier.name;
      }
    }
    if (expr is PropertyAccess) {
      final target = expr.target;
      if (target is SimpleIdentifier && target.name == 'LogMetadata') {
        return expr.propertyName.name;
      }
    }
    // Simple identifier — verify its type is LogMetadata.
    if (expr is SimpleIdentifier) {
      final type = expr.staticType;
      if (type != null && logMetadataChecker.isExactlyType(type)) {
        return expr.name;
      }
    }
    return null;
  }
}
