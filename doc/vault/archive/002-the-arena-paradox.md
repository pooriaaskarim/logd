# ADR 002: The Arena Paradox

## Context
To achieve "Predictable Silence" (Zero GC jank), we introduced LIFO pooling (`Arena`) for `LogDocument` and `LogNode` objects. This was a response to the high allocation rate during intensive logging.

## The Paradox
Micro-benchmarks showed a **~3-7% regression** in raw throughput after introducing the Arena. 

## Investigation
The Dart VM's "nursery" (Scavenger) is exceptionally fast at handling short-lived objects. The manual management overhead of a LIFO pool (resetting fields, maintaining the stack, ensuring release) occasionally exceeds the cost of just letting the VM collect the garbage.

## Decision
We retain the **Arena-based LIFO pooling** despite the micro-benchmark regression.

## Rationale
Stability is not measured by the peak, but by the floor.
- Large-scale throughput is a "Mechanical" metric.
- **Jitter reduction** is a "Resilient" metric.
In real-world applications (e.g., UI-heavy Flutter apps), a minor loss in throughput is a small price to pay for the elimination of GC-induced frame drops during heavy logging bursts. The "Paradox" is that the slower system is the more stable one.

## Consequences
- **Positive**: Determinstic memory usage; elimination of nursery pressure during log bursts.
- **Negative**: Slightly more complex developer ergonomics (must ensure documents are released).
