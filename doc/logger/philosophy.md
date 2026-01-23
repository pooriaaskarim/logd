# Design Philosophy

This document outlines the architectural principles and design decisions behind the `logd` logger module.

## 1. Hierarchical Inheritance

The primary design goal of `logd` is to mirror the hierarchical nature of software systems. Just as classes belong to packages, loggers belong to namespaces.

### Principle
Loggers are organized in a tree structure using dot-separated names (e.g., `root` -> `app` -> `app.ui`). A logger inherits its configuration (Level, Handlers) from its nearest configured ancestor.

### Deterministic Validation
To ensure predictable hierarchy traversal, `logd` enforces strict naming rules:
- **Regex**: `^[a-z0-9_]+(\.[a-z0-9_]+)*$`
- **Lowercase**: All names are normalized to lowercase to prevent "Ghost Hierarchy" issues where `App.UI` and `app.ui` would otherwise be treated as siblings.
- **Single Source of Truth**: All loggers are registered in a central, static **Registry** (@internal). This ensures that requesting the same name from anywhere in the app always returns the same instance.

## 2. Sparse Configuration & Lazy Resolution

To maintain high performance and low memory footprint, `logd` avoids duplicating configuration data.

### Sparse Configuration
The `LoggerConfig` object stores *only* values that satisfy an explicit override. If a value is `null`, it implies inheritance.

### Lazy Resolution
The effective configuration for a logger is not computed until it is accessed.
1. Upon access, the system traverses the hierarchy from the leaf (logger) to the root (`global`).
2. The resolving logic fills in gaps using parent configurations.
3. The result is cached in a specialized `_ResolvedConfig` object for O(1) access in subsequent calls.

## 3. Performance Optimization

### Version-Based Cache Invalidation
The system utilizes a versioning strategy. Modifying a parent node increments its version, signaling dependent children to invalidate their cached configurations lazily. This avoids expensive tree-walking operations during configuration updates.

### Deep Equality Checks
`logd` employs **Deep Equality** on collection parameters (like `handlers` or `filters`) during configuration. If a configuration is logically identical (even if it's a new object), the library skips the cache invalidation cycle.

### Inheritance Freezing
For hot-paths where even the overhead of checking a version number is too high, the library supports `freezeInheritance()`.
- **The Optimization**: It flattens the resolved configuration and bakes it into a private, immutable instance.
- **Trade-off**: The logger becomes disconnected from future parent configuration updates, but achieves the absolute minimum CPU overhead possible in Dart.

## 4. Stability and Safety (The Fail-Safe Core)

Logging is a diagnostic tool and must not introduce instability into the application.

### The Problem: Circularity
If a `FileSink` fails (e.g., Disk Full), and that error is logged via the standard hierarchy, it may trigger the same failing `FileSink`, causing an infinite loop.

### The Solution: InternalLogger
`logd` utilizes an **InternalLogger** that:
- Bypasses the user-defined handler pipeline.
- Outputs directly to platform standard streams.
- Is used for all internal library errors, ensuring that even if the logging system is broken, the failure is reported without crashing the host application.

### Immutability
To prevent race conditions, resolved configurations provided to clients are immutable. Modification of active configurations is restricted to the comprehensive `Logger.configure` API, which handles synchronization safely.
