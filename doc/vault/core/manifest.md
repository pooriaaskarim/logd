# The Logd Manifest: A Resilient Habitat

## The Vision: Strategic Elasticity
Logd is a **Resilient Habitat** for diagnostic data. We have evolved beyond the "Mechanical Squeeze" into a state of **Strategic Elasticity**. In this state, the architecture remains flexible and spacious by default, engaging mechanical optimizations only when the environment exerts significant pressure.

## Core Philosophy: The Dual Path
> "Organic by default (VM Native), Mechanical when under pressure (Arena/FFI)."

1.  **The Organic Path**: Most log cycles should reside in "String-land," leveraging the Dart VM's native Garbage Collector. This path maximizes **Creation Comfort**—the ability for developers and agents to iterate rapidly on features without the friction of manual memory management.
2.  **The Mechanical Reserve**: We maintain a dormant exoskeleton of optimizations (LIFO Pooling, Bitmasks, Off-Heap isolation). These are engaged only when performance metrics indicate we have crossed a "Pressure Threshold."
3.  **Predictable Silence**: Our primary metric remains **Zero GC jank**. However, we now acknowledge that the Dart VM's nursery is often the quietest path for low-to-medium throughput.

## The Pillars
- **Creation Comfort**: The architecture must prioritize developer velocity and idiomatic Dart until performance is proven to be the primary bottleneck.
- **Semantic Primacy**: The identity of a log exists in its semantic IR (`LogDocument`). Rendering and optimization are downstream concerns.
- **Lazy Physicality**: Physical layout and byte-slicing occur at the absolute edge.
- **Systemic Slack**: We retain the "slack" of high-level abstractions to ensure the codebase remains hospitable.
