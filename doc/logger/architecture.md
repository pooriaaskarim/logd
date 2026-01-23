# Architecture Overview

This document provides a technical overview of the `logd` logger module implementation. It is intended for contributors and developers requiring a deeper understanding of the internal mechanics.

## System Components

The logger module consists of three primary subsystems:
1. **The Registry**: Manages sparse configuration state.
2. **The Resolver**: Computes effective configurations based on hierarchy.
3. **The Pipeline**: Handles the creation and dispatch of `LogEntry` objects.

### 1. Configuration Registry
The `_registry` is a static map holding `LoggerConfig` objects. A `LoggerConfig` is mutable and represents the *explicit* configuration set by the user.

- **Value**: `LoggerConfig` (contains nullable fields).

### 2. Name Validation & Normalization
To ensure consistency and prevent fragile hierarchy lookups, all names pass through a normalization gate.

- **Normalization Rules**:
    - `null`, empty string `""`, and `"global"` (case-insensitive) all resolve to the root `"global"`.
    - All other names are converted to **lowercase** for case-insensitive matching.
- **Validation Rules**:
    - Pattern: `^[a-z0-9_]+(\.[a-z0-9_]+)*$` (Strictly alphanumeric with underscores, segments separated by dots).
    - Invalid segments or formatting throws an `ArgumentError`.

### 3. Resolution & Caching
The `LoggerCache` maintains the derived state of the system using a versioned-invalidation strategy.

- **_ResolvedConfig**: An immutable snapshot of a logger's effective state. It contains no nullable fields (defaults are applied if no parent provides a value).
- **Version-Based Invalidation**:
  Every `LoggerConfig` maintains a `_version` counter. When a parent logger is reconfigured, its version increments. Descendant loggers track their parent's version; if a mismatch is detected during a log call, the cache is invalidated and re-resolved lazily. 
- **Deep Equality Optimization**: 
  `Logger.configure` uses `operator ==` on all configuration components (including collections of handlers and filters). If the provided configuration is value-identical to the existing one, the version is **not** incremented, and descendant caches remain valid.

### 4. Dispatch Pipeline
When a log method (e.g., `info`) is called:
1. **The Fast Path**: The logger checks its cached `logLevel`. If disabled, it returns immediately (Zero-Cost).
2. **The Resolution Path**: If the cache is stale (due to version mismatch), the resolver performs a leaf-to-root walk.
3. **Caller Extraction**: The `StackTraceParser` identifies the call site.
4. **LogEntry & Handlers**: A `LogEntry` is constructed and passed to the handler pipeline.

## Freezing Inheritance

For critical hot-paths where logger configuration is guaranteed to be static, developers can call `logger.freezeInheritance()`.
- **Implementation**: This flattens the hierarchy by copying the parent's resolved configuration into the child's explicit configuration.
- **Result**: Future lookups bypass the resolution path entirely, reducing the logic to a single flag check and a direct field access.

## Performance Considerations

- **Cache Locality**: Once resolved, logger lookups involve a single map access.
- **Resolution walk**: Inheritance is O(D) where D is depth of hierarchy, but only occurs once per configuration change.
- **Deep Equality**: O(K) where K is number of config parameters. prevents O(N) descendant cache clears.

## Isolation

State management in `logd` is static and isolate-local.
- Configurations are **not shared** between Dart isolates.
- Multi-threaded applications using isolates must initialize logging configurations within each isolate entry point.
