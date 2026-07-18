# logd Product — Session Log
> Append-only. Records high-level product release decisions, milestones, and architectural pivots.
> Never edit past entries. Add new entries at the top.

---

## 2026-07-18 | v0.8.9 | Hardening, Web Source Mapping & Roadmap Pivot

- **Focus**: Phase A Hardening completion — polymorphic serialization fix, timezone input hardening and benchmarks, concurrency stress tests, Web Source Mapping, formal ADR documentation.
- **Key Decisions Recorded**:
  - Sinks (SqlSink, MemorySink, SentrySink) are satellite package concerns. They must NOT be built until the core `LogSink` / `LogFormatter` extension points are declared `@stable`.
  - The roadmap is formally restructured into 3 phases: (1) API Stabilization → (2) Major v1.0 + Ecosystem → (3) Lean Core dependency extraction.
  - `http`, `web_socket_channel`, and `ffi` are to be extracted from core in Phase 3 as a **breaking change** requiring a major version bump. They stay in core through v1.0 with explicit deprecation notices.
  - "Gradual stabilization" was criticized as too vague. Phase 1 requires concrete deliverables: symbol annotation audit (`@stable`/`@experimental`/`@internal`), semver contract document, DX quality pass, extension point freeze.
- **Released**: `logd` v0.8.9 and `logd_linters` v0.1.2 published to pub.dev.
- **PR**: [#52](https://github.com/pooriaaskarim/logd/pull/52) opened dev → master.

---

## 2026-07-08 | v0.8.7 | Concurrency & Stability Milestone

- **Focus**: Hardening VM concurrency under heavy load and final validation of the HTML encoder control panel.
- **Key Decision**: Shifted focus from starting v0.9.0 planning to core stabilization (concurrency stress testing, memory capping, auto-recovery background isolates). This ensures the engine is rock-solid before any major API overhauls.

---

## 2026-07-03 | v0.8.6 | Web Compilation Restructuring

- **Focus**: Restructured internal sub-libraries to fix a major compilation crash under browser/Web environments.
- **Key Decision**: Extracted FFI conditional stubs directly next to their VM implementations and removed all platform-specific imports from the package package-level exports. This prioritizes out-of-the-box cross-platform compliance (Web, JS, WASM).

---

## 2026-06-25 | v0.8.4 | Flutter Decoupling & Testing Harness

- **Focus**: Decoupled the logging pipeline from the Flutter SDK and added a dedicated test harness (`package:logd/testing.dart`).
- **Key Decision**: Flutter was moved to `dev_dependencies`. This allows backend CLI and server-side Dart tools to utilize `logd` without dragging the Flutter framework along. Diagnostic metrics (`LoggerMetrics`) and pooled buffers (`LogBuffer`) were introduced to provide enterprise-grade observability.

---

## 2026-06-18 | v0.8.3 | Allocation-Free hot-path optimizations

- **Focus**: CPU latency optimization and complete garbage collection (GC) pressure elimination.
- **Key Decision**: Optimized hot execution paths (`hierarchyDepth` character scanning, JIT inlining of the cache lookup check, lazy token parsing in timestamp formatter) to target 0.00 KB of heap allocations per 10k log operations.
