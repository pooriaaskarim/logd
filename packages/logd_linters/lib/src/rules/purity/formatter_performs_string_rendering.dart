// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

// ignore_for_file: comment_references, deprecated_member_use

/// Rule B1 — `logd_formatter_performs_string_rendering`.
library;

import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../utils/ast_helpers.dart';
import '../../utils/type_checkers.dart';

/// **B1** — Fires when a `dart:io` terminal API (`stdout.terminalColumns`,
/// `stderr`, `stdout.write*`) is accessed inside a [LogFormatter] or
/// [LogDecorator] implementation.
///
/// Formatters and decorators operate on the **Semantic IR** ([LogDocument]).
/// Terminal width calculations and direct I/O are the exclusive domain of
/// [TerminalLayout] (Physical Layer). Mixing them breaks the architectural
/// boundary defined in `architectural-integrity.md` §1.
///
/// ### Bad
/// ```dart
/// class BadFormatter implements LogFormatter {
///   @override
///   void format(LogEntry e, LogDocument doc, LogPipelineFactory f) {
///     final width = io.stdout.terminalColumns; // ← B1
///     doc.text(e.message.substring(0, width));
///   }
/// }
/// ```
///
/// ### Good
/// ```dart
/// void format(LogEntry e, LogDocument doc, LogPipelineFactory f) {
///   doc.text(e.message); // TerminalLayout handles wrapping
/// }
/// ```
class FormatterPerformsStringRendering extends DartLintRule {
  const FormatterPerformsStringRendering() : super(code: _code);

  static const LintCode _code = LintCode(
    name: 'logd_formatter_performs_string_rendering',
    problemMessage:
        'LogFormatter and LogDecorator must not access terminal I/O or '
        'perform physical layout (e.g. terminalColumns). '
        'Delegate wrapping to TerminalLayout.',
    correctionMessage:
        'Remove the terminal API access. Write semantic content to the '
        'LogDocument; TerminalLayout will handle physical rendering.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  /// Property / method names that represent physical rendering concerns.
  static const _terminalApis = {
    'terminalColumns',
    'terminalLines',
    'hasTerminal',
    'supportsAnsiEscapes',
  };

  /// dart:io member names that indicate direct console output.
  static const _ioOutputMethods = {'write', 'writeln', 'writeAll', 'add'};

  @override
  void run(
    final CustomLintResolver resolver,
    final ErrorReporter reporter,
    final CustomLintContext context,
  ) {
    context.registry.addPropertyAccess((final node) {
      if (!_terminalApis.contains(node.propertyName.name)) {
        return;
      }
      final enclosing = enclosingClass(node);
      if (enclosing == null) {
        return;
      }
      final element = enclosing.declaredFragment?.element;
      if (element == null) {
        return;
      }
      if (_isFormatterOrDecorator(element)) {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addMethodInvocation((final node) {
      if (!_ioOutputMethods.contains(node.methodName.name)) {
        return;
      }
      final targetType = node.target?.staticType;
      if (targetType == null) {
        return;
      }

      // Check if target is stdout/stderr (dart:io IOSink).
      final targetName = targetType.getDisplayString();
      if (!targetName.contains('IOSink') && !targetName.contains('Stdout')) {
        return;
      }

      final enclosing = enclosingClass(node);
      if (enclosing == null) {
        return;
      }
      final element = enclosing.declaredFragment?.element;
      if (element == null) {
        return;
      }
      if (_isFormatterOrDecorator(element)) {
        reporter.atNode(node, _code);
      }
    });
  }

  bool _isFormatterOrDecorator(final classElement) =>
      logFormatterChecker.isSuperOf(classElement) ||
      logDecoratorChecker.isSuperOf(classElement);
}
