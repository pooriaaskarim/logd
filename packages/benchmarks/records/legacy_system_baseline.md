# Benchmark Report
**Commit:** 878b1f9 Oh my god! Fixing Readme again!
**Branch:** chore/legacy-benchmarks
**Dart:** Dart SDK version: 3.10.4 (stable) (Tue Dec 9 00:01:55 2025 -0800) on "linux_x64"

```text
Running Baseline Benchmarks...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 295.28918355184743 us.
StructuredFormatter(RunTime): 560.498 us.
ToonFormatter(RunTime): 346.18487839266834 us.
JsonFormatter(RunTime): 24.01646163065318 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 180.13545521835678 us.
PrefixDecorator(RunTime): 1.607285190286413 us.
StyleDecorator(RunTime): 12.70677361274513 us.

--- E2E Pipeline Overhead ---
Simple Pipeline (Plain)(RunTime): 554.8115 us.
Complex Pipeline (Structure+Box+Style)(RunTime): 1147.78 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 538.6245 us.
MultiSink (x2)(RunTime): 581.3704579025111 us.
MultiSink (x4)(RunTime): 591.90975 us.
==============================
Benchmarks Complete.
```
