# logd Product — Status
> Current as of: v0.8.9 | Updated: 2026-07-18

---

## Active Product Focus

v0.8.9 is released (PR #52 open → master). Both `logd` v0.8.9 and `logd_linters` v0.1.2 are published to pub.dev.

The roadmap has been strategically revised. The next active phase is **Phase 1 (API Stabilization)** targeting the v0.9.x release series.

---

## High-Level Milestone Tracking

| Milestone | Target Scope | Status |
|---|---|---|
| **v0.8.7 (Core Stable)** | Concurrency, FIFO waiter queue, isolate crash recovery, HTML control panel | ✅ Released |
| **v0.8.8 (Async / HTTP)** | AsyncHandler isolate offloading, HttpServerSink dashboard, HTML concurrency | ✅ Released |
| **v0.8.9 (Hardening)** | Web Source Mapping, polymorphic serialization fix, timezone hardening, ADRs | ✅ Released |
| **v0.1.2 (logd_linters)** | Automated quick-fixes for arena lifecycle, purity, and formatting rules | ✅ Published |
| **Phase 1 (API Stabilization)** | Symbol annotation audit, semver contract, DX pass, extension point freeze | 🔲 Next |
| **Phase 2 (v1.0 + Ecosystem)** | logd_sqlite, logd_memory, logd_sentry, LogOutput facade, deprecation notices | 🔲 Planned |
| **Phase 3 (Lean Core)** | logd_http, logd_socket, logd_native split out, core dependency reduction | 🔲 Planned |

---

## Current Core Package State

- **Version**: `0.8.9`
- **Dart SDK**: `>=3.6.0 <4.0.0`
- **Direct Dependencies**: `characters`, `ffi`, `http`, `matcher`, `meta`, `timezone`, `source_maps`, `source_span`, `web_socket_channel`
- **Dependencies to Extract in Phase 3**: `ffi`, `http`, `web_socket_channel`
- **Tests**: All 2,439 unit and integration tests passing.
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
