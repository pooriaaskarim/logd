# Changelog

## 0.6.0: LLM-Optimized Logging & Shared Data Model

### ⚠️ Breaking Changes
- **Styling Engine Overhaul**: Replaced the terminal-bound `AnsiColorConfig` and `AnsiColorScheme` with a platform-agnostic **`LogTheme`** system. Visual intent is now decoupled from platform representation.
- **Unified Formatter API**: Standardized metadata extraction via the **`LogField`** enum. 
  - **Removed**: Individual boolean flags (e.g., `showLevel`, `includeTime`) in `JsonFormatter` and `ToonFormatter`.
  - **Note**: Customizable field support for legacy formatters is planned for future versions.
- **Strict Logger Naming**: Enforced deterministic hierarchy traversal via name validation (regex: `^[a-z0-9_]+(\.[a-z0-9_]+)*$`) and automatic normalization to lowercase. This prevents "Ghost Hierarchies" caused by case sensitivity or invalid characters.
- **Decorator Migration**: `ColorDecorator` is now a deprecated alias for **`StyleDecorator`**. All visual transformations now flow through the `LogTheme` resolution logic.

### 🚀 Major Overhauls & Features
- **ToonFormatter (LLM-Native)**: Introduced **Token-Oriented Object Notation (TOON)**, a header-first streaming format optimized for AI agent context efficiency.
- **Semantic Styling Pipeline**: The internal pipeline now emits rich **`LogStyle`** metadata. Sinks are now responsible for final rendering (e.g., translating `Bold` and `Dim` into ANSI codes or CSS classes).
- **Style Resolution Precision**: Enhanced `JsonPrettyFormatter` to correctly tag and style nested JSON values by mapping them to their corresponding `LogField` types.
- **Shared Field Logic**: Core log metadata (Timestamp, Level, Logger, Message, Error, StackTrace) is now extracted via a centralized, type-safe provider used by all modern formatters.

### 📚 Documentation Suite
- **Technical Manuals**: Completely rebuilt the `doc/` module with high-precision architectural guides:
  - **[Architecture](doc/handler/architecture.md)**: Details the 4-stage pipeline and operational context (`LogContext`).
  - **[Migration Guide](doc/handler/migration.md)**: Outlines the transition from monolithic "God Components" to decentralized behaviors.
  - **[Philosophy](doc/logger/philosophy.md)**: Documents foundational principles like Hierarchical Inheritance and Lazy Resolution.
  - **[Decorator Composition](doc/handler/decorator_compositions.md)**: Explains execution priority and data-model flow.
- **Roadmap Pivot**: Updated future priorities to include **Structured Context Support** and a **Web-Based Logd Dashboard**.

 
## 0.5.0: Centralized Layout & Rigid Alignment
- ### Core Architecture & Layout
  - **Centralized Layout Management**: Introduced a rigid layout system where `Handler.lineLength` acts as the primary constraint, falling back to `LogSink.preferredWidth` (e.g., 80 for Terminal, dynamic for others)
  - **LogContext Evolution**: `LogContext` now carries `availableWidth`, serving as the single, authoritative source of truth for all layout calculations in formatters and decorators
  - **Parameter Cleanup**: Removed deprecated and redundant `lineLength` parameters from `StructuredFormatter`, `BoxDecorator`, and `BoxFormatter` to enforce centralized control and reduce API surface
- ### Component Enhancements
  - **Const-Friendly Decorators**: Migrated `BoxDecorator` and `JsonPrettyFormatter` to `const` constructors where possible, improving initialization performance
  - **Logical Segment Tags**: Added `LogTag.prefix` to support specialized content prefixes from `PrefixDecorator`, providing better isolation from header coloring
  - **PlainFormatter Refinement**: Improved multi-line message handling in `PlainFormatter` to yield distinct segments, preventing structural breaks during decoration
- ### Quality & Safety
  - **Width Clamping**: Consistent width clamping across the pipeline ensures stability even with extremely narrow terminal configurations
  - **Zero-Lint State**: Resolved all lingering linting warnings related to the layout API transition across the entire core library, examples, and test suite
  - **Comprehensive Test Migration**: Full coverage of the new layout model in `null_safety_test.dart`, `layout_safety_test.dart`, and `decorator_composition_test.dart`

## 0.4.2: Semantic Segments & Visual Overhaul
- ### Core Architecture & Structure
  - **Directory Overhaul**: Centralized internal modules under `lib/src/core/` (coloring, context, utils, logger, time, stack_trace) for cleaner package organization
  - **Semantic Tagging Engine**: Migrated the entire pipeline to a segment-based architecture. Formatters now emit `LogLine` objects composed of `LogSegment`s with rich semantic tags (`LogTag`)
- ### New Formatters & Sinks
  - **JsonSemanticFormatter**: Outputs structured JSON containing both raw data and semantic metadata for programmatic analysis
  - **MarkdownFormatter**: Generates beautifully structured Markdown with support for headers, code blocks, and nested lists
  - **HTMLFormatter & HTMLSink**: Dedicated system for producing semantic HTML logs with customizable CSS mapping for browser visualization
- ### Visual Enhancements
  - **Advanced Header Wrapping**: `StructuredFormatter` now intelligently wraps long headers (logger names, levels, timestamps) while preserving fine-grained semantic tags where possible
  - **Expanded Color System**: Refined `ColorScheme` and `ColorConfig` to leverage semantic tags for precise, multi-layered coloring
- ### Developer Experience
  - **Logd Theatre Showcase**: A new flagship example (`example/log_theatre.dart`) providing an interactive, "dashboard-style" demonstration of the entire library capability
  - **Test Rationalization**: Consolidated the fragmented edge-case test suite from 16 files into 5 high-impact safety suites, improving test speed and maintainability
- ### Maintenance & Fixes
  - **Version Correction**: Unified versioning across documentation and package metadata
  - **General Stability**: Fixed several edge-case wrapping bugs in `StructuredFormatter` and `BoxDecorator`

## 0.4.1: Handler Robustness & Stability
- ### Critical Bug Fixes
  - **FileSink Race Condition:** Implemented mutex-based synchronization to serialize concurrent writes, preventing data loss during rapid logging
  - **TimeRotation Accuracy:** Fixed timestamp tracking by updating `lastRotation` after successful writes, ensuring correct rotation triggers
  - **Rotation Error Resilience:** Enhanced error handling to continue writing to original file when rotation fails, preventing data loss
  - **BoxDecorator Width:** Fixed internal content width calculation (`lineLength - 2`) and added width clamping to prevent crashes
  - **PlainFormatter Multi-line:** Now joins multi-line messages to prevent format breaks in file logs
- ### ANSI Code Handling
  - Added `wrapVisiblePreserveAnsi()` to maintain ANSI styles across line breaks, fixing style loss in wrapped content
  - Added `padRightVisiblePreserveAnsi()` to ensure padding inherits styling, preventing visual gaps in colored headers
  - Introduced `AnsiColorScheme` and `AnsiColorConfig` for structured color customization
  - Replaced boolean `colorHeaderBackground` with explicit `AnsiColorConfig(headerBackground: true)`
- ### Robustness & Idempotency
  - Width clamping in `StructuredFormatter` and `BoxDecorator` prevents negative width crashes
  - `BoxDecorator` idempotency check prevents nested box decorations
  - Fixed `LogBuffer` to avoid unnecessary stack trace creation during sink
- ### Examples & Documentation
  - Added 17 comprehensive examples covering basic setups, formatters, decorators, sinks, filters, and edge cases
  - Updated `docs/handler/README.md` with color customization and edge case handling info
  - Added migration guide for `BoxFormatter` and color configuration changes
- ### Test Coverage
  - Added 13+ edge case test files validating concurrency, null handling, Unicode, ANSI codes, extreme widths, rotation timing, and error handling
  - Over 2,400 new lines of test code ensuring robust behavior under edge conditions

## 0.4.0: Context-Aware Decorators & Visual Refinement
- ### Context-Aware Decoration Pipeline
  - **Full Context Access:** `LogDecorator.decorate()` now accepts the full `LogEntry` object, granting decorators access to metadata like `hierarchyDepth`, `tags`, and `loggerName` for smarter transformations.
  - **Automatic Composition Control:** The `Handler` automatically sorts decorators by type (Transform → Visual → Structural) to ensure correct visual composition, with deduplication to prevent redundant processing.
- ### Visual Refinements
  - **Independent Coloring:** `BoxDecorator` now supports its own `useColors` parameter, allowing the structural border to be colored independently of the content. `ColorDecorator` can now be focused purely on content styling.
  - **Header Highlights:** `ColorDecorator` adds a `colorHeaderBackground` option to apply bold background colors specifically to log headers, improving scannability in dense logs without bleeding into structural elements.
  - **Hierarchy Visualization:** Introduced `HierarchyDepthPrefixDecorator` (formerly experimented as `TreeDecorator`). It adds visual indentation (defaulting to `│ `) based on the logger's hierarchy depth, creating a clear tree-like structure in the terminal.
- ### API & Robustness
  - **Simplified BoxDecorator:** Removed internal complexity from `BoxDecorator`, making it a pure `StructuralDecorator` focused on layout.
  - **Robustness Tests:** Expanded test suite to cover deep decorator composition, ensuring that complex chains (Color -> Box -> Indent) render correctly without layout artifacts.

## 0.3.1: Logger Architecture Refactor & Performance Optimization + Critical Bug Fix

- ### Bug Fix: Corrupted Pure Dart support fixed
  - Version 0.3.0 dropped support for pure dart due to a mis-used library. **Fixed in version 0.3.1**.

- ### Architectural Shift: Separated Configuration from Resolution
  - **`LoggerConfig` & `LoggerCache`:** Introduced a dual-component architecture for logger configuration. `LoggerConfig` now strictly holds raw, explicitly set configuration values, while the new `LoggerCache` handles the hierarchical resolution (inheritance) and provides a high-performance caching layer.
  - **Versioned Invalidation:** Implemented a version-based cache invalidation mechanism. `LoggerConfig` tracks changes via a `_version` counter, allowing `LoggerCache` to lazily re-resolve effective settings only when the source configuration or its ancestry changes.
  - **Thread-Safety & Immutability:** Resolved configuration objects (like `handlers` and `stackMethodCount`) are now returned as **unmodifiable** collections, protecting the internal state from accidental external mutation.
- ### Performance: Deep Equality Optimization
  - **Smart Reconfiguration:** `Logger.configure` now performs deep equality checks on collections using internal `listEquals` and `mapEquals` utilities. This prevents redundant cache invalidations and descending tree walks when passing new collection instances that contain identical configurations.
  - **Comprehensive Equality Support:** Implemented `operator ==` and `hashCode` across the entire configuration surface, including:
    - **Handlers:** `Handler` now correctly compares its formatter, sink, filters, and decorators.
    - **Time Engine:** `Timestamp` and `Timezone` (including DST rules and transition logic) now support value-based equality.
    - **Stack Logic:** `StackTraceParser` and `CallbackInfo` now support deep comparison.
    - **Filters & Formatters:** `LevelFilter`, `RegexFilter`, `PlainFormatter`, `BoxFormatter`, and `JsonFormatter` are now value-comparable.
- ### Resilience & Testing
  - **InternalLogger Resilience:** Added targeted tests to verify that `InternalLogger` remains safe and circular-logging-free even when primary handlers fail, preventing stack overflows during failure recovery.
  - **Deep Inheritance:** Expanded the test suite to cover complex, multi-level hierarchy inheritance with partial overrides, ensuring configuration correctly "bubbles" through the tree.
  - **LogBuffer Integration:** Verified the instance-based `LogBuffer` API (`logger.infoBuffer`) and its integration with the logging pipeline.
- ### API & Maintenance
  - **Immutability Enforcement:** Applied `@immutable` annotations to all core configuration and handler classes, providing better compile-time safety and alignment with modern Dart best practices.
  - **Core Utilities:** Centralized collection equality logic into `src/core/utils.dart`.

## 0.3.0: Robust Fallback Logging & Handler Resilience
- ### Fallback Logger for Circularity Prevention
  - Introduced `InternalLogger`, a safe, direct-to-console logging mechanism for library-internal errors.
  - This prevents circular logging loops where a failure in a sink (like `FileSink`) could trigger another error log, leading to infinite recursion.
  - Integrated `InternalLogger` into `Logger`, `FileSink`, `MultiSink`, `LogBuffer`, and `Timezone`.
- ### Improved Handler Resilience
  - `Logger` now catches errors from individual handlers. If one handler fails, it reports the error via `InternalLogger` and continues to process other handlers.
  - `MultiSink` now iterates through its sinks and handles individual sink failures independently, ensuring a single failing sink doesn't stop the entire output pipeline.
- ### Bug Fixes & API Refinements
  - **StackTraceParser:** Fixed a regex bug that prevented parsing frames with spaces in method names, such as `<anonymous closure>`.
  - **API Visibility:** Unhidden `LogEntry` in the public API, as it is required for users to implement custom `LogFormatter` instances.
  - **InternalLogger Visibility:** Marked `InternalLogger` as `@internal` to keep it out of the public surface while still available for internal use.

## 0.2.3: Decoupled System Dependencies for Enhanced Testability
- ### Internal Service Locator for System Dependencies
  - Introduced an internal `Context` class to act as a service locator for system-level dependencies like `Clock` and `FileSystem`.
  - This decouples the library from concrete implementations (e.g., `DateTime.now()`, `dart:io`), making it possible to inject mock implementations during testing.
  - Added `@visibleForTesting` annotations to allow injecting custom `Clock` and `FileSystem` instances in test environments.
  - This change significantly improves the testability and reliability of time-sensitive and file-system-dependent components.

## 0.2.2: Enhanced FileSink Rotation & Custom Formatters
- ### Custom Filename Formatters for Rotated Logs
  - `SizeRotation` and `TimeRotation` now accept an optional `filenameFormatter` function.
  - This allows developers to define custom naming schemes for rotated log files, providing more control over backup organization.
- ### Robust File Rotation & Cleanup Logic
  - The backup cleanup logic has been refactored to be more reliable. It now sorts backup files by their last modified timestamp to determine which to delete, instead of parsing potentially fragile filenames.
  - `SizeRotation` now correctly renames the current log file to the first backup (e.g., `.1`) before compression.
- ### Improved Argument Validation & Reliability
  - `FileSink` now validates the `basePath` to ensure it is not empty or a directory.
  - `FileRotation` and `TimeRotation` constructors now throw an `ArgumentError` for invalid arguments (e.g., negative `backupCount`), replacing previous `assert` checks.
  - `FileSink.write()` now writes to the file with `flush: true` to ensure data is immediately persisted.

## 0.2.1: Comprehensive Time Component Testing & Fixes
- ### Comprehensive Unit Testing
  - **`Time` & `Timezone` Tests:** Added `time_test.dart` and `timezone_test.dart` to verify mockable providers and extensive DST calculations across various rules and hemispheres.
  - **`Timestamp` Formatter Tests:** Added `timestamp_test.dart` to validate formatters, literal parsing, edge cases, and timezone handling.
- ### Bug Fixes & Refinements
  - **Timestamp Formatting:** Corrected `iso8601` and `rfc2822` formatters by removing extra single quotes to fix timezone literal rendering. The formatter token parser was also updated to correctly handle tokens containing underscores and digits.
  - **DST Rules:** Updated internal DST transition rules for several European timezones (`Europe/Paris`, `Europe/London`, `Europe/Berlin`) to use the correct local transition times.
  - **Time Class:** Renamed `Time.resetTimeProvide()` to `Time.resetTimeProvider()` for consistency.
  - **Code Simplification:** Replaced a manual Zeller’s congruence implementation for calculating the day of the week with a simpler call to `DateTime.utc().weekday`.

## 0.2.0: Time Engine Overhaul & Mockable Time Provider
- ### Timestamp & Timezone Overhaul (Performance, DST, API)
  - **Performance:** Implemented a cached token system, eliminating the need to re-parse redundant formatters on every call.
  - **Mockable Time Provider:** Introduced a mockable time provider (`Time.timeProvider`) for robust testing of time-sensitive logic. The `Time` class is now encapsulated with controlled access via `setTimeProvider()` and `resetTimeProvider()`.
  - **DST Support:** Added full support for Daylight Saving Time (DST). The local timezone will resolve to a DST-aware timezone if available on the platform.
  - **`timezone` Renaming (Backward Incompatible):** The `timeZone` parameter was renamed to `timezone` for consistency. The `TimeZone` class was also renamed to `Timezone`.
  - **DST Calculation Fix:** Improved the DST offset calculation logic to better handle transitions.
  - **Platform Support:** Enhanced platform-aware timezone detection, now including web support.
- ### Advanced `Timestamp` Formatter
  - **Literal Support**: The formatter now supports single-quoted literals (e.g., `'on'`, `'at'`) to include static text in the output.
  - **New Format Tokens**:
    - `'F...'`: For microseconds (for high-accuracy benchmarking).
    - `'E...'`: For weekdays (e.g., 'Monday').
    - `'a'`: For lowercase "am/pm".
    - `'z'`: For a standard-compliant timezone offset string (e.g., `Z` or `+0330`).
  - **Token Changes:** Removed the 'SSSS' token as it was redundant.
  - **Factory Constructors**: Introduced common factory constructors like `Timestamp.iso8601()`, `rfc3339()`, `rfc2822()`, and `millisecondsSinceEpoch()`.
- ### Other Changes & Refinements
  - **API Clarity:** Renamed `LogBuffer.sync()` to `LogBuffer.sink()`.
  - **Improved Error Handling:** `LogBuffer` and `FileSink` now use the logger instance for error reporting instead of `print()`.
  - **Code Refinements:** Internal function and variable names related to timezones have been unified for better readability.

## 0.1.5: Async Logging / File Rotation
- ### Asynchronous Logging Pipeline
  -   The entire logging pipeline, from `logger.log()` to `handler.log()` and `sink.output()`, is now `async`.
  -   This prevents I/O operations (like file or network writes) from blocking the main thread.
  -   Error handling has been added to logging calls to catch and print exceptions that occur during the logging process itself.
- ### Advanced File Sink with Rotation
  -   Introduced `FileRotation` abstract class to enable log file rotation policies.
  -   Added `SizeRotation`: Rotates log files when they exceed a specified size (e.g., '10 MB').
  -   Added `TimeRotation`: Rotates logs based on a time interval.
  -   Both rotation policies support keeping a configured number of backup files and optional `gzip` compression for rotated logs.
- ### Minor Refinements
  -   `MultiSink` now outputs to all its sinks concurrently using `Future.wait`.
  -   Added `//ignore: one_member_abstracts` to `LogFilter` and `LogFormatter` to clean up analyzer warnings.

## 0.1.3: Pure Dart Support / Instantaneous Cached Configurations
- ### Pure Dart Optimizations
  - logd in now Dart ready. Decoupled from Flutter dependencies in favor of Dart standalone support.
- ### Instantaneous Cached Configurations
  - **Introduced `_LoggerConfig`:** Configuration is now stored in a separate internal `_LoggerConfig` class, decoupling it from the `Logger` instance itself. This allows `Logger` to act as a lightweight proxy.
  - **Improved Dynamic Hierarchy Propagation:** Configuration changes now dynamically propagate down the logger tree. 
  - **Cached Configuration:** Resolved configuration values are now cached to improve performance by avoiding repeated hierarchy lookups. Caches are automatically cleared when parent configurations change.
  - **Simplified `configure()`:** The `configure()` method now updates the configuration in-place rather than creating a new `Logger` instance.
  - **Normalized Logger Names:** Logger names are now consistently normalized to lowercase to ensure case-insensitivity. The root logger is consistently referred to as 'global'.
  - **Refactored `freezeInheritance()`:** The `freezeInheritance()` method has been updated to work with the new `_LoggerConfig` model, "baking" the current resolved configuration into descendant loggers.
  - **Removed `attachToUncaughtErrors()`:** The method was removed from the `Logger` class.
- ### TimeZone Improvements
  - The `Timestamp` constructor's `formatter` parameter is now required.
  - A new factory constructor, `Timestamp.none()`, is introduced to create a `Timestamp` with an empty formatter.
  - `TimeZone.local()` now correctly includes the system's current time zone offset.
- ### Improved FileSink (Still Under Development)
  - Automatically create parent directories for the log file path.
  - Add more robust error handling:
  - Rethrow exceptions in debug mode for easier debugging.
- ### Comprehensive example demonstrating all `logd` features

## 0.1.2: Minor API Changes

## 0.1.1: Dynamic Logger Tree Hierarchy Inheritance
- ### Dynamic Inheritance
  - Logger tree is now dynamically propagated, rooting at 'global' logger
  - freezeInheritance() is introduced to bake configs into a logger (and it's descendant branch, if any).
  - global getter ditched in favor of uniformity: access global logger using get() or get('global').

## 0.1.0: Dot-separated Logger Tree Hierarchy + Handlers
- ### New Api
  - Logger has new Api surface.
  - Introduced Dot-separated Logger Tree Hierarchy.
  - Introduced functionalities to attach to Flutter/Dart Error and Unhandled Exceptions
- ### Logger Tree Hierarchy
  - Loggers are named, now with a Dot-separated mechanism to inherit from their parent if not explicitly set. (Under Development)
  - global Logger (still) available.
  - Child propagation. (Under Development)
- ### Handlers
  - Introduce Handlers:
    This Replaces Printers in V 0.0.2, no backward compatibility here!
  - Introduced LogFormatters:
    Separated formatting LogEntries from outputting.
  - Introduced LogSinks:
    Separated outputting LogEntries from formatting.
  - Introduce LogFilters
    A way to filter out specific log entries.
- ### Better Structure and Documentation

## 0.0.2: Modularity + Printers
- ### Introduced Modular Loggers
- ### Introduced LogEvents
- ### Introduced Printers
  - Printers are a way of outputting data. (Soon to be replaced with Handlers: Formatters and Sinks)

## 0.0.1: Initial version
- ### Logger Daemon
  - Uses LogBuffer to collect  and output data.
- ### Simple BoxPrinter
  - Formats output in a simple box.
- ### StackTraceParser
- ### TimeStampFormatter and TimeZone
