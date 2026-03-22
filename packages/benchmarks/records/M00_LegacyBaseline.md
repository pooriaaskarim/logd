# Benchmark Report: Milestone 0 (Legacy Baseline)
**Goal:** Establish performance baseline for legacy `logd`.
**Status:** Completed

## Results Summary
| Scenario | Plain (µs) | Structured (µs) | Json (µs) |
| :--- | :--- | :--- | :--- |
| **Legacy Baseline** | 276.5 | 467.3 | 26.3 |

## Analysis
- **Legacy Performance**: Performance was hampered by heavy string concatenation and a lack of structured IR.
- **JSON Anomaly**: The low JSON timing is deceptive, as the legacy system used a flat `Map` with `jsonEncode`, bypassing all layout and semantic logic.

## Raw Output
```text
Running Baseline Benchmarks (Legacy System)...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 276.5 us.
StructuredFormatter(RunTime): 467.3 us.
ToonFormatter(RunTime): 319.6 us.
JsonFormatter(RunTime): 26.3 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 157.0 us.
PrefixDecorator(RunTime): 1.9 us.
StyleDecorator(RunTime): 13.0 us.

--- E2E Pipeline Overhead ---
Simple Pipeline (Plain)(RunTime): 930.2 us.
Complex Pipeline (Structure+Box+Style+Prefix)(RunTime): 1738.7 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 460.5 us.
MultiSink (x2)(RunTime): 484.1 us.
MultiSink (x4)(RunTime): 508.1 us.
==============================
Benchmarks Complete.
```
