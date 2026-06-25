# Time Module

The Time module manages timestamp generation and timezone handling for log entries. It ensures consistent and configurable temporal data across the application.

## Capabilities

- **High-Precision Timestamps**: Efficient generation of timestamps with sub-millisecond precision.
- **Timezone Support**: Standard IANA database integration for accurate global time.
- **High-Throughput Caching**: Truncated 1-minute timezone offset caching achieves massive performance gains.
- **Formatting**: Customizable date/time patterns (e.g., ISO-8601), including fast-path Date-Only formatting.

## Integration
The global timestamp configuration serves as the default for all loggers but can be overridden on a per-logger basis to support different requirements (e.g., UTC for server logs, Local for UI logs).
