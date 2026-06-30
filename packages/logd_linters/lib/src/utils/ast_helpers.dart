// Copyright (c) 2026, Pooria Askari Moqaddam. All rights reserved.
// Use of this source code is governed by a BSD-3-Clause license that can be
// found in the LICENSE file.

/// AST traversal helpers shared across logd lint rules.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

// ---------------------------------------------------------------------------
// Class / method context helpers
// ---------------------------------------------------------------------------

/// Returns the nearest enclosing [ClassDeclaration] for [node], or `null`.
ClassDeclaration? enclosingClass(final AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is ClassDeclaration) {
      return current;
    }
    current = current.parent;
  }
  return null;
}

/// Returns the nearest enclosing [MethodDeclaration] for [node], or `null`.
MethodDeclaration? enclosingMethod(final AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is MethodDeclaration) {
      return current;
    }
    current = current.parent;
  }
  return null;
}

/// Returns the nearest enclosing [FunctionBody] for [node], or `null`.
FunctionBody? enclosingFunctionBody(final AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is FunctionBody) {
      return current;
    }
    current = current.parent;
  }
  return null;
}

// ---------------------------------------------------------------------------
// try-finally helpers
// ---------------------------------------------------------------------------

/// Returns `true` if [block] contains a [TryStatement] whose `finally` block
/// has at least one [MethodInvocation] named [methodName].
bool hasTryFinallyWithCall(final Block block, final String methodName) {
  for (final stmt in block.statements) {
    if (stmt is! TryStatement) {
      continue;
    }
    final fin = stmt.finallyBlock;
    if (fin == null) {
      continue;
    }
    for (final fStmt in fin.statements) {
      if (_blockContainsCall(fStmt, methodName)) {
        return true;
      }
    }
  }
  return false;
}

bool _blockContainsCall(final AstNode node, final String name) {
  if (node is ExpressionStatement) {
    final expr = node.expression;
    if (expr is MethodInvocation && expr.methodName.name == name) {
      return true;
    }
    if (expr is AwaitExpression) {
      final inner = expr.expression;
      if (inner is MethodInvocation && inner.methodName.name == name) {
        return true;
      }
    }
  }
  // Recurse one level (handles if/else, nested blocks)
  for (final child in node.childEntities) {
    if (child is AstNode && _blockContainsCall(child, name)) {
      return true;
    }
  }
  return false;
}

// ---------------------------------------------------------------------------
// File path heuristics
// ---------------------------------------------------------------------------

/// Returns `true` when [path] belongs to a test file (`_test.dart` suffix
/// or lives inside a `test/` directory segment).
bool isTestFile(final String path) =>
    path.endsWith('_test.dart') ||
    path.contains('/test/') ||
    path.contains(r'\test\');

/// Returns `true` when [path] is inside a `lib/src/` directory of a package,
/// indicating it is internal library code rather than an app entry point.
bool isLibrarySrcFile(final String path) =>
    path.contains('/lib/src/') || path.contains(r'\lib\src\');

// ---------------------------------------------------------------------------
// Interface / supertype helpers
// ---------------------------------------------------------------------------

/// Returns `true` if [element] implements or extends an interface whose name
/// equals [interfaceName].
bool implementsInterface(
  final ClassElement element,
  final String interfaceName,
) {
  for (final interface in element.allSupertypes) {
    if (interface.element.name == interfaceName) {
      return true;
    }
  }
  return false;
}

/// Returns `true` if [classDecl] has a non-`final` instance field (i.e. it
/// contains mutable state and therefore cannot be `@immutable`).
bool hasMutableFields(final ClassDeclaration classDecl) {
  for (final member in classDecl.members) {
    if (member is FieldDeclaration && !member.isStatic) {
      if (!member.fields.isFinal && !member.fields.isConst) {
        return true;
      }
    }
  }
  return false;
}

/// Returns `true` if [classDecl] carries the `@immutable` annotation from
/// `package:meta`.
bool hasImmutableAnnotation(final ClassDeclaration classDecl) {
  for (final annotation in classDecl.metadata) {
    if (annotation.name.name == 'immutable') {
      return true;
    }
  }
  return false;
}

// ---------------------------------------------------------------------------
// Argument / expression helpers
// ---------------------------------------------------------------------------

/// Returns the [NamedExpression] with [name] from [argumentList], or `null`.
NamedExpression? namedArg(
  final ArgumentList argumentList,
  final String name,
) {
  for (final arg in argumentList.arguments) {
    if (arg is NamedExpression && arg.name.label.name == name) {
      return arg;
    }
  }
  return null;
}

/// Returns `true` if [invocation] is a call to a static method named
/// [methodName] on a class named [className].
bool isStaticCall(
  final MethodInvocation invocation,
  final String className,
  final String methodName,
) {
  if (invocation.methodName.name != methodName) {
    return false;
  }
  final target = invocation.target;
  if (target is SimpleIdentifier && target.name == className) {
    return true;
  }
  return false;
}
