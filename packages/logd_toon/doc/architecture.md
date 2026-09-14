# TOON Architecture & Design Philosophy

## What is TOON?
TOON (Typed Object Oriented Notation) is a specialized serialization format designed for structured logging. While JSON is the industry standard for structured data interchange, it carries specific drawbacks when used as a terminal output format or as a high-throughput logging sink. TOON aims to solve these issues.

## Why Not JSON?

1. **Human Readability**: JSON is machine-first. Quotes around keys, curly braces, and strict trailing comma rules make it visually dense. When staring at terminal logs for hours, this syntactic noise causes fatigue. TOON drops unnecessary quotes and brackets in favor of a cleaner, YAML-like visual hierarchy, while remaining faster to parse than YAML.
2. **Type Preservation**: JSON lacks native support for complex types beyond basic primitives (strings, numbers, booleans, null). Dart's rich type system (e.g., `DateTime`, `Duration`, `Uri`, custom objects) requires manual stringification in JSON, which loses semantic meaning. TOON natively encodes these types.
3. **Escaping Overhead**: JSON requires strict escaping of control characters and quotes. In logging, where strings often contain raw terminal output, stack traces, or nested code snippets, escaping overhead is significant. TOON uses length-prefixed blocks or smart multi-line delimiters to avoid byte-by-byte escaping.

## Pipeline Integration
`logd_toon` operates as an `Encoder` in the `logd` pipeline. It takes the semantic IR (`LogDocument`) produced by the `Formatter` and `Decorator` layers and serializes it strictly into bytes (or a string) without concern for terminal width or ANSI colors.

## Zero-Allocation Strategy
The TOON encoder is built with a zero-allocation philosophy. Instead of building massive intermediate string representations, it streams characters directly to a reusable `StringBuffer` or sink, minimizing GC pressure during high-throughput logging bursts.
