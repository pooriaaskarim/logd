---
name: dart-use-ffigen
description: Guide agents to use `package:ffigen` to automatically generate FFI bindings instead of writing them manually. Use this skill when a task involves writing new FFI bindings, extending C/Objective-C/Swift integrations, or replacing hand-crafted `dart:ffi` setups in logd.
---
# Generating FFI Bindings for logd

## Principles
1. **No Hand-Written FFI Bindings**: Never write manual `DynamicLibrary.lookup`, `@Native` functions, or raw struct classes if headers exist.
2. **Path Resolution**: Resolve all paths relative to `Platform.script` in the generator script to ensure it is runnable from any package directory.
3. **Location**: Place the generator script at `tool/ffigen.dart` and output generated bindings to `lib/src/third_party/` with a `.g.dart` extension.
4. **Tree Shaking**: Enable recorded usage on all functions by setting `recordUse: (_) => true` and configure `recordUseMapping` target in `Output` to support tree shaking.

## Example Config
```dart
import 'dart:io';
import 'package:ffigen/ffigen.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');
  final entryHeader = packageRoot.resolve('third_party/native_lib.h');
  final bindingsOutput = packageRoot.resolve('lib/src/third_party/native_bindings.g.dart');
  final treeShakeMapping = packageRoot.resolve('lib/src/third_party/native_bindings.record_use_mapping.g.dart');

  FfiGenerator(
    headers: Headers(entryPoints: [entryHeader]),
    functions: Functions(
      include: (decl) => {'my_native_function'}.contains(decl.originalName),
      recordUse: (_) => true,
    ),
    output: Output(
      dartFile: bindingsOutput,
      recordUseMapping: treeShakeMapping,
      format: true,
      preamble: '// AUTO-GENERATED FILE. DO NOT EDIT.\n',
    ),
  ).generate();
}
```
