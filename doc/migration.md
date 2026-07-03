# Migration Guide

## v0.8.5 to v0.8.6 (Sub-Library Restructure & Web Logging Fix)

### 1. Web Compilation Restored (Bug Fix)
**Change**: Fixes compilation failures under Web/JS/WASM platforms caused by transitive imports of `dart:ffi` and `dart:io`.
* **Impact**: You can now safely run and compile projects using `logd` under Web environments. 
* **Migration**: 
  - No code changes are required for standard cross-platform usage.
  - Sinks and engines that rely on native FFI (like `ArenaEngine`, `NativeEngine`, `FileSink`, and `IsolateSink`) will throw descriptive, enabling `UnsupportedError` exceptions if executed in a Web browser, guiding you to use cross-platform alternatives (e.g., `StandardEngine`, `ConsoleSink`, or `HttpSink`).

### 2. Dissolution of `native_handler.dart` and `native_handler_stub.dart`
**Change**: Decoupled the monolithic platform stub files. Stub classes (such as `ArenaDocument` or `FileRotation` stubs) are now co-located with their actual native implementations under the leaf directories.
* **Impact**:
  - Direct internal imports of `package:logd/src/handler/native_handler.dart` or `package:logd/src/handler/native_handler_stub.dart` will fail because these files have been deleted.
* **Migration**:
  - If your project used direct internal imports (discouraged), update them to reference the specific sub-library selectors:
    * `Arena` -> `import 'package:logd/src/handler/engine/arena.dart';`
    * `FileSink` -> `import 'package:logd/src/handler/sink/file_sink.dart';`
    * `IsolateSink` -> `import 'package:logd/src/handler/sink/isolate_sink.dart';`
    * `NativeEngine` / `ArenaEngine` -> `import 'package:logd/src/handler/engine/native_engine.dart';`
    * `BinaryIR` -> `import 'package:logd/src/handler/document/binary_ir.dart';`
  - VM-only FFI tests and native integrations should import the native implementations directly (e.g. `import 'package:logd/src/handler/engine/arena_native.dart';`).

## v0.8.3 to v0.8.4 (Flutter Decoupling & Pure Dart Transition)

### 1. Flutter SDK Dependency Removed (Breaking Change)
**Change**: To enable logging in pure Dart VM, CLI, server, and background isolates, the `logd` package has completely removed the Flutter SDK runtime dependency. 
*   **Impact**:
    *   Conditional import files (`flutter_stubs.dart`, `flutter_stubs_flutter.dart`) are deleted.
    *   The API `Logger.attachToFlutterErrors` has been removed.
*   **Migration**:
    If your codebase relied on `Logger.attachToFlutterErrors` to capture Flutter framework exceptions, you must now explicitly hook the logger to the Flutter runtime inside your app's entry points (typically `main()`):

    ```dart
    void main() {
      // 1. Capture framework-specific UI errors
      FlutterError.onError = (final details) {
        Logger.get('app.crash').error(
          'Flutter error',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      // 2. Capture asynchronous framework/zone exceptions
      runZonedGuarded(
        () => runApp(const MyApp()),
        (final error, final stack) {
          Logger.get('app.crash').error(
            'Uncaught asynchronous error',
            error: error,
            stackTrace: stack,
          );
        },
      );
    }
    ```

---

## v0.7.1 to v0.8.0 (The High-Performance Engine Milestone)

### 1. `LogDocument` Abstraction (Breaking Change)
**Change**: `LogDocument` has transitioned from a concrete class to an **abstract interface**.
- **Impact**: You can no longer instantiate `LogDocument()` directly.
- **Migration**: 
  - For standard heap-allocated documents, use **`StandardDocument()`**.
  - For pooled documents (recommended), use **`factory.checkoutDocument()`**.
  - **Why?**: This allows the `NativeEngine` and `ArenaEngine` to swap in specialized, high-performance document types (like `ArenaDocument`) without changing your formatting logic.

### 2. StandardEngine remains the Default (Universal Compatibility)
**Decision**: To ensure complete cross-platform safety out-of-the-box (especially for Web compilation via DDC/Dart2js), the `Handler` continues to default to **`StandardEngine`**.
- **Opt-in Performance**: You can explicitly select **`ArenaEngine`** (zero GC overhead) or **`NativeEngine`** (high-speed FFI-ready binary stream serialization) depending on your target platforms.
- **Opt-in Example**:
  ```dart
  final handler = Handler(
    engine: const ArenaEngine(),
  );
  ```

### 3. Custom `LogNode` Implementation
**Change**: All `LogNode` subclasses must now implement a **`reset()`** method.
- **Impact**: If you have implemented custom node types for specialized renderers, you must add a `reset()` method to support `Arena` object pooling.
- **Reference**: See [content_nodes.dart](../packages/logd/lib/src/handler/document/content_nodes.dart) for reference implementations.

---

## v0.6.4 to v0.7.0 (Structural Overhaul & Engine API)

### 1. Engine-Driven Orchestration
**Change**: The `Handler` now delegates all execution and lifecycle management to a matching `LogEngine`.
- **Impact**: Users can now explicitly choose their performance strategy (`StandardEngine` vs `ArenaEngine`) in the `Handler` constructor.

### 2. Unified Resource Management
**Change**: Allocation of [LogDocument]s and [LogNode]s is now managed through the `LogPipelineFactory` interface.
- **Benefit**: Decouples semantic generation (formatting) from physical memory management (heap vs pool).

### 3. File Relocation
**Change**: The internal directory structure of the `handler` module has been reorganized for architectural clarity:
- **`document/`**: Semantic Intermediate Representation (IR).
- **`layout/`**: Physical representation and rendering logic.
- **`engine/`**: Orchestration and resource pooling.
- **`decorator/`**: Transformation logic (absorbed the `pipeline/` directory).

---

## v0.6.0 to v0.6.1 (Layout Stability)

### 1. Unified Formatter Configuration
**Breaking**: `LogField` is replaced by `LogMetadata`. All modern formatters now use a unified constructor API.
- **Migration**: Pass `Set<LogMetadata>` (e.g., `{LogMetadata.timestamp}`) to your formatter. Core fields like `level` and `message` are now automatic.

### 2. Implicit Layout Management
**Change**: The `Handler` framework now owns the wrapping logic (Unified Layout Sovereignty).
- **Benefit**: Decorators no longer implement wrapping. They receive lines pre-cut to the available content slot.
- **New API**: Custom structural decorators must implement `paddingWidth` to declare their footprint.

### 3. API Protection
**Breaking**: `Handler.log` and the `LogEntry` constructor are now **`@internal`**.
- **Migration**: Always interface with the system via the `Logger` API (e.g., `logger.info()`).

---

## v0.5.0 to v0.6.0 (Semantic Data)

### 1. Platform-Agnostic Styling
**Change**: `ColorDecorator` is deprecated in favor of `StyleDecorator` and the `LogTheme` system. Styles are now instructions (Bold, Dim) rather than hardcoded ANSI codes.

### 2. Semantic Pipeline
**Change**: The pipeline now passes `Iterable<LogLine>` containing tagged `LogSegment`s.
- **Benefit**: 100% accurate styling of timestamps, levels, and borders without Regex.

---

## 🗺 Breaking Changes Map

| Version | Feature | Technical Impact |
|---|---|---|
| **v0.5.0** | Centralized Layout | `lineLength` moved from formatters to `Handler`. |
| **v0.6.0** | Metadata System | `LogField` → `LogMetadata`. |
| **v0.6.1** | Internal Guards | `Handler.log` and `LogEntry` marked as `@internal`. |
| **v0.6.1** | Unified Layout | Explicit wrapping phase moved to `Handler`. |
| **v0.6.1** | Deprecation | `BoxFormatter` removed; `ColorDecorator` deprecated. |
| **v0.7.0** | Engine API | `LogEngine` and `LogPipelineFactory` become public. `StandardEngine` default. |
| **v0.7.0** | Structural Overhaul| Files moved to `document/`, `layout/`, `engine/`, and `decorator/`. |
| **v0.8.4** | Flutter Decoupling | Flutter SDK dependency removed. `Logger.attachToFlutterErrors` API removed. |

