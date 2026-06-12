# Milestone Record: M12 - FFI Binary IR Groundwork (B-IR v1)

## Date: 2026-04-28
## Goal: Zero-Copy FFI Readiness & High-Speed Standardization

### Overview
This milestone introduces the **Binary Intermediate Representation (B-IR) v1**, a language-agnostic instruction stream designed for FFI compatibility. By linearizing the `LogDocument` tree into a contiguous byte-buffer, we achieve a massive reduction in Dart object overhead and prepare for native rendering in C/Rust.

### Benchmark Results
Run via `packages/benchmarks/lib/engine_comparison.dart`.

| Scenario | Engine | Throughput | p90 Latency | GC Pressure |
| :--- | :--- | :--- | :--- | :--- |
| **2. Modern Human (Structured + Box)** | Standard | 10,286 | 120µs | 45.1 MB |
| | **Native (B-IR)** | **211,797** | **5µs** | **30.5 MB** |
| **4. Complex (TOON + Box + Nesting)** | Standard | 5,995 | 194µs | 49.2 MB |
| | **Native (B-IR)** | **98,385** | **12µs** | **21.9 MB** |

### Key Observations
- **16x Latency Reduction**: p90 latency dropped from 194µs to 12µs in complex scenarios.
- **20x Throughput Increase**: The stream-based `BinaryAnsiEncoder` bypasses the expensive `TerminalLayout` object graph.
- **GC Stability**: GC pressure dropped by ~55% in complex nested scenarios due to the use of a native-backed `Arena` for the IR buffer.

### Architectural Impact
The `NativeEngine` now provides a "Fast-Path" in Dart that serves as a reference for the C-library port. This confirms that the B-IR protocol is sufficient for all current `logd` features, including recursive boxes and indentations.

---
*Verified by Antigravity*
