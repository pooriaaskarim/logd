import 'package:meta/meta.dart';

/// Internal utility for list equality.
@internal
bool listEquals<T>(final List<T>? a, final List<T>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

/// Internal utility for map equality.
@internal
bool mapEquals<K, V>(final Map<K, V>? a, final Map<K, V>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null || a.length != b.length) {
    return false;
  }
  if (identical(a, b)) {
    return true;
  }
  for (final K key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) {
      return false;
    }
  }
  return true;
}
