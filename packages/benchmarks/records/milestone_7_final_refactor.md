# Benchmark Report
**Commit:** 116dab5 Merge remote-tracking branch 'origin/feat/lifo_object_pooling' into feat/lifo_object_pooling
**Branch:** feat/lifo_object_pooling
**Dart:** Dart SDK version: 3.10.4 (stable) (Tue Dec 9 00:01:55 2025 -0800) on "linux_x64"

```text
Running Baseline Benchmarks...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 145.0460403784549 us.
StructuredFormatter(RunTime): 421.1403582718651 us.
ToonFormatter(RunTime): 306.15058997050147 us.
JsonFormatter(RunTime): 263.7604677480196 us.
JsonPrettyFormatter(RunTime): 612.42425 us.
MarkdownFormatter(RunTime): 225.7745764665207 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 583.889 us.
PrefixDecorator(RunTime): 591.88525 us.
StyleDecorator(RunTime): 418.6761666666667 us.
SuffixDecorator(RunTime): 589.16825 us.
HierarchyDepthPrefixDecorator(RunTime): 594.2445 us.

--- E2E Pipeline Overhead ---
Simple Pipeline (Plain)(RunTime): 10.51982 us.
Complex Pipeline (Structure+Box+Style)(RunTime): 59.50916961595835 us.
JsonPretty Pipeline(RunTime): 125.27768678341943 us.
Markdown Pipeline(RunTime): 6.84482584914184 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 11.916162167675665 us.
MultiSink (x2)(RunTime): 12.24735550528899 us.
MultiSink (x4)(RunTime): 12.4748750502499 us.

--- Stress Test & Profiling ---
### 1. The Raw Machine (JSON -> FileSink)
Profiling: Raw Machine ...
28017 Ops/sec | p90: 39.00µs | p95: 46.00µs | p99: 68.00µs | GC Pressure: 218.40 KB/10k

### 2. The Modern Human (Structured -> Box -> ConsoleSink)
Profiling: Modern Human ...
10005 Ops/sec | p90: 127.00µs | p95: 174.00µs | p99: 218.00µs | GC Pressure: 187.20 KB/10k

### 3. The Framing Squeeze (Prefix -> Box -> ConsoleSink @ 40 width)
Profiling: Framing Squeeze ...
4817 Ops/sec | p90: 247.00µs | p95: 318.00µs | p99: 439.00µs | GC Pressure: 0.00 KB/10k


--- Structural Efficiency Report ---
Error: VM Service not enabled. Run with --observe or --enable-vm-service.
==============================
Benchmarks Complete.
```
