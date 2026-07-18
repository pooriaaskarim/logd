import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:logd/logd.dart';
// ignore: implementation_imports
import 'package:logd/src/time/timestamp.dart';

class TimezoneOffsetLocalBenchmark extends BenchmarkBase {
  TimezoneOffsetLocalBenchmark() : super('TimezoneOffsetLocal');

  late Timezone timezone;

  @override
  void setup() {
    Timezone.ensureInitialized();
    timezone = Timezone.local();
  }

  @override
  void run() {
    final _ = timezone.offset;
  }
}

class TimezoneOffsetNamedBenchmark extends BenchmarkBase {
  TimezoneOffsetNamedBenchmark() : super('TimezoneOffsetNamed');

  late Timezone timezone;

  @override
  void setup() {
    Timezone.ensureInitialized();
    timezone = Timezone.named('America/New_York');
  }

  @override
  void run() {
    final _ = timezone.offset;
  }
}

class TimestampFormattingBenchmark extends BenchmarkBase {
  TimestampFormattingBenchmark() : super('TimestampFormatting');

  late TimestampFormatter formatter;
  late DateTime time;

  @override
  void setup() {
    formatter = TimestampFormatter('yyyy-MM-dd HH:mm:ss.SSS Z');
    time = DateTime.now();
  }

  @override
  void run() {
    final _ = formatter.format(time);
  }
}

void runTimezoneBenchmarks() {
  print('\n--- Timezone Cache Performance ---');
  TimezoneOffsetLocalBenchmark().report();
  TimezoneOffsetNamedBenchmark().report();
  TimestampFormattingBenchmark().report();
}
