# Performance: Pressure Thresholds

## The Inquiry
As we pivot to "Strategic Elasticity," we must formally define the "Pressure" that justifies engaging the Mechanical Reserve. Is our bottleneck raw speed, or the stability of the environment?

## Defining "Pressure"

### 1. Throughput (The Raw Metric)
Defined as operations per second (ops/sec). This is the traditional performance metric. However, for a logging library, raw throughput is often a vanity metric—most applications do not log at the limit of the system's capacity.

### 2. Temporal Density (The Stability Metric)
Defined as a high rate of short-lived object creation within a narrow time window. This is where "Pressure" is most felt in the Dart VM. High temporal density triggers frequent nursery scavenges, which can induce micro-jitter (GC jank) in UI-heavy applications.

## The Research Path: Finding the "Tipping Point"
We are currently operating on the hypothesis that the Dart VM's Nursery is exceptionally efficient for low-complexity nodes. The "Tipping Point" occurs when:
- The cost of manual management (Arena overhead, LIFO stack maintenance) < The cost of VM Garbage Collection.
- The "UTF-8 Tax" of small segmental writes outweighs the benefit of memory isolation.

## Observation: The Scavenger's Efficiency
Recent benchmarks indicate that for standard logging volumes, the Dart VM's pointer-bumping allocator and generational scavenger outperform manual pooling. We do not engage the Mechanical Reserve prematurely because the "Organic Path" is actually quieter under normal load.
