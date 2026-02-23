# Benchmark Report: Pre-Bitmask Refactoring

**Date:** 2026-02-23
**Description:** Baseline performance right before refactoring `LogTag` from `Set<LogTag>` into integer bitmasks.

## Results

```
Running Baseline Benchmarks...
==============================

--- Formatter Throughput ---
PlainFormatter(RunTime): 147.45385291532375 us.
StructuredFormatter(RunTime): 478.7181818181818 us.
ToonFormatter(RunTime): 294.8256622761581 us.
JsonFormatter(RunTime): 268.10475007168117 us.

--- Decorator Overhead ---
BoxDecorator(RunTime): 542.7585106382978 us.
PrefixDecorator(RunTime): 555.848 us.
StyleDecorator(RunTime): 342.5595517802277 us.

--- E2E Pipeline Overhead ---
Simple Pipeline (Plain)(RunTime): 11.87089375 us.
Complex Pipeline (Structure+Box+Style)(RunTime): 74.32371941024472 us.

--- Multi-Sink Scaling ---
MultiSink (x1)(RunTime): 6.9986607523436835 us.
MultiSink (x2)(RunTime): 6.351941296117408 us.
MultiSink (x4)(RunTime): 6.2635650387611825 us.
==============================
Benchmarks Complete.
```
