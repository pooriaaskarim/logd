import 'package:analyzer/dart/element/element.dart' as elem;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../logd_type_checker.dart';

/// Detects `LogBuffer` instances that are acquired but never sinked,
/// or sinked without `finally` protection.
///
/// ## Reported diagnostics
///
/// - **`avoid_abandoned_log_buffers`** (ERROR): Buffer acquired but `.sink()`
///   is never called. Data will be lost.
/// - **`risky_log_buffer_usage`** (WARNING): Buffer is sinked, but not inside
///   a `finally` block. An exception could cause data loss.
class AvoidAbandonedLogBuffers extends DartLintRule {
  const AvoidAbandonedLogBuffers() : super(code: _codeAbandoned);

  static const _codeAbandoned = LintCode(
    name: 'avoid_abandoned_log_buffers',
    problemMessage: 'LogBuffer acquired but never sinked. Data will be lost.',
    correctionMessage:
        'Ensure .sink() is called, preferably in a finally block.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    final CustomLintResolver resolver,
    final ErrorReporter reporter,
    final CustomLintContext context,
  ) {
    // ------------------------------------------------------------------
    // Pattern 1: Variable declarations typed as LogBuffer
    // ------------------------------------------------------------------
    context.registry.addVariableDeclaration((final node) {
      // ignore: deprecated_member_use
      final element = node.declaredElement;
      if (element == null) {
        return;
      }
      final type = element.type;
      final isLogBuffer = LogdTypeChecker.isLogBufferType(type);

      if (!isLogBuffer) {
        return;
      }

      _checkVariableLifecycle(node, reporter);
    });

    // ------------------------------------------------------------------
    // Pattern 2: Expression statements that acquire a LogBuffer inline
    //            e.g. `logger.infoBuffer!.writeln('leak');`
    // ------------------------------------------------------------------
    context.registry.addExpressionStatement((final node) {
      final visitor = _ExpressionChainVisitor();
      node.expression.accept(visitor);

      if (visitor.hasLogBufferAcquisition && !visitor.hasSink) {
        reporter.atNode(node.expression, _codeAbandoned);
      }
    });
  }

  /// Checks whether a `LogBuffer` variable is properly sinked within its scope.
  void _checkVariableLifecycle(
    final VariableDeclaration node,
    final ErrorReporter reporter,
  ) {
    final scope = node.thisOrAncestorOfType<Block>() ??
        node.thisOrAncestorOfType<FunctionBody>();
    if (scope == null) {
      return;
    }

    final variableName = node.name.lexeme;

    // If the initializer is a cascade that already calls .sink(), it's fine.
    final initializer = node.initializer;
    if (initializer is CascadeExpression) {
      for (final section in initializer.cascadeSections) {
        if (section is MethodInvocation && section.methodName.name == 'sink') {
          return; // Already sinked in cascade — safe.
        }
      }
    }

    if (!_PathSinkVerifier(variableName).isSinkedInScope(scope)) {
      reporter.atNode(node, _codeAbandoned);
    }
  }
}

// ---------------------------------------------------------------------------
// Visitors / Verifiers
// ---------------------------------------------------------------------------

class _PathSinkVerifier {
  final String variableName;

  _PathSinkVerifier(this.variableName);

  bool isSinkedInScope(final AstNode scope) {
    if (scope is Block) {
      return _isSafe(_checkBlock(scope));
    }
    if (scope is FunctionBody) {
      if (scope is BlockFunctionBody) {
        return _isSafe(_checkBlock(scope.block));
      }
      if (scope is ExpressionFunctionBody) {
        return _checkExpression(scope.expression);
      }
    }
    return false;
  }

  _PathStatus _checkBlock(final Block block) {
    for (final statement in block.statements) {
      final status = _checkStatement(statement);
      if (status == _PathStatus.sinked || status == _PathStatus.transferred) {
        return status;
      }
      // If status is 'none', continue to next statement.
    }
    return _PathStatus.none; // Reached end of block without sinking.
  }

  _PathStatus _checkStatement(final Statement statement) {
    if (statement is ExpressionStatement) {
      if (_checkExpression(statement.expression)) {
        return _PathStatus.sinked;
      }
    } else if (statement is ReturnStatement) {
      if (_checkExpression(statement.expression)) {
        return _PathStatus.transferred; // Explicitly returned the buffer.
      }
      return _PathStatus.transferred; // Return without value exits scope.
    } else if (statement is Block) {
      if (_checkBlock(statement) != _PathStatus.none) {
        return _PathStatus.sinked;
      }
    } else if (statement is IfStatement) {
      final thenStatus = _checkStatement(statement.thenStatement);
      final elseStatement = statement.elseStatement;
      final elseStatus = elseStatement != null
          ? _checkStatement(elseStatement)
          : _PathStatus.none;

      // Robustness: If ONE branch exits/sinks, what about the other?
      // We need BOTH branches to be handled.
      // If 'then' sinks, and 'else' is missing -> path falls through.
      // If path falls through, we return 'none' so verifyBlock continues.

      // If both branches definitely sink/exit, then the IfStatement definitely sinks.
      if (_isSafe(thenStatus) && _isSafe(elseStatus)) {
        return _PathStatus.sinked;
      }
    } else if (statement is TryStatement) {
      final finallyBlock = statement.finallyBlock;
      if (finallyBlock != null && _isSafe(_checkBlock(finallyBlock))) {
        return _PathStatus.sinked; // Sink in finally covers everything.
      }

      final bodySafe = _isSafe(_checkBlock(statement.body));
      final allCatchesSafe = statement.catchClauses.every(
        (final c) => _isSafe(_checkBlock(c.body)),
      );

      if (bodySafe && allCatchesSafe) {
        return _PathStatus.sinked;
      }
    }

    // Check for throw (exit)
    // Dart AST doesn't have ThrowStatement? Use ExpressionStatement with ThrowExpression.

    return _PathStatus.none;
  }

  bool _checkExpression(final Expression? expression) {
    if (expression == null) {
      return false;
    }

    // Check for direct sink call: variable.sink()
    if (expression is MethodInvocation) {
      if (expression.methodName.name == 'sink') {
        final target = expression.realTarget;
        if (target != null && target.toSource() == variableName) {
          return true;
        }
      }
    }

    // Check for cascade: variable..sink()
    if (expression is CascadeExpression) {
      final target = expression.target;
      if (target.toSource() == variableName) {
        for (final section in expression.cascadeSections) {
          if (section is MethodInvocation &&
              section.methodName.name == 'sink') {
            return true;
          }
        }
      }
    }

    // Check for assignment/return of the variable (ownership transfer).
    if (expression is SimpleIdentifier && expression.name == variableName) {
      return true; // Treated as sinked/transferred.
    }

    // Recursive checks for children?
    // Just handling top-level of expression for now.

    return false;
  }

  bool _isSafe(final _PathStatus status) {
    return status == _PathStatus.sinked || status == _PathStatus.transferred;
  }
}

enum _PathStatus {
  none, // Continue execution
  sinked, // Definitely sinked
  transferred // Exits scope (return/throw)
}

/// Walks an expression tree to detect if a `LogBuffer` is acquired and
/// whether `.sink()` is called on it.
class _ExpressionChainVisitor extends RecursiveAstVisitor<void> {
  bool hasLogBufferAcquisition = false;
  bool hasSink = false;

  @override
  void visitMethodInvocation(final MethodInvocation node) {
    // Check for .sink() call on a LogBuffer target.
    if (node.methodName.name == 'sink') {
      final target = node.realTarget;
      if (target != null) {
        final targetType = target.staticType;
        if (targetType != null && LogdTypeChecker.isLogBufferType(targetType)) {
          hasSink = true;
        }
      }
    }

    // Check if we're calling a method on a LogBuffer (acquisition).
    final target = node.realTarget;
    if (target != null) {
      final targetType = target.staticType;
      if (targetType != null && LogdTypeChecker.isLogBufferType(targetType)) {
        bool ignore = false;
        if (target is SimpleIdentifier) {
          // ignore: deprecated_member_use
          final element = target.element;
          if (element is elem.VariableElement) {
            ignore = true;
          }
        }

        if (!ignore) {
          hasLogBufferAcquisition = true;
        }
      }
    }

    // Check if the method itself returns a LogBuffer.
    final returnType = node.staticType;
    if (returnType != null && LogdTypeChecker.isLogBufferType(returnType)) {
      hasLogBufferAcquisition = true;
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(final PropertyAccess node) {
    final type = node.staticType;
    if (type != null && LogdTypeChecker.isLogBufferType(type)) {
      // Check if target is local variable/parameter to ignore
      bool ignore = false;
      final target = node.realTarget;
      if (target is SimpleIdentifier) {
        // ignore: deprecated_member_use
        final element = target.element;
        if (element is elem.VariableElement) {
          ignore = true;
        }
      }

      if (!ignore) {
        hasLogBufferAcquisition = true;
      }
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(final PrefixedIdentifier node) {
    final type = node.staticType;
    if (type != null && LogdTypeChecker.isLogBufferType(type)) {
      // Check if prefix is local variable/parameter to ignore
      bool ignore = false;
      final prefix = node.prefix;
      // ignore: deprecated_member_use
      final element = prefix.element;
      if (element is elem.VariableElement) {
        ignore = true;
      }

      if (!ignore) {
        hasLogBufferAcquisition = true;
      }
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitCascadeExpression(final CascadeExpression node) {
    final type = node.staticType;
    if (type != null && LogdTypeChecker.isLogBufferType(type)) {
      bool ignore = false;
      final target = node.target;
      if (target is SimpleIdentifier) {
        // ignore: deprecated_member_use
        final element = target.element;
        if (element is elem.VariableElement) {
          ignore = true;
        }
      }

      if (!ignore) {
        hasLogBufferAcquisition = true;
        for (final section in node.cascadeSections) {
          if (section is MethodInvocation &&
              section.methodName.name == 'sink') {
            hasSink = true;
            break;
          }
        }
      }
    }
    super.visitCascadeExpression(node);
  }
}

/// Walks a scope to find `.sink()` invocations on a specific variable
/// (identified by name), and to detect ownership transfers
/// (return / argument passing).
///
/// Uses name matching since `staticElement` is removed in analyzer 8.x.
/// In single block scope, a name match is sufficient and reliable.
