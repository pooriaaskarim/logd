# Milestone Record: M15 - FFI Layout Parity & Stabilization
**Date:** 2026-06-13
**Goal:** Achieve 100% visual layout parity for FFI Binary IR rendering while maintaining zero performance regressions.

**Commit:** 9ea5843 fix(handler): stabilize FFI layout engine for 100% parity with Standard Dart pipeline
**Branch:** fix/ffi-layout-parity
**Dart:** Dart SDK version: 3.12.0 (stable) (Fri May 8 01:51:14 2026 -0700) on "linux_x64"

## Overview
This milestone marks the full stabilization and verification of the **Binary Intermediate Representation (B-IR) physical layout engine**. Across a differential matrix of 2,048 test configurations (spanning varying widths, formatters, and decorators), the Native FFI engine now achieves exact line-for-line, character-for-character rendering parity with the Standard Dart-based engine. This was achieved by integrating a custom word-wrapping simulator, indentation-aware fitting, and nested decorated state tracking into `BinaryAnsiEncoder`.

## 1. Baseline Benchmarks

```text
Running Baseline Benchmarks...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 221.09405093087952 us.
StructuredFormatter(RunTime): 342.03496266123557 us.
ToonFormatter(RunTime): 316.9660826233725 us.
JsonFormatter(RunTime): 366.3242700729927 us.
JsonPrettyFormatter(RunTime): 875.307 us.
MarkdownEncoder(RunTime): 46.417288600590545 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 619.4847290640394 us.
PrefixDecorator(RunTime): 791.244 us.
StyleDecorator(RunTime): 9.647719704560592 us.
SuffixDecorator(RunTime): 1941.9842578710645 us.
HierarchyDepthPrefixDecorator(RunTime): 1636.9055064581917 us.

--- Pipeline Throughput ---
FullPipeline(RunTime): 3.5885657586403648 us.
ArenaFullPipeline(RunTime): 3.871059023913443 us.
ManualPipeline(RunTime): 788.21125 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 26.201128092103357 us.
MultiSink (x2)(RunTime): 26.05715779273766 us.
MultiSink (x4)(RunTime): 26.0017375 us.

--- Phase 1: Native Offload Scaling (10k iterations) ---
NativeEngineOffload (Phase 1): 57.03 us/op

--- Stress Test & Profiling ---
### 1. The Raw Machine (JSON -> FileSink)
13311 Ops/sec | p90: 97.00µs | p95: 121.00µs | p99: 219.00µs | GC Pressure: 0.00 KB/10k

### 2. The Modern Human (Structured -> Box -> ConsoleSink)
9848 Ops/sec | p90: 130.00µs | p95: 168.00µs | p99: 260.00µs | GC Pressure: 202.40 KB/10k

### 3. The Framing Squeeze (Prefix -> Box -> ConsoleSink @ 40 width)
3018 Ops/sec | p90: 431.00µs | p95: 532.00µs | p99: 689.00µs | GC Pressure: 0.00 KB/10k

==============================
Benchmarks Complete.
```

## 2. Key Observations
- **100% Visual Parity**: All 2,048 layout configurations run against both engines yield identical terminal outputs, verified via strict differential tests.
- **Zero Performance Regression**: The additional wrapping and margin tracking logic added to `BinaryAnsiEncoder` did not regress pipeline speeds, with Plain/Structured formatters showing a 5-8% runtime reduction compared to the M14 baseline.
- **High Throughput Ceiling**: The Modern Human logging profile handles **9,848 Ops/sec** (compared to 9,019 in M14 Phase 2), while the Raw Machine profile maintains a high ceiling of **13,311 Ops/sec**.
