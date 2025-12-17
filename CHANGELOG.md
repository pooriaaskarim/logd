# Changelog
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
