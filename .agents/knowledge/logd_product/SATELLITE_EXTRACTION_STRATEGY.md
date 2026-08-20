# Satellite Extraction Strategy: Zero-Dependency Core Vision
> Recorded: 2026-08-20 | Reflects v0.9.5 release & zero-dependency core roadmap

---

## 1. Architectural Vision: The Zero-Dependency Core Engine

The long-term vision for `logd` is to achieve a **zero-external-dependency, hyper-optimized core logging engine** (`packages/logd`) that runs natively across pure Dart VM, Flutter (iOS/Android/macOS/Windows/Linux), and Web (JS/WASM) without dependency friction.

Heavy, platform-bound, or domain-specific capabilities are extracted into dedicated first-party satellite packages.

```
                           ┌───────────────────────────┐
                           │   packages/logd (CORE)    │
                           │ - Zero external deps      │
                           │ - Pure Dart & Web native  │
                           │ - Semantic IR & Hierarchy │
                           └─────────────┬─────────────┘
                                         │
      ┌──────────────┬──────────────┬────┴─────────┬──────────────┬──────────────┐
      ▼              ▼              ▼              ▼              ▼              ▼
 ┌──────────┐  ┌──────────┐  ┌────────────┐  ┌───────────┐  ┌──────────────┐ ┌──────────┐
 │  logd_   │  │  logd_   │  │   logd_    │  │   logd_   │  │    logd_     │ │  logd_   │
 │ network  │  │  sqlite  │  │   native   │  │   time    │  │ deobfuscate  │ │ flutter  │
 └──────────┘  └──────────┘  └────────────┘  └───────────┘  └──────────────┘ └──────────┘
```

---

## 2. Satellite Candidates & Rationale Inventory

### A. [`logd_network`](https://pub.dev/packages/logd_network) — ✅ Extracted in v0.9.5
- **Extracted Components**: `HttpSink`, `SocketSink`, `HttpServerSink`, `HttpDashboardHandler`, `NetworkSink`, `DropPolicy`.
- **Dependencies Removed from Core**: `package:http`, `package:web_socket_channel`.
- **Rationale**: Prevents web server/socket dependency pollution in CLI/mobile applications that do not use network shipping. Soft deprecated in core targeting hard removal in `v0.10.0`.

### B. [`logd_sqlite`](https://pub.dev/packages/logd_sqlite) — ✅ Extracted in v0.9.0
- **Extracted Components**: `SqliteSink`, `SqliteHandler`, `queryLogs`, retention auto-pruning engine.
- **Dependencies Removed from Core**: `package:sqlite3`.
- **Rationale**: Database persistence requires native library bindings (`sqlite3_flutter_libs` / system `libsqlite3`).

### C. `logd_time` (IANA Timezone Engine) — 🔲 Planned for v0.10.x
- **Candidate Components**: `TimestampFormatter` IANA timezone parsing (`America/New_York`, `Asia/Tehran`).
- **Dependencies to Remove from Core**: `package:timezone`.
- **Rationale**: `package:timezone` bundles a ~300KB timezone binary database. 95%+ of logging use cases only require local device time or UTC (`DateTime.now()`, `.toUtc()`). Extracting custom IANA timezone support keeps core ultra-light.

### D. `logd_native` (C/FFI Arena Memory Pool & Binary ANSI Engine) — 🔲 Planned for v0.10.x
- **Candidate Components**: `NativeEngine`, `ArenaEngine`, `BinaryAnsiEncoder`, `calloc`/`malloc` FFI pointers.
- **Dependencies to Remove from Core**: `package:ffi`.
- **Rationale**: FFI cannot compile on Web (JS/WASM) platforms. Moving FFI components to `logd_native` makes `packages/logd` **100% pure Dart & Web-native out of the box** without platform stubs.

### E. `logd_deobfuscate` (Web & Mobile Source-Map Resolver) — 🔲 Planned for v0.10.x
- **Candidate Components**: Web source-map stack trace resolver in `StackTraceParser`.
- **Dependencies to Remove from Core**: `package:source_maps`, `package:source_span`.
- **Rationale**: Unobfuscated builds and standard server apps do not use source map parsing at runtime.

### F. `logd_flutter` / `logd_devtools` — 🔲 Planned Future
- **Candidate Components**: Flutter UI overlay widgets, in-app error log toasts, `FlutterError.onError` auto-binding, and official Dart DevTools panel extension.

### G. `logd_ai` (LLM & Telemetry Chunking) — 🔲 Planned Future
- **Candidate Components**: DuckDB ingestion scripts, OpenAI/Claude prompt token chunkers, vector embedding exporters based on `ToonFormatter`.

---

## 3. Two-Phase Deprecation Lifecycle Rule

To preserve SemVer guarantees while extracting satellite packages:

1. **Phase 1 (Minor Release, e.g., v0.9.5)**:
   - Extract the satellite package to `packages/<satellite>`.
   - Mark core classes with `@Deprecated('Use ... from package:<satellite> instead. Will be removed in v0.10.0')`.
   - Update core examples to decouple from extracted components.
2. **Phase 2 (Milestone Release, e.g., v0.10.0)**:
   - Permanently delete deprecated source files from core.
   - Remove third-party dependencies from core `pubspec.yaml`.
