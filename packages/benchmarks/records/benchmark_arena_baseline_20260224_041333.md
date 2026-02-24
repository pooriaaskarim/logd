# Benchmark Report
**Commit:** 503f895 chore: Changelog update for 0.6.5 - work in progress!
**Branch:** feat/arena_refinement
**Dart:** Dart SDK version: 3.10.4 (stable) (Tue Dec 9 00:01:55 2025 -0800) on "linux_x64"

```text
Running Baseline Benchmarks...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 145.19169329073483 us.
StructuredFormatter(RunTime): 448.23257287705957 us.
ToonFormatter(RunTime): 283.2175986129172 us.
JsonFormatter(RunTime): 243.07961904761905 us.
JsonPrettyFormatter(RunTime): 578.96575 us.
MarkdownFormatter(RunTime): 225.15629386991108 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 634.6424564511367 us.
PrefixDecorator(RunTime): 585.543 us.
StyleDecorator(RunTime): 436.03342442715996 us.
SuffixDecorator(RunTime): 614.0505 us.
HierarchyDepthPrefixDecorator(RunTime): 594.1015 us.

--- E2E Pipeline Overhead ---
Simple Pipeline (Plain)(RunTime): 10.32484 us.
Complex Pipeline (Structure+Box+Style)(RunTime): 57.00037049703602 us.
JsonPretty Pipeline(RunTime): 111.55958114010528 us.
Markdown Pipeline(RunTime): 5.623421159012972 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 8.480392 us.
MultiSink (x2)(RunTime): 8.419294475881905 us.
MultiSink (x4)(RunTime): 8.6071399732251 us.
==============================
Benchmarks Complete.
```
