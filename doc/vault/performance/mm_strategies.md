# Performance: Memory Management Strategies

In our state of "Strategic Elasticity," we maintain multiple strategies for managing memory pressure. These reside in our "Mechanical Reserve," ready to be engaged as the environment demands.

## Strategy A: Off-Heap Autonomy (FFI/Binary IR)
*Status: Production Ready (Default)*

### Summary
The `NativeEngine` targets native platforms via `dart:ffi`. By linearizing the `LogDocument` into a language-agnostic **Binary IR (B-IR)** instruction stream, it achieves absolute memory determinism and zero-copy readiness.

### Performance Profile
- **Zero-Churn Streaming**: In "Streaming Mode" (no decorators), it bypasses the Dart object heap entirely, writing directly to contiguous native buffers.
- **Extreme Throughput**: Achieves ~230k+ ops/sec, representing a 10x-13x improvement over standard heap allocation.
- **Reference**: [M13: Pipeline Stability & Alignment](../../packages/benchmarks/records/M13_PipelineStability.md)

## Strategy B: LIFO Pooling (`ArenaEngine`)
*Status: Production Ready (Hybrid)*

### Summary
The `ArenaEngine` utilizes an isolate-local `Arena` for deterministic object reuse. It is used when the **Object Pipeline** is required (e.g., when complex `LogDecorators` are present). By recycling the entire object graph, it neutralizes the pressure on the Dart generational scavenger.

### Performance Profile
- **Predictable GC**: Maintains low GC pressure even with high-frequency logging by preventing object leakage into the old generation.
- **Throughput Optimization**: Best-in-class performance for decorated logs.

## Strategy C: Heap Allocation (`StandardEngine`)
*Status: Active (Fallback)*

### Summary
The `StandardEngine` relies on the Dart VM's native garbage collector. It is used as a safety fallback when the platform or the `LogSink` does not support binary streaming or explicit pooling.
