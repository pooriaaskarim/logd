---
name: dart-setup-ffi-assets
description: Guides agents in compiling and packaging C/C++ source code into dynamic or static libraries (Code Assets) using Dart's Native Assets hook system (via hook/build.dart and hook/link.dart utilizing package:native_toolchain_c) for logd VM/native modules.
---
# Compiling and Setup Native Assets for logd

## Principles
1. **Use native_toolchain_c**: Always compile C/C++ source code via `package:native_toolchain_c` inside standard hooks.
2. **Hook Location**: Put build hooks under `hook/build.dart` and linker hooks under `hook/link.dart` inside the package root.
3. **Decouple VM/Web**: Ensure that native assets are conditionally linked or registered so they do not pollute browser or web compilation paths.

## Example Hook (`hook/build.dart`)
```dart
import 'package:logging/logging.dart';
import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (config, output) async {
    final builder = CBuilder.library(
      name: 'logd_native',
      assetId: 'package:logd/src/native/logd_native.dart',
      sources: [
        'src/logd_native.c',
      ],
    );
    await builder.run(
      config: config,
      output: output,
      logger: Logger('logd_native_builder'),
    );
  });
}
```
