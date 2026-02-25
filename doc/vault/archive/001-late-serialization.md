# ADR 001: Late-Bound Serialization

## Context
The boundary between a `Formatter` and an `Encoder` (or `Sink`) was previously blurred. There was a temptation to perform string generation or byte-encoding early in the pipeline to "save time."

## The Debate
- **Option A (Early Serialization)**: Formatters produce final bytes. This is efficient for a single output but rigid.
- **Option B (Semantic IR)**: Formatters produce a `LogDocument`. Serialization is deferred to the edge.

## Decision
We choose **Option B**. Intent belongs at the heart; physicality belongs at the edge.

## Rationale
By preserving the semantic structure until the final `Sink` or `Encoder`, we allow for:
1.  **Multi-Sinking**: A single `LogDocument` can be rendered as ANSI-colored text for the terminal and dense JSON for a network sink simultaneously without re-running formatting logic.
2.  **Adaptive Wrap**: Terminal width calculations can happen at the last possible moment, ensuring the "Physical Layout" is always accurate to the environment.

## Consequences
- **Positive**: High architectural flexibility; clean separation of concerns.
- **Negative**: Slight overhead in maintaining the intermediate `LogDocument` object graph (mitigated by the Arena).
