# logd Product — Status
> Current as of: v0.8.7 | Updated: 2026-07-08

---

## Active Product Focus
Completing pre-release tasks for `logd_linters` (v0.1.0-RC verification and publishing checklist), planning Phase A concurrency stress testing, and documenting Core architecture decisions (ADRs).

---

## High-Level Milestone Tracking

| Milestone | Target Scope | Status |
|---|---|---|
| **v0.8.7 (Core Stable)** | Concurrency, FIFO waiter queue, isolate crash recovery, HTML control panel | ✅ Released |
| **v0.1.0 (logd_linters)** | Publish custom lint rules to pub.dev, align core dependencies | ⏳ Ready to Publish |
| **Phase A (Hardening)** | Concurrency stress tests, ADRs, immutability audits, timezone offset benchmark | 🟡 Active |
| **Phase B (Async & DB)** | `AsyncFormatter`, `SqliteSink`, `SentrySink`, JS source-mapped web traces | 🔲 Planned |
| **Phase C (Dashboard)** | `HttpServerSink` WebSocket React dashboard, HTML log consolidation | 🔲 Planned |
| **Phase D (Output Overhaul)** | `LogSurface`, WCAG `lightScheme`, self-declaring wrappers, session handle lifecycle | 🔲 Planned (v0.9.0/v1.0.0) |

---

## Out-of-Scope (Explicitly Deferred)
- **Automatic log rotation UI**: Not planning to support configuration or log parsing dashboards. Keep `logd` as a pure, lightweight engine.
- **Direct database sinks**: No immediate plans to build official SQL/NoSQL sinks. Let community plugins handle storage.
- **Fluent logger builders**: Let configuration remain structured (`Logger.configure`) rather than builder-based, keeping the API footprint small.

---

## Active Product Decisions

- **Why linters are a separate package**: Kept separate from `logd` to avoid inflating the core package's dependency footprint with custom lint dependencies.
- **Why we decoupled Flutter**: In v0.8.4, we fully decoupled the Flutter SDK so `logd` can be utilized in CLI utilities, server applications, and pure VM scripts, preventing package dependency conflicts with Flutter versions.
- **No premature facades**: The `LogOutput` facade is explicitly deferred until the underlying pipeline changes (surface, wrapping, lifecycle) settle.
