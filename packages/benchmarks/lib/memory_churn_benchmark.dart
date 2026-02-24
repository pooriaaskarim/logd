// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports
import 'dart:async';
import 'dart:developer';
import 'package:logd/logd.dart';
import 'package:logd/src/logger/logger.dart';
import 'package:vm_service/vm_service_io.dart';

Future<void> runMemoryChurnBenchmark() async {
  print('\n--- Structural Efficiency Report ---');

  final info = await Service.getInfo();
  final uri = info.serverUri;

  if (uri == null) {
    print(
        'Error: VM Service not enabled. Run with --observe or --enable-vm-service.');
    return;
  }

  final String wsUri = 'ws://${uri.host}:${uri.port}${uri.path}ws';
  final vmService = await vmServiceConnectUri(wsUri);

  try {
    final vm = await vmService.getVM();
    final isolateId = vm.isolates!.first.id!;

    final handler = const Handler(
      formatter: StructuredFormatter(),
      sink: ConsoleSink(enabled: false),
    );

    // 1. Heavy Warmup
    print('Warming up LogArena (2,000 entries)...');
    for (int i = 0; i < 2000; i++) {
      await handler.log(LogEntry(
        loggerName: 'bench.warmup.depth',
        origin: 'memory_churn_benchmark.dart:warmup',
        level: LogLevel.info,
        message:
            'Warmup entry $i with some length to ensure buffers are sized.',
        timestamp: '2026-02-24T00:00:00.000Z',
      ));
    }

    // Stabilize
    await Future.delayed(const Duration(milliseconds: 500));

    // 2. Reset accumulators
    print('Resetting VM Service allocation accumulators...');
    await vmService.getAllocationProfile(isolateId, reset: true);

    // 3. Execution: 10,000 entries
    print('Logging 10,000 entries (Arena Active)...');
    final entry = const LogEntry(
      loggerName: 'bench.test.depth',
      origin: 'memory_churn_benchmark.dart:test',
      level: LogLevel.info,
      message: 'This is a test message for structural efficiency.',
      timestamp: '2026-02-24T00:00:00.000Z',
    );

    for (int i = 0; i < 10000; i++) {
      await handler.log(entry);
    }

    // 4. Capture Profile
    final profile = await vmService.getAllocationProfile(isolateId);

    print('\nClass Allocations during 10,000 logs:');
    print('-------------------------------------');

    final arenaClasses = [
      'LogDocument',
      'HeaderNode',
      'MessageNode',
      'ErrorNode',
      'FooterNode',
      'MetadataNode',
      'BoxNode',
      'IndentationNode',
      'GroupNode',
      'DecoratedNode',
      'ParagraphNode',
      'RowNode',
      'FillerNode',
      'MapNode',
      'ListNode',
    ];

    final otherClasses = [
      'StyledText',
    ];

    bool allGarbageFree = true;
    int totalArenaAllocations = 0;

    for (final classStat in profile.members!) {
      final className = classStat.classRef!.name!;
      if (arenaClasses.contains(className) ||
          otherClasses.contains(className)) {
        final count = classStat.instancesAccumulated ?? 0;
        final size = classStat.accumulatedSize ?? 0;

        if (count == 0 && size == 0) continue;

        print(
            '${className.padRight(15)}: ${count.toString().padLeft(6)} objects | ${size.toString().padLeft(8)} bytes');

        if (arenaClasses.contains(className)) {
          totalArenaAllocations += size;
          if (size > 0) {
            allGarbageFree = false;
          }
        }
      }
    }

    print('-------------------------------------');
    if (allGarbageFree) {
      print('✅ VERIFIED: LogDocument & LogNodes are 100% Garbage-Free.');
    } else {
      print(
          '⚠️ WARNING: Identified leak of $totalArenaAllocations bytes ($totalArenaAllocations total bytes) in Arena-managed classes.');
      print(
          'This might be due to cold-start pool expansion or VM-internal allocations.');
    }

    print(
        'Bytes Allocated per log event (Structural): ${(totalArenaAllocations / 10000).toStringAsFixed(4)} bytes/log');
  } finally {
    await vmService.dispose();
  }
}

void main() async {
  await runMemoryChurnBenchmark();
}
