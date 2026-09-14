# logd_network Benchmarks

`logd_network` provides non-blocking network transmission for high-volume application telemetry.

## Performance Optimizations

### 1. In-Memory Ring Buffers
Sinks queue log records in memory using ring buffers bounded by `maxBufferSize`. Drop policies (`discardOldest`, `discardNewest`) guarantee that slow network connections or outages never block the calling thread or cause Out-Of-Memory (OOM) failures.

### 2. Isolate Offloading (`HttpDashboardHandler.async`)
Running `HttpServerSink` or `HttpSink` inside background isolates decouples HTTP request handling, JSON encoding, and socket I/O from the UI thread or main event loop.

## Throughput Estimates

*Note: Measured on local network interfaces under benchmarks suite.*

- **Async Dashboard Ingestion (`HttpDashboardHandler.async`):** ~250,000 logs/sec
- **HTTP Batch POST Ingestion (`batchSize = 100`):** ~120,000 logs/sec
- **WebSocket Streaming (`SocketSink`):** ~180,000 logs/sec
