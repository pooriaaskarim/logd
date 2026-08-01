# Stack Trace Symbol Deobfuscation Guide

When building Flutter or Dart applications for production release using `--obfuscate`, class and method names in stack traces are mangled to reduce binary size and hinder reverse engineering (e.g. `#0 _k3$2 (package:myapp/main.dart:42:10)`).

`logd` provides built-in support for deobfuscating production stack traces via the `SymbolResolver` hook on `StackTraceParser`.

---

## 1. Defining a `SymbolResolver`

`SymbolResolver` is a lightweight callback function that translates an obfuscated symbol or method string into its human-readable original form:

```dart
typedef SymbolResolver = String? Function(String symbol);
```

If the resolver returns `null`, `StackTraceParser` keeps the raw frame information.

---

## 2. Using `SymbolResolver` with `Logger`

To use custom deobfuscation in your application, supply a `StackTraceParser` configured with your `SymbolResolver` when configuring `Logger`:

```dart
final Map<String, String> appSymbolMap = {
  '_k3$2': 'UserService.fetchProfile',
  '_a9$1': 'AuthManager.login',
};

final parser = StackTraceParser(
  symbolResolver: (symbol) => appSymbolMap[symbol],
);

Logger.configure(
  'global',
  stackTraceParser: parser,
);
```

---

## 3. Deobfuscating Release Stack Traces via `flutter symbolize`

For native Flutter AOT release builds:

1. **Save your app's symbol map** during compilation:
   ```bash
   flutter build apk --obfuscate --split-debug-info=build/symbols
   ```

2. **Deobfuscate crash reports** using the official `flutter symbolize` CLI:
   ```bash
   flutter symbolize -i obfuscated_trace.txt -d build/symbols/app.android-arm64.symbols
   ```

---

## 4. Integration with External Error Tracking Services

If you integrate `logd` with remote crash reporting endpoints (e.g., Sentry, Bugsnag), you can provide a custom `SymbolResolver` that queries local cache or in-memory symbol dictionaries prior to formatting:

```dart
final remoteResolver = StackTraceParser(
  symbolResolver: (symbol) {
    return SymbolRegistry.lookup(symbol);
  },
);
```
