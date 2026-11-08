import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:zstd/zstd.dart';

void main() async {
  final input = await _readAsBytes('user.0AdXA5MNzW.json');
  final dictionary = await _readAsBytes('dictionary');
  _test(input);
  _testWithDictionary(input, dictionary);
}

Future<Uint8List> _readAsBytes(String reference) async {
  final fileUri = Platform.script.resolve(reference);
  final file = File.fromUri(fileUri);
  final bytes = await file.readAsBytes();
  return bytes;
}

void _test(Uint8List input) {
  final encoded = zstd.encode(input);
  final ratio = input.length / encoded.length;
  stdout.writeln('encode ratio is $ratio');
  final decoded = zstd.decode(encoded);
  stdout.writeln('decode length is ${decoded.length}');
  final text = utf8.decode(decoded);
  stdout.writeln('decode text is $text');
}

void _testWithDictionary(Uint8List input, Uint8List dictionary) {
  final zstd = ZstdCodec(dictionary: dictionary);
  final encoded = zstd.encode(input);
  final ratio = input.length / encoded.length;
  stdout.writeln('encode ratio with dictionary is $ratio');
  final decoded = zstd.decode(encoded);
  stdout.writeln('decode length is ${decoded.length}');
  final text = utf8.decode(decoded);
  stdout.writeln('decode text is $text');
}
