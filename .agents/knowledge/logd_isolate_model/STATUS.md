# logd Isolate Model — Status
> Current as of: v0.9.4 | Created: 2026-08-19

---

## Maturity Assessment
**Current State**: *Deployment-level convenience; semantic model is primary-isolate-centric.*

The current multi-isolate capabilities (`AsyncHandler`, `.async()` target handler factories, `NativeIsolateSink`) successfully offload heavy serialization, formatting, and physical I/O to background isolates. However, the core semantic model (`Logger` hierarchy, configuration registry, ambient context, filter trees) remains local to each isolate's heap.

---

## Capability Breakdown

| Component / Layer | State | Details |
|---|---|---|
| `AsyncHandler` / `IsolateWorker` | ✅ Stable | Reusable background worker isolate lifecycle, message queue, error restart. |
| `NativeIsolateSink` | ✅ Stable | Auto-respawn on worker crash (2s backoff), startup pre-ready packet buffering. |
| `LoggerSerializationRegistry` | ⚠️ Point Patch | Static snapshot serialization of `LoggerConfig` across isolates via `exportConfig()` / `importConfig()`. |
| `LogBrightness` Serialization | ✅ Stable | Theme brightness state correctly preserved across isolate boundaries. |
| `LogContext` Zone Propagation | ❌ Local Only | Dart `Zone`s do not cross isolate boundaries. Ambient context must be explicitly copied into `SendPort` payloads. |
| Configuration Authority | ❌ Undefined | Primary isolate owns config by convention only. Worker isolate mutations silently diverge. |
| Dynamic Config Synchronization | ❌ Immature / Deferred | Point-patch `LogdIsolateHub` rejected in favor of formal multi-isolate system design. |
| Cross-Isolate Trace Correlation | ❌ Missing | No native trace ID / span ID propagation protocol across isolate message ports. |
| Unified Entry Pipeline | ❌ Undefined | Worker isolates either maintain independent logging pipelines or stream raw serialized packets to primary sink. |

---

## Active Roadmap Position
- **Status**: Research & Design Phase for **v0.10.x track** (formal multi-isolate architecture).
- **Decision**: Reject point-patch synchronization bus (`LogdIsolateHub`) in v0.9.x to avoid layering patches on top of an unprincipled isolate model. Use `v0.10.x` series to iterate on the multi-isolate model before committing to `v1.0.0` API stability.
- **Reference**: See [ARCHITECTURE.md](file:///home/ono/Projects/logd/.agents/knowledge/logd_isolate_model/ARCHITECTURE.md) and [OPEN_QUESTIONS.md](file:///home/ono/Projects/logd/.agents/knowledge/logd_isolate_model/OPEN_QUESTIONS.md).
