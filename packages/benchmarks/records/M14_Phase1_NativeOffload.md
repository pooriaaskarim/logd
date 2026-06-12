# Benchmark Report: Phase 1 (Native Offload)
**Commit:** ad25422 docs: update handler roadmap and architecture for v0.8.0
**Branch:** feat/ffi-binary-ir
**Dart:** Dart SDK version: 3.10.4 (stable) (Tue Dec 9 00:01:55 2025 -0800) on "linux_x64"

```text
Running Baseline Benchmarks...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 152.7393220854233 us.
StructuredFormatter(RunTime): 327.34537208130354 us.
ToonFormatter(RunTime): 249.7007883011539 us.
JsonFormatter(RunTime): 268.18155119476705 us.
JsonPrettyFormatter(RunTime): 581.5184743742551 us.
MarkdownEncoder(RunTime): 82.93554274034601 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 503.7625 us.
PrefixDecorator(RunTime): 650.57875 us.
StyleDecorator(RunTime): 12.155709088236375 us.
SuffixDecorator(RunTime): 644.23975 us.
HierarchyDepthPrefixDecorator(RunTime): 569.02225 us.

--- Pipeline Throughput ---
FullPipeline(RunTime): 57.60119558027293 us.
ArenaFullPipeline(RunTime): 70.17473894942785 us.
ManualPipeline(RunTime): 551.3991958644457 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 13.33586615273616 us.
MultiSink (x2)(RunTime): 13.629827035951303 us.
MultiSink (x4)(RunTime): 13.845372350452072 us.

--- Phase 1: Native Offload Scaling (10k iterations) ---
[logd-internal] [WARNING]: Arena saturation reached (200 packets). Blocking main thread.
NativeEngineOffload (Phase 1): 42.56 us/op

--- Stress Test & Profiling ---
### 1. The Raw Machine (JSON -> FileSink)
Profiling: Raw Machine ...
15821 Ops/sec | p90: 83.00µs | p95: 94.00µs | p99: 118.00µs | GC Pressure: 18661.60 KB/10k

### 2. The Modern Human (Structured -> Box -> ConsoleSink)
Profiling: Modern Human ...
7524 Ops/sec | p90: 153.00µs | p95: 187.00µs | p99: 232.00µs | GC Pressure: 0.00 KB/10k

### 3. The Framing Squeeze (Prefix -> Box -> ConsoleSink @ 40 width)
Profiling: Framing Squeeze ...
2830 Ops/sec | p90: 427.00µs | p95: 548.00µs | p99: 798.00µs | GC Pressure: 41980.80 KB/10k


--- Structural Efficiency Report ---
Error: VM Service not enabled. Run with --observe or --enable-vm-service.
==============================
Benchmarks Complete.
