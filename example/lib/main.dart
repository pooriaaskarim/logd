import 'package:logger/logd.dart';

void main() {
  Logger.global.t
    ?..writeln('clicked on button')
    ..sync();

  Logger.global.d
    ?..writeln('User logged in')
    ..writeln('ID: 12345')
    ..writeln('From IP: 192.168.1.1')
    ..sync();

  Logger.global.e
    ?..writeln('Failed to connect to API')
    ..writeln('Timeout after 5s')
    ..writeln('Retry count: 3')
    ..sync();
}
