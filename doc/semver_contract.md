# Semantic Versioning Contract (v0.9.0+)

This document defines the formal API contract and Semantic Versioning (SemVer) rules for `package:logd` and its satellite packages.

---

## 1. API Stability Classifications

To balance fast-paced innovation with library stability, all public exports are classified into one of three stability tiers:

### A. Implicitly Stable (Default)
- **Definition**: Any public-facing class, method, property, constructor, or enum that is exported by `package:logd/logd.dart` and does not carry an explicit `@experimental` or `@internal` annotation.
- **Guarantee**: Guaranteed backwards-compatible throughout the major version lifecycle (e.g. all `1.x.x` releases). Breaking changes to stable symbols require a major version increment.

### B. Experimental (`@experimental`)
- **Definition**: Publicly accessible symbols decorated with the `@experimental` annotation from `package:meta`.
- **Reasoning**: Used for native FFI bindings (`Arena`, `NativeEngine`, `ArenaEngine`), multi-threaded isolate sinks (`IsolateSink`, `NativeIsolateSink`), or network/server configurations (`HttpServerSink`) that are undergoing optimization and might change in minor or patch releases.
- **Guarantee**: Subject to change or removal in any version (including minor/patch releases). Developers using experimental APIs should pin dependencies to a specific minor/patch version.

### C. Internal (`@internal`)
- **Definition**: Symbols decorated with the `@internal` annotation from `package:meta`.
- **Reasoning**: Exposes implementation details that must be public for cross-package use (such as configuration serialization or internal test utilities) but are not intended for consumer use.
- **Guarantee**: NOT part of the public API. Breaking changes can occur at any time without version increments. Do not reference internal APIs in external code.

---

## 2. Rules for Version Increments

| Increment Type | Allowed Changes | Stability Impact |
|---|---|---|
| **Major (X.0.0)** | - Breaking changes to Implicitly Stable APIs.<br>- Deprecation removals.<br>- Heavy dependency extractions. | High |
| **Minor (0.X.0 / X.Y.0)** | - New backward-compatible features.<br>- Breaking changes or removals of `@experimental` APIs.<br>- Deprecations added to Stable APIs. | Medium |
| **Patch (0.0.X / X.Y.Z)** | - Bug fixes and optimization passes.<br>- Backwards-compatible documentation/lint updates. | Low |

---

## 3. Extension Point API Freeze

Starting with **v0.9.0**, the core extension interfaces and base orchestrators are frozen as **Implicitly Stable**:
- [LogFormatter](file:///a:/Projects/logd/packages/logd/lib/src/handler/formatter/formatter.dart)
- [LogDecorator](file:///a:/Projects/logd/packages/logd/lib/src/handler/decorator/decorator.dart)
- [LogSink](file:///a:/Projects/logd/packages/logd/lib/src/handler/sink/sink.dart)
- [Handler](file:///a:/Projects/logd/packages/logd/lib/src/handler/handler.dart)

Custom plugins, formatters, decorators, and sinks compiled against v0.9.0 are guaranteed to compile and execute without modifications on all subsequent `v0.9.x` and `v1.x.x` releases.
