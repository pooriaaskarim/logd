# logd Isolate Model — Session Log
> Append-only. Each entry records what was attempted, what broke, and what was learned.
> Never edit past entries. Add new entries at the top.

---

## 2026-08-19 | v0.9.4 | Strategic Architectural Pivot

### What We Did
- Conducted structural audit of `logd`'s multi-isolate support following the implementation of ambient `LogContext`.
- Identified that `logd`'s Logger hierarchy, configuration registry, and context propagation are process-local singleton concepts that exist independently in each isolate's heap.
- Formally rejected the proposed `LogdIsolateHub` point-patch (a dynamic pub/sub message bus) as an immature band-aid that layers complexity over an unprincipled isolate model.
- Created the dedicated `logd_isolate_model` knowledge item to capture architectural gaps, structural challenges, and open design questions for a comprehensive v1.0 multi-isolate architecture.
- Updated product roadmap: replaced `LogdIsolateHub` with **Multi-Isolate Architecture Design (v0.10.x track)**.
- Established that `v0.10.x` is the appropriate pathway to iterate on the multi-isolate semantic model with full design freedom before making a `v1.0.0` stability commitment.

### Key Insights
- Zones used by `LogContext.run()` are isolate-local; ambient context cannot cross isolate boundaries without explicit serialization.
- Multi-isolate support cannot be solved piecemeal; it requires formalizing isolate topology, configuration authority, ambient context bridging, and centralized vs. distributed entry ingestion.
