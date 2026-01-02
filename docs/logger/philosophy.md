# Design Philosophy

This document outlines the architectural principles and design decisions behind the `logd` logger module.

## 1. Hierarchical Inheritance

The primary design goal of `logd` is to mirror the hierarchical nature of software systems. Just as classes belong to packages, loggers belong to namespaces.

### Principle
Loggers are organized in a tree structure using dot-separated names (e.g., `root` -> `app` -> `app.ui`). A logger inherits its configuration (Level, Formatters, Sinks) from its nearest configured ancestor.

### Rationale
In large applications, configuring every individual logger is unmaintainable. Hierarchy allows strict control over specific subsystems while maintaining sensible defaults for the rest of the application.

## 2. Sparse Configuration & Lazy Resolution

To maintain high performance and low memory footprint, `logd` avoids duplicating configuration data.

### Sparse Configuration
The `LoggerConfig` object stores *only* values that satisfy an explicit override. If a value is `null`, it implies inheritance.

### Lazy Resolution
The effective configuration for a logger is not computed until it is accessed.
1. Upon access, the system traverses the hierarchy from the leaf (logger) to the root (`global`).
2. The resolving logic fills in gaps using parent configurations.
3. The result is cached in a specialized `_ResolvedConfig` object for O(1) access in subsequent calls.

## 3. Stability and Safety

Logging is a diagnostic tool and must not introduce instability into the application.

### Fail-Safe Execution
Exceptions occurring within `Handlers` or `Sinks` (e.g., standard I/O errors) are caught internally. They are reported to `stdout` via an internal failsafe mechanism but do not propagate to the main application flow.

### Immutability
To prevent race conditions and ensure consistency, resolved configurations provided to clients are immutable. Modification of active configurations is restricted to the comprehensive `Logger.configure` API, which handles cache invalidation safely.

## 4. Performance Optimization

### Version-Based Cache Invalidation
The system utilizes a versioning strategy for cache invalidation. Modifying a parent node increments its version, signaling dependent children to invalidate their cached configurations lazily. This avoids expensive tree-walking operations during configuration updates.

### Deep Equality Checks
Configuration updates typically trigger cache invalidation. `logd` employs deep equality checks on collection parameters (like `handlers` or `stackMethodCount`) to prevent unnecessary invalidation cycles when the configuration logically remains the same.
