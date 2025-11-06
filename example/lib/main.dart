import 'package:logger/logd.dart';

void main() {
  Logger.includeFileLineInHeader = true;

  Logger.t(LogBuffer.t?..writeln('clicked on button'));

  Logger.d(
    LogBuffer.d
      ?..writeln('User logged in')
      ..writeln('ID: 12345')
      ..writeln('From IP: 192.168.1.1'),
  );

  Logger.e(
    LogBuffer.e
      ?..writeln('Failed to connect to API')
      ..writeln('Timeout after 5s')
      ..writeln('Retry count: 3'),
  );
}
