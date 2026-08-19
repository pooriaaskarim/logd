# logd Product — Status
> Current as of: v0.9.4 | Updated: 2026-08-19

---

## Active Product Focus

v0.9.4 active development. Stack Trace Origin Bypass and Ambient Structured Context (MDC / `LogContext`) are implemented, validated, and documented.

---

## High-Level Milestone Tracking

| Milestone | Target Scope | Status |
|---|---|---|
| **v0.8.7 (Core Stable)** | Concurrency, FIFO waiter queue, isolate crash recovery, HTML control panel | ✅ Released |
| **v0.8.8 (Async / HTTP)** | AsyncHandler isolate offloading, HttpServerSink dashboard, HTML concurrency | ✅ Released |
| **v0.8.9 (Hardening)** | Web Source Mapping, polymorphic serialization fix, timezone hardening, ADRs | ✅ Released |
| **v0.1.2 (logd_linters)** | Automated quick-fixes for arena lifecycle, purity, and formatting rules | ✅ Published |
| **v0.9.0–v0.9.2 (API Hardening)** | Symbol audit, semver contract, logd_sqlite satellite package launch | ✅ Released |
| **v0.9.3 (Target Handlers)** | Pre-wired TargetHandler subclasses, dual-mode `.async()`, `advanced.dart` | ✅ Released |
| **v0.9.4 (MDC & Performance)** | Hot-path caller origin bypass, ambient structured context (`LogContext.run`) | 🟡 In Progress (PR #61) |
| **v0.10.0 (Multi-Isolate Architecture)** | Principled isolate topology, config authority, context bridging, satellite ecosystem | 🔲 Next |
| **v1.0.0 (API Freeze & Stability)** | Full stability declaration, breaking-change policy lock, deprecation guides | 🔲 Future |

---

## Current Core Package State

- **Version**: `0.9.4`
- **Dart SDK**: `>=3.6.0 <4.0.0`
- **Direct Dependencies**: `characters`, `ffi`, `http`, `matcher`, `meta`, `timezone`, `source_maps`, `source_span`, `web_socket_channel`
- **Tests**: All 2,513 unit and integration tests passing.
- **Lints**: Zero analyzer warnings across all packages.

---

## Out-of-Scope (Explicitly Deferred)
- **Automatic log rotation UI**: Not supporting configuration or log-parsing dashboards. `logd` is a pure engine.
- **Fluent logger builders**: API stays structured (`Logger.configure`), not builder-based.
- **Direct database sinks in core**: Satellite package concern only.

---

## Active Product Decisions

- **Why linters are a separate package**: Avoids inflating core package dependency footprint with custom lint tooling.
- **Why Flutter is decoupled**: Pure Dart for CLI, server, and VM use cases without Flutter SDK friction.
- **Why heavy transitive deps stay for now**: `http` and `ffi` remain in core through v1.0 with explicit deprecation notices. Extraction requires a major version bump and is a Phase 3 concern.
- **Why sinks come after API stabilization**: Building `logd_sqlite` or `logd_sentry` on an unstable `LogSink` extension point forces synchronized breaking version bumps. Extension points must be `@stable` before satellites target them.
- **No premature facades**: `LogOutput` convenience constructors deferred until the underlying pipeline surface, wrapping, and lifecycle changes settle.
