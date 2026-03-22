# ADR 004: Newline Consistency in Byte-Oriented Sinks

## Context
With the transition to a byte-oriented architecture using `HandlerContext` and direct `stdout.add` transport (see [Strategic Simplification](003-strategic-simplification.md)), we removed the reliance on Dart's `print()` function. 

Existing encoders often used "interleaved" newline logic—adding newlines *between* lines but omitting the final terminator. While `print()` automatically added this terminator, `stdout.add` sends the raw byte stream as-is, leading to "log scattering" where outputs from different entries (or the shell prompt) appear on the same line.

## Decision
We have decided to enforce **trailing newlines at the Encoder level**. 

Every call to `LogEncoder.encode` must result in a byte stream that is properly terminated by a newline (`0x0A`).

## Rationale
- **Single Point of Truth**: Encoders are responsible for the physical layout. Placing the responsibility here ensures that whether the output is ANSI, TOON, or JSON, it occupies its intended space.
- **Simplification**: Removing "join" logic (skipping the last element) simplifies the encoder loops into consistently line-oriented operations.
- **Resilience**: Sinks can remain thin and transport-agnostic, simply pumping bytes from the `HandlerContext` without needing to audit the content for completeness.

## Consequences
- **Positive**: Consistent terminal and file output; simpler loop implementations in encoders.
- **Negative**: Redundant newlines if a sink tries to be "smart" (though this is unlikely given our current thin-sink philosophy).

---
*Status: Accepted*
*Date: 2026-02-25*
