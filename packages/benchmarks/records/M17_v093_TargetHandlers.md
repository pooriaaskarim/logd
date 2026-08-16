# Benchmark Report
**Commit:** 6a972dc docs(roadmap): mark v0.9.3 completed
**Branch:** dev
**Dart:** Dart SDK version: 3.12.2 (stable) (Tue Jun 9 01:11:39 2026 -0700) on "linux_x64"

```text
Running Baseline Benchmarks...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 234.98400548383412 us.
StructuredFormatter(RunTime): 380.86828052687787 us.
ToonFormatter(RunTime): 341.69293563579276 us.
JsonFormatter(RunTime): 408.7118301314459 us.
JsonPrettyFormatter(RunTime): 925.6621689155422 us.
MarkdownEncoder(RunTime): 52.98265428620428 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 725.7125 us.
PrefixDecorator(RunTime): 955.11125 us.
StyleDecorator(RunTime): 9.873324975031343 us.
SuffixDecorator(RunTime): 871.1845 us.
HierarchyDepthPrefixDecorator(RunTime): 770.88725 us.

--- Pipeline Throughput ---
FullPipeline(RunTime): 3.2083108083178664 us.
ArenaFullPipeline(RunTime): 6.593906604420531 us.
ManualPipeline(RunTime): 1071.981 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 42.25688 us.
MultiSink (x2)(RunTime): 40.84661906761865 us.
MultiSink (x4)(RunTime): 31.113203320780077 us.

--- Cache Invalidation Performance ---
Descendant Invalidation (10,000 Unrelated, 1 Descendant)(RunTime): 49.58678076438471 us.

--- Timezone Cache Performance ---
TimezoneOffsetLocal(RunTime): 1.4193413333333333 us.
TimezoneOffsetNamed(RunTime): 1.4529695 us.
TimestampFormatting(RunTime): 14.892822089478507 us.

--- AsyncHandler vs StandardEngine Performance ---
StandardEngine (Sync JSON)(RunTime): 1788.420208500401 us.
AsyncHandler (Isolate-offloaded JSON)(RunTime): 9.580129967627636 us.

--- Phase 1: Native Offload Scaling (10k iterations) ---
[logd-internal] [WARNING]: Arena saturation reached (200 packets). Blocking main thread.
[logd-internal] [WARNING]: Blocked main thread for 20ms waiting for pool capacity.

--- Phase 1: Native Offload Scaling (10k iterations) ---
  Progress: 0/10000
[logd-internal] [WARNING]: Blocked main thread for 29ms waiting for pool capacity.
  Progress: 1000/10000
  Progress: 2000/10000
  Progress: 3000/10000
  Progress: 4000/10000
  Progress: 5000/10000
  Progress: 6000/10000
  Progress: 7000/10000
[logd-internal] [WARNING]: Blocked main thread for 18ms waiting for pool capacity.
  Progress: 8000/10000
  Progress: 9000/10000
NativeEngineOffload (Phase 1): 91.71 us/op

--- Stress Test & Profiling ---
### 1. The Raw Machine (JSON -> FileSink)
Profiling: Raw Machine ...
7480 Ops/sec | p90: 137.00µs | p95: 153.00µs | p99: 196.00µs | GC Pressure: 268.80 KB/10k

### 2. The Modern Human (Structured -> Box -> ConsoleSink)
Profiling: Modern Human ...
5385 Ops/sec | p90: 196.00µs | p95: 215.00µs | p99: 300.00µs | GC Pressure: 309.60 KB/10k

### 3. The Framing Squeeze (Prefix -> Box -> ConsoleSink @ 40 width)
Profiling: Framing Squeeze ...
2067 Ops/sec | p90: 647.00µs | p95: 776.00µs | p99: 1497.00µs | GC Pressure: 290.40 KB/10k


--- Structural Efficiency Report ---
Error: VM Service not enabled. Run with --observe or --enable-vm-service.
==============================
Benchmarks Complete.
```
