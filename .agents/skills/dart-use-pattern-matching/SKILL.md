---
name: dart-use-pattern-matching
description: Optimize token resolvers, timezone parsers, and formatter conditions in logd using switch expressions and Dart pattern matching.
---
# Utilizing Pattern Matching in logd

## Principles
1. **Optimize Hot Paths**: Avoid heavy conditional strings or deep nested if-else ladders inside timestamp parser segments, timezone maps, and log formatters.
2. **JIT Efficiency**: Sort match branches by expected frequency to help VM branch prediction.
3. **Immutability Protection**: Ensure matched variables are extracted as immutable (`final`) values.

## Pattern Match Example (Token Parsing)
```dart
String resolveToken(String token, DateTime time) => switch (token) {
      'yyyy' => time.year.toString(),
      'MM' => time.month.toString().padLeft(2, '0'),
      'dd' => time.day.toString().padLeft(2, '0'),
      'HH' => time.hour.toString().padLeft(2, '0'),
      'mm' => time.minute.toString().padLeft(2, '0'),
      'ss' => time.second.toString().padLeft(2, '0'),
      _ => throw ArgumentError('Unknown format token: $token'),
    };
```
