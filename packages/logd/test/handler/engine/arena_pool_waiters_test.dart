import 'package:logd/src/handler/document/binary_ir_native.dart';
import 'package:logd/src/handler/engine/arena_native.dart';
import 'package:test/test.dart';

void main() {
  group('Arena concurrent waiters', () {
    setUp(() {
      Arena.instance.clear();
    });

    test('multiple concurrent waiters for pool capacity are all resolved',
        () async {
      final arena = Arena.instance;

      // Saturate pool manually by creating in-flight packets
      final packets = <NativePacket>[];
      for (var i = 0; i < Arena.maxInFlightPackets; i++) {
        final doc = (arena.checkoutDocument() as ArenaDocument)
          ..enableStreaming()
          ..text('log $i');
        packets.add(arena.checkoutNativePacket(doc, terminalWidth: 80));
      }

      expect(arena.inFlightCount, Arena.maxInFlightPackets);

      // Verify that calling waitForPoolCapacity blocks
      var waiter1Completed = false;
      var waiter2Completed = false;

      final f1 = arena.waitForPoolCapacity().then((final _) {
        waiter1Completed = true;
      });
      final f2 = arena.waitForPoolCapacity().then((final _) {
        waiter2Completed = true;
      });

      // Give event loop a chance to run
      await Future.delayed(Duration.zero);
      expect(waiter1Completed, isFalse);
      expect(waiter2Completed, isFalse);

      // Now release one packet
      final firstPacket = packets.removeAt(0);
      firstPacket.completionPort.send(firstPacket.address);

      // Wait for completion port message processing
      await Future.delayed(const Duration(milliseconds: 100));

      expect(waiter1Completed, isTrue);
      expect(waiter2Completed, isTrue);

      await f1;
      await f2;

      // Clean up other packets
      for (final p in packets) {
        p.completionPort.send(p.address);
      }
      await Future.delayed(const Duration(milliseconds: 50));
    });
  });
}
