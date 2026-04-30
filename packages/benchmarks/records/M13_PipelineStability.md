# Milestone Record: M13 - Pipeline Stability & Alignment
**Date:** 2026-04-30
**Goal:** Fix B-IR alignment regressions and implement engine fallback safety.

**Commit:** 606fcce perf(handler): optimize Binary IR standardization and achieve 74% speedup
**Branch:** feat/ffi-binary-ir
**Dart:** Dart SDK version: 3.10.4 (stable) (Tue Dec 9 00:01:55 2025 -0800) on "linux_x64"

## 1. Baseline Benchmarks

```text
Running Baseline Benchmarks...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 161.28144487586775 us.
StructuredFormatter(RunTime): 331.7408945686901 us.
ToonFormatter(RunTime): 229.26857411986342 us.
JsonFormatter(RunTime): 281.0174192683907 us.
JsonPrettyFormatter(RunTime): 579.7222222222222 us.
MarkdownEncoder(RunTime): 86.49001631947777 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 464.72433333333333 us.
PrefixDecorator(RunTime): 539.8514960197639 us.
StyleDecorator(RunTime): 10.206803172787309 us.
SuffixDecorator(RunTime): 575.5575 us.
HierarchyDepthPrefixDecorator(RunTime): 549.7078503688093 us.

--- Pipeline Throughput ---
FullPipeline(RunTime): 56.30764103887169 us.
ArenaFullPipeline(RunTime): 61.41369259522962 us.
ManualPipeline(RunTime): 738.639 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 13.363164821011074 us.
MultiSink (x2)(RunTime): 13.817735911320444 us.
MultiSink (x4)(RunTime): 14.40919654482073 us.

--- Stress Test & Profiling ---
### 1. The Raw Machine (JSON -> FileSink)
Profiling: Raw Machine ...
16059 Ops/sec | p90: 79.00µs | p95: 93.00µs | p99: 123.00µs | GC Pressure: 18372.80 KB/10k

### 2. The Modern Human (Structured -> Box -> ConsoleSink)
Profiling: Modern Human ...
7953 Ops/sec | p90: 150.00µs | p95: 187.00µs | p99: 232.00µs | GC Pressure: 36072.00 KB/10k

### 3. The Framing Squeeze (Prefix -> Box -> ConsoleSink @ 40 width)
Profiling: Framing Squeeze ...
2785 Ops/sec | p90: 410.00µs | p95: 535.00µs | p99: 824.00µs | GC Pressure: 42528.00 KB/10k


--- Structural Efficiency Report ---
Error: VM Service not enabled. Run with --observe or --enable-vm-service.
==============================
Benchmarks Complete.
```

## 2. Engine Comparison (Standard vs Native B-IR)

```text
The Dart VM service is listening on http://127.0.0.1:8181/qcT_Oappkno=/
The Dart DevTools debugger and profiler is available at: http://127.0.0.1:8181/qcT_Oappkno=/devtools/?uri=ws://127.0.0.1:8181/qcT_Oappkno=/ws
# Logd Engine Comparison Report Generator

Evaluating Scenario: 1. Raw Machine (JSON)

Evaluating Scenario: 2. Modern Human (Structured + Box)

Evaluating Scenario: 3. Framing Squeeze (Prefix + Box @ 40)

Evaluating Scenario: 4. Complex Native (TOON + Box + Nesting)


============================================================
FINAL COMPARISON SUMMARY
============================================================

Scenario: 1. Raw Machine (JSON)
Engine   | Throughput | p90 Latency | GC Pressure
-------------------------------------------------------
Standard |      17639 |       81.0µs |      24357 KB
Arena    |      28019 |       47.0µs |      32579 KB
Native   |     237158 |        5.0µs |      34192 KB

Scenario: 2. Modern Human (Structured + Box)
Engine   | Throughput | p90 Latency | GC Pressure
-------------------------------------------------------
Standard |       9755 |      147.0µs |      32189 KB
Arena    |      11837 |      103.0µs |      32892 KB
Native   |      63960 |       21.0µs |      26711 KB

Scenario: 3. Framing Squeeze (Prefix + Box @ 40)
Engine   | Throughput | p90 Latency | GC Pressure
-------------------------------------------------------
Standard |       5486 |      239.0µs |      49622 KB
Arena    |       5983 |      201.0µs |      36947 KB
Native   |      46807 |       27.0µs |      25661 KB

Scenario: 4. Complex Native (TOON + Box + Nesting)
Engine   | Throughput | p90 Latency | GC Pressure
-------------------------------------------------------
Standard |       5643 |      230.0µs |      32968 KB
Arena    |       6102 |      193.0µs |      21497 KB
Native   |      63739 |       23.0µs |      22229 KB
```
