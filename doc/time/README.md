# Time Module

The Time module manages timestamp generation and timezone handling for log entries. It ensures consistent and configurable temporal data across the application.

## Capabilities

- **High-Precision Timestamps**: Efficient generation of timestamps for high-volume logging.
- **Timezone Support**: utilities for handling UTC and Local time conversions.
- **Formatting**: Customizable date/time patterns (e.g., ISO-8601).

## Integration
The global timestamp configuration serves as the default for all loggers but can be overridden on a per-logger basis to support different requirements (e.g., UTC for server logs, Local for UI logs).
