import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../logd_type_checker.dart';

/// Quick fix for `avoid_abandoned_log_buffers`: appends `.sink()` at the end
/// of the scope.
class AddSinkCallFix extends DartFix {
  @override
  void run(
    final CustomLintResolver resolver,
    final ChangeReporter reporter,
    final CustomLintContext context,
    final AnalysisError error,
    final List<AnalysisError> others,
  ) {
    context.registry.addVariableDeclaration((final node) {
      if (!error.sourceRange.intersects(node.sourceRange)) {
        return;
      }

      // ignore: deprecated_member_use
      final element = node.declaredElement;
      if (element == null) {
        return;
      }

      final type = element.type;
      if (!LogdTypeChecker.isLogBufferType(type)) {
        return;
      }

      final block = node.thisOrAncestorOfType<Block>();
      if (block == null) {
        return;
      }

      final variableName = node.name.lexeme;

      reporter
          .createChangeBuilder(
        message: 'Add .sink() call',
        priority: 80,
      )
          .addDartFileEdit((final builder) {
        // Insert at the end of the block, before the closing brace.
        final closingBrace = block.rightBracket;
        builder.addSimpleInsertion(
          closingBrace.offset,
          '  $variableName.sink();\n',
        );
      });
    });
  }
}
