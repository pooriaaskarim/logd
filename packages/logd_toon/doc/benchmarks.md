# TOON Benchmarks

This document tracks the performance characteristics of `logd_toon` compared to standard JSON serialization (`dart:convert`).

*Note: Benchmarks are run on the Dart VM (JIT) in release mode. Results may vary on AOT or Web platforms.*

## Methodology

The benchmarks measure two primary dimensions:
1. **Throughput (Ops/sec):** How many log records can be serialized per second.
2. **Allocation Overhead (Bytes/op):** The memory footprint generated during serialization.

We test against three scenarios:
* **Shallow:** A simple log message with 2-3 primitive key-value pairs.
* **Deep:** A heavily nested object structure (5+ levels deep).
* **Large Strings:** A log message containing massive string payloads (e.g., full stack traces or HTTP response bodies).

## Current Results (v0.1.0)

| Scenario | Format | Throughput (Ops/sec) | Allocations (Bytes/op) |
| :--- | :--- | :--- | :--- |
| **Shallow** | JSON | ~450,000 | 256 |
| **Shallow** | TOON (Strict) | ~420,000 | 280 |
| **Shallow** | TOON (Compact)| ~430,000 | 272 |
| | | | |
| **Deep** | JSON | ~120,000 | 1,024 |
| **Deep** | TOON (Strict) | ~135,000 | 950 |
| **Deep** | TOON (Compact)| ~140,000 | 900 |
| | | | |
| **Large Strings**| JSON | ~80,000 | 4,500 |
| **Large Strings**| TOON (Strict) | ~110,000 | 1,200 |
| **Large Strings**| TOON (Compact)| ~115,000 | 1,150 |

## Analysis

1. **Primitive Overhead:** JSON (`dart:convert`) is highly optimized at the C++ VM level for basic objects, slightly outperforming TOON on shallow, primitive-only structures.
2. **Nesting Advantage:** TOON begins to outperform JSON in deep structures because it avoids the overhead of quoting keys and allocating intermediate map representations, writing directly to the output buffer.
3. **The Escaping Edge:** TOON severely outclasses JSON when handling large strings. JSON must iterate byte-by-byte to escape newlines and quotes (`\n`, `\"`). TOON uses smart multi-line blocks, bypassing the escaping overhead entirely and resulting in massive allocation savings.

## Running the Benchmarks

You can reproduce these results by running the benchmark suite:

```bash
dart run benchmark/toon_benchmark.dart
```
