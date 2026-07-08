# logd Core — Status
> Current version: v0.8.7 | Updated: 2026-07-08

---

## Version Snapshot

| Area | State |
|---|---|
| Pipeline Architecture (Formatter → Decorator → TerminalLayout → Encoder → Sink) | ✅ Stable |
| Logger Hierarchy & Inheritance (`freezeInheritance`, `unfreezeInheritance`) | ✅ Stable since v0.8.2 |
| Arena / Object Pooling | ✅ Stable. LIFO pool, Finalizer leak detection |
| `NativeEngine` / Binary IR | ✅ Stable. Streaming + Object mode |
| `LogPipelineFactory` injection | ✅ Stable since factory injection refactor |
| `LoggerConfig` immutability + `copyWith` | ✅ Stable since v0.8.4 |
| `Logger.configureMultiple` + batched invalidation | ✅ Stable since v0.8.4 dev |
| `LoggerSerializationRegistry` (cross-isolate transport) | ✅ Stable since v0.8.4 |
| `package:logd/testing.dart` (`CaptureSink`, `TestLogger`, `hasLog`) | ✅ Stable since v0.8.4 |
| Flutter SDK decoupled (pure Dart CLI/VM) | ✅ Stable since v0.8.4 |
| Web compilation (zero `dart:ffi`/`dart:io` in entry point) | ✅ Fixed in v0.8.6 |
| Sub-library restructure (8 clean sub-libs) | ✅ Stable since v0.8.6 |
| Arena concurrency hardening (FIFO waiter queue, pool cap 512/1000) | ✅ Stable since v0.8.7 |
| `NativeIsolateSink` crash recovery (auto-respawn) | ✅ Stable since v0.8.7 |
| Handler timeout support | ✅ Stable since v0.8.7 |

---

## What Was Just Done (v0.8.7)

**Concurrency & Arena:**
- Thread waiter queue in `Arena` replaced single-slot waiter → no more race conditions under async saturation
- Pool cap enforced: 512 objects / 1000 buffers max
- Lazy `receivePort` lifecycle in `Arena` → no more VM test leaks

**Pipeline Safety:**
- `NativeIsolateSink` crash detection + 2s delayed respawn
- Startup pre-ready buffer capped at 200 packets
- Handler execution timeout (optional per-handler)
- `configureMultiple` now validates before any state mutation (atomic)
- Rate-limited warnings on repeated handler failures
- `SocketSink` exponential backoff (capped at 5 min)

**Performance:**
- `NetworkSink`: List → Queue for O(1) removals
- Lazy `StackTrace.current` — not evaluated if explicit trace supplied
- Scoped cache invalidation (pattern match → only affected loggers, not full wipe)

**HTML Encoder:** (see `logd_output_design/STATUS.md`)

---

## Next Steps

### Core (no active next steps — v0.8.7 is stabilization)
The engine is in a healthy state. Next work will likely be driven by:
1. Publishing `logd_linters` v0.1.0 (see `logd_linters/STATUS.md`)
2. Output pipeline design improvements (`LogSurface`, `lightScheme`, `WrappingStrategy` self-declaration)
3. Real-world usage driving future API decisions

### Open Questions

| Question | Status |
|---|---|
| Should `NativeEngine` streaming mode support decorators in future? | Unknown |
| Should `LoggerMetrics` be observable (stream) rather than polling? | Unknown |
| What does the v0.9.0 milestone look like? | Not yet defined |
| `LogOutput` facade — when is the right moment? | Deferred (needs user validation) |

---

## Known Traps

- Any decorator present → disables NativeEngine streaming mode → Object mode path. A "fix" to the engine check that excludes `AutoConsoleEncoder` wrappers will silently push to StandardEngine.
- `NativeEngine` fallback to `StandardEngine` is logged once via `InternalLogger`. If output looks wrong, check for this warning.
- Core resource managers (`Arena`, sinks) must use `print` not `InternalLogger`. Re-entrancy into the logging pipeline during active state clobbers native buffers → "No native data" error.
- `configureMultiple` validates ALL inputs before writing ANY state. Partial failure = zero mutation. Don't expect partial success.
- `LogBuffer.autoSinkBuffer` defaults to `false` — data is lost by default on leak. Intentional: enforces explicit lifecycle.
- `Logger.reset()` without an argument clears the **entire** registry. Very destructive in production. Always pass a name in long-lived apps.
- Web: `dart:ffi` and `dart:io` must never appear in the entry point. All native features use co-located stubs (`*_native.dart` / `*_stub.dart`).
