import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Shared type-checking utilities for logd lint rules.
///
/// Uses direct element inspection instead of `source_gen`'s `TypeChecker`
/// for simpler, more reliable type resolution.
class LogdTypeChecker {
  const LogdTypeChecker._();

  /// Returns `true` if [type] is `LogBuffer` from `package:logd`.
  ///
  /// Also returns `true` for nullable `LogBuffer?` types by unwrapping
  /// the nullability before checking.
  static bool isLogBufferType(final DartType type) {
    final unwrapped = type is InterfaceType ? type : null;
    if (unwrapped == null) {
      return false;
    }
    return _isLogBuffer(unwrapped.element);
  }

  /// Recursively checks whether [element] is `LogBuffer` from `package:logd`,
  /// or a subtype thereof.
  static bool _isLogBuffer(final InterfaceElement element) {
    final uri = element.library.identifier;
    if (element.name == 'LogBuffer' && uri.startsWith('package:logd/')) {
      return true;
    }
    for (final supertype in element.allSupertypes) {
      if (_isLogBuffer(supertype.element)) {
        return true;
      }
    }
    return false;
  }
}
