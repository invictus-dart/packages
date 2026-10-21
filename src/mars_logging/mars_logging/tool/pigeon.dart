// Run with `dart run pigeon --input tool/pigeon.dart`.

import 'package:pigeon/pigeon.dart';

void main(List<String> args) async {
  final options = PigeonOptions(
    input: 'pigeon/mars_logging_api.dart',
    dartOut: 'lib/src/mars_logging_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/dev/zeekr/mars_logging/MarsLoggingApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'dev.zeekr.mars_logging',
      errorClassName: 'MarsLoggingError',
    ),
    swiftOut: 'darwin/mars_logging/Sources/mars_logging/MarsLoggingApi.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'MarsLoggingError'),
  );
  await Pigeon.runWithOptions(options);
}
