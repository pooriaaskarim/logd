# Migration Guide: `logd` v0.9.x to `logd_toon`

Starting with `logd` v0.9.7, the built-in TOON handlers, formatters, and encoders are deprecated. They have been extracted into the standalone `logd_toon` package to reduce the core package size and allow independent versioning of the TOON specification.

This guide explains how to migrate your existing codebase.

## 1. Add the Dependency

Add `logd_toon` to your `pubspec.yaml`:

```yaml
dependencies:
  logd: ^0.9.7
  logd_toon: ^0.1.0
```

Run `dart pub get` or `flutter pub get`.

## 2. Update Imports

Since `logd` v0.9.7 still contains deprecated shims for the TOON classes, importing both `package:logd/logd.dart` and `package:logd_toon/logd_toon.dart` will cause `Ambiguous import` errors.

You must `hide` the deprecated classes from the `logd` import:

```dart
// Before
import 'package:logd/logd.dart';

// After
import 'package:logd/logd.dart' hide ToonEncoder, ToonDialect, ToonHandler;
import 'package:logd_toon/logd_toon.dart';
```

## 3. Update Handler Usage

If you were using `ToonHandler` directly, the API remains the same. Just ensure you are using the one from `logd_toon`.

```dart
// The syntax remains identical
final handler = ToonHandler(
  dialect: ToonDialect.strict,
);

Logger.configure(
  handlers: [handler],
);
```

## 4. Removal in v0.10.0

The deprecated shims in `package:logd` will be completely removed in `v0.10.0`. Once you upgrade to v0.10.0, you can remove the `hide` clauses from your imports.
