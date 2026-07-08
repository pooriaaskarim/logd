# logd Product — Roadmap & Philosophy
> Canonical product direction, philosophy, and unified roadmap.
> Synthesized from sub-module plans (logger, handler, time, stack_trace).

---

## Core Product Philosophy

> **"Simplicity integrated into complexity."**
>
> The logging engine should support complex execution needs (object pooling, native FFI, offloaded isolate workers) while exposing a clean, approachable interface for standard developers.

### Core Architectural Pillars
1. **Purity of Representation**: Formatters and decorators operate strictly on Semantic IR (`LogDocument`). Wrapping, layout, and colors are physical layer concerns managed by `TerminalLayout` and Encoders.
2. **Zero Garbage Collection Overhead**: Hot-path logging targets zero heap allocations per 10k log operations via LIFO pooling (`Arena`, `LogBuffer`) and linear serialization (`Binary IR`).
3. **Platform-Agnostic Core**: Compile-time decoupling (zero conditional exports in package entry point) ensures out-of-the-box browser/web support, VM support, and Flutter independence.

---

## Unified Roadmap (Active & Planned)

This unified roadmap synthesizes priorities across all sub-modules (see [doc/logger/roadmap.md](file:///home/ono/Projects/logd/doc/logger/roadmap.md), [doc/handler/roadmap.md](file:///home/ono/Projects/logd/doc/handler/roadmap.md), [doc/stack_trace/roadmap.md](file:///home/ono/Projects/logd/doc/stack_trace/roadmap.md), and [doc/time/roadmap.md](file:///home/ono/Projects/logd/doc/time/roadmap.md)).

```
  v0.8.7 (Core Stable)   v0.8.8 / v0.8.9 (Async / DB / Web)        v0.9.0 (Output API)     v1.0.0 (Stable Release)
           │                             │                              │                           │
  • Concurrency stress      • AsyncFormatter & Isolate worker      • LogSurface & Theme         • LogOutput Facade
  • Memory caps             • SqliteSink / Sentry / MemorySinks    • lightScheme contrast       • Session/Handle Lifecycle
  • Isolate auto-recovery   • JS Source Map Stack Parsing          • requiredStrategy auto-wrap • ADR Finalization
```

### Phase A: Concurrency, Testing & Code Hardening (Current / Active)
Focuses on VM safety, stress testing, and formalizing architecture decisions.
- **Concurrency stress testing**: Add tests for multiple isolates configuring independently, rapid `configure()` calls, and stress testing cache invalidation (P3).
- **Architecture Decision Records (ADRs)**: Create `doc/decisions/` and document key design decisions (ADR-001: Hierarchical inheritance, ADR-002: Cache invalidation, ADR-003: Sparse storage, ADR-004: Unmodifiable collections, ADR-005: InternalLogger).
- **Quality Audits**: Audit classes for immutability gaps and add null safety asserts (P3).
- **Offset Cache Validation**: Benchmark timezone offset cache performance (target: 50% lookup reduction) (P2).

### Phase B: Async Formatting, Database Sinks & Web Trace Mapping (Planned)
Focuses on offloading expensive operations and expanding target destinations.
- **Async Formatter Support (P1)**: Implement `AsyncFormatter` and `AsyncHandler` wrapper that offloads heavy serialization (e.g. complex JSON) to worker isolates to avoid blocking the calling isolate.
- **Additional Sinks (P1)**:
  - `SqliteSink`: Local database persistence with schemas.
  - `SentrySink`: Direct error tracking integration.
  - `MemorySink`: In-memory ring-buffer for test assertion and debugging.
- **Web Source Mapping (P1)**: Map JS bundle stack trace locations back to Dart source files using source maps in dev mode.

### Phase C: Web-Based Log Viewer & Consolidated HTML Output (Planned)
Focuses on remote debugging and HTML visual pipeline modernization.
- **Logd Dashboard (P2)**: Implement an `HttpServerSink` serving a small Vite/React dashboard with real-time log streaming via WebSockets, plus browser-side filtering and search.
- **HTML Logging Consolidation (P1)**:
  - Evaluate if `HtmlFormatter` should only emit structured semantic tags (like JSON).
  - Determine if `HtmlSink` CSS should be moved to a shared theme system.
  - Consider a unified `WebLogHandler` managing both static file generation and server streaming.

### Phase D: Output API Overhaul & Stable Release (Planned for v0.9.0 / v1.0.0)
Focuses on clarifying API naming, theme propagation, and beginner conveniences.
- **LogSurface Integration**: Add `LogSurface` (dark, light) to `LogTheme` to separate canvas background from level color schemes.
- **`lightScheme` Palette**: Formally introduce `lightScheme` to `LogColorScheme` with WCAG AA/AAA-compliant hex values.
- **Self-Declaring Wrapping**: Introduce `requiredStrategy` on `LogEncoder` so sinks auto-wrap outputs.
- **Beginner Facade**: Expose the `LogOutput` named constructor factory (e.g., `LogOutput.console()`, `LogOutput.htmlFile()`).
- **Teardown Lifecycle**: Transition to a Session/Handle lifecycle pattern for atomic, race-free sink disposal.
