# logd Isolate Model — Open Design Questions
> Status: Unresolved / Queued for v0.10.x Research | Created: 2026-08-19

---

## Decision Register (Ordered by Dependency)

### 1. Topology Declaration Model
- **Question**: Should `logd` require explicit initialization of isolate topology, or support ad-hoc isolate participation?
- **Options**:
  - A. *Explicit Roles*: `LogdIsolate.init(role: LogdIsolateRole.primary)` and `LogdIsolate.connect(primaryPort)` on worker startup.
  - B. *Implicit Discovery*: Auto-detect main isolate via Zone tokens or static registry.
- **Dependency**: Must be decided before any configuration protocol is implemented.

---

### 2. Configuration Authority & Conflict Resolution
- **Question**: Who is the authoritative source of truth for `LoggerConfig` updates?
- **Options**:
  - A. *Strict Primary Authority*: Only the primary isolate may call `Logger.configure()`. Worker calls throw `UnsupportedError` or silently request primary mutation.
  - B. *Hierarchical Override*: Primary broadcast sets baseline; workers may establish local override namespaces (e.g. `worker.compute.*`).
  - C. *Multi-Master Distributed*: Any isolate can update config, synchronized via versioned vector clocks. (High complexity).
- **Dependency**: Depends on Decision 1 (Topology Model).

---

### 3. Context & MDC Isolate Boundary Crossing
- **Question**: How should ambient `LogContext` values cross `Isolate.spawn()` boundaries?
- **Options**:
  - A. *Explicit Envelope Packaging*: Provide `LogContext.capture()` / `LogContext.runWith(capturedContext, body)`.
  - B. *Isolate Runner Helpers*: Provide `LogdIsolate.run(workerFunction, inputData)` which automatically captures ambient MDC and unpacks it in the worker isolate.
- **Dependency**: Independent, can be designed in parallel with Decision 2.

---

### 4. Entry Ingestion Architecture
- **Question**: Should all isolates log directly to their own sinks, or stream binary log packets to a centralized coordinator sink?
- **Options**:
  - A. *Centralized Coordinator*: All workers pipe binary IR to the primary/logging isolate via `SendPort`. Only one isolate touches files/terminals/sockets. Eliminates file lock contention and interleaving.
  - B. *Independent Pipelines*: Each isolate has its own sink stack.
- **Trade-offs**: Centralized eliminates file locking and formatting duplicate work, but increases GC / SendPort transfer overhead under ultra-high throughput.

---

### 5. Trace / Span Correlation Standard
- **Question**: Should `logd` implement a first-class trace/span context data structure or provide generic OpenTelemetry-compatible map hooks?
- **Options**:
  - A. Generic `LogContext` keys (`traceId`, `spanId`, `parentSpanId`) with standard convention.
  - B. Native `LogSpan` / `LogTrace` primitives in semantic IR.
