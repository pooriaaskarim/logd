import 'dart:async';
import 'package:logd/logd.dart';

/// Comprehensive showcase for ambient structured context (`LogContext` / MDC) in logd.
///
/// Demonstrates:
/// 1. Synchronous ambient context propagation
/// 2. Asynchronous `await` & microtask context preservation across async boundaries
/// 3. Nested scope inheritance and shadowing
/// 4. Concurrent execution isolation (e.g. parallel requests)
/// 5. Call-site explicit context merging with ambient context
/// 6. Multi-format rendering (Structured and JSON)
void main() async {
  print('===============================================================');
  print('       logd Ambient Structured Context (MDC) Demo');
  print('===============================================================\n');

  // Configure logger with ConsoleHandler and StructuredFormatter
  Logger.configure(
    'demo.context',
    handlers: [
      ConsoleHandler(
        formatter: const StructuredFormatter(),
      ),
    ],
  );

  Logger.configure(
    'demo.json',
    handlers: [
      ConsoleHandler(
        formatter: const JsonPrettyFormatter(),
      ),
    ],
  );

  final logger = Logger.get('demo.context');
  final jsonLogger = Logger.get('demo.json');

  // ---------------------------------------------------------------------------
  // 1. Basic Synchronous Ambient Context
  // ---------------------------------------------------------------------------
  print('--- 1. Basic Synchronous Ambient Context ---');

  logger.info('Log emitted before entering any context scope (no context)');

  LogContext.run({'requestId': 'req-9812', 'userId': 'user-42'}, () {
    logger.info('Processing payment transaction');
    _handlePayment();
  });

  logger.info('Log emitted after exiting context scope (context cleared)');

  // ---------------------------------------------------------------------------
  // 2. Asynchronous Propagation across Awaits & Microtasks
  // ---------------------------------------------------------------------------
  print('\n--- 2. Asynchronous Propagation across Awaits & Microtasks ---');

  await LogContext.run(
      {'traceId': 'trace-abc-123', 'environment': 'production'}, () async {
    logger.info('Starting async background sync job');

    await Future<void>.delayed(const Duration(milliseconds: 50));
    logger.info('Step 1 complete: Database snapshot fetched');

    await Future<void>.delayed(const Duration(milliseconds: 50));
    logger.info('Step 2 complete: S3 replication finished');
  });

  // ---------------------------------------------------------------------------
  // 3. Nested Scope Inheritance & Shadowing
  // ---------------------------------------------------------------------------
  print('\n--- 3. Nested Scope Inheritance & Shadowing ---');

  LogContext.run({'tenantId': 'tenant-us-east', 'role': 'operator'}, () {
    logger.info('Outer scope: Base tenant configuration');

    // Inner scope inherits tenantId, overrides role, and introduces spanId
    LogContext.run({'role': 'admin', 'spanId': 'span-nested-01'}, () {
      logger.info('Inner scope: Elevated privileges and span attached');
    });

    logger.info('Back in outer scope: Original role restored, spanId gone');
  });

  // ---------------------------------------------------------------------------
  // 4. Concurrent Request Isolation
  // ---------------------------------------------------------------------------
  print('\n--- 4. Concurrent Request Isolation ---');

  // Two concurrent tasks run in parallel. Their ambient contexts never bleed into each other.
  await Future.wait([
    _simulateRequest(logger, requestId: 'req-alpha', customer: 'Acme Corp'),
    _simulateRequest(logger, requestId: 'req-beta', customer: 'Globex Inc'),
  ]);

  // ---------------------------------------------------------------------------
  // 5. Call-Site Context Merging
  // ---------------------------------------------------------------------------
  print('\n--- 5. Call-Site Explicit Overrides ---');

  LogContext.run({'service': 'orders', 'version': '1.2.0'}, () {
    logger.info(
      'Order validated with call-site override and extra metadata',
      context: {
        'version':
            '1.3.0-rc1', // Overrides ambient version for this single entry
        'orderId': 'ord-998877', // Appends new key
      },
    );

    logger.info('Subsequent log retains ambient version 1.2.0');
  });

  // ---------------------------------------------------------------------------
  // 6. JSON Formatted Output with Ambient Context
  // ---------------------------------------------------------------------------
  print('\n--- 6. JSON Formatted Ambient Context ---');

  LogContext.run({'traceId': 'trace-json-99', 'service': 'billing'}, () {
    jsonLogger.info(
      'Invoice generated and dispatched',
      context: {
        'invoiceNumber': 'INV-2026-0042',
        'amount': 499.95,
        'currency': 'USD',
      },
    );
  });

  print('\n===============================================================');
  print('                  LogContext Demo Complete');
  print('===============================================================');
}

void _handlePayment() {
  // Deep in the call stack, no logger or context parameters need to be threaded!
  final logger = Logger.get('demo.context.payment');
  logger.info('Gateway connection established (inherited ambient context)');
}

Future<void> _simulateRequest(
  Logger logger, {
  required String requestId,
  required String customer,
}) async {
  await LogContext.run({'requestId': requestId, 'customer': customer},
      () async {
    logger.info('Received incoming HTTP POST /checkout');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    logger.info('Payment authorization succeeded');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    logger.info('Order completed successfully');
  });
}
