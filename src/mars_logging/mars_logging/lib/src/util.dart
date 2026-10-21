import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

extension IntListExt on List<int> {
  Uint8List toUint8List() => Uint8List.fromList(this);

  BigInt toBigInt([Endian endian = Endian.little]) {
    final elements = this;
    var temp = BigInt.from(0);
    for (int i = 0; i < elements.length; i++) {
      final index = endian == Endian.little ? i : elements.length - i - 1;
      temp += BigInt.from(elements[index]) << (8 * i);
    }
    return temp;
    // final input = endian == Endian.little ? reversed.toList() : this;
    // final source = hex.encode(input);
    // return BigInt.parse(source, radix: 16);
  }
}

extension BitIntExt on BigInt {
  Uint8List toUint8List([Endian endian = Endian.little]) {
    var temp = this;
    final length = (temp.bitLength + 7) >> 3;
    var elements = List.filled(length, 0);
    final mask = BigInt.from(0xff);
    for (int i = 0; i < elements.length; i++) {
      final index = endian == Endian.little ? i : elements.length - i - 1;
      elements[index] = (temp & mask).toInt();
      temp = temp >> 8;
    }
    return elements.toUint8List();
    // var text = toRadixString(16);
    // if (text.length.isOdd) {
    //   text = '0$text';
    // }
    // var elements = hex.decode(text);
    // if (endian == Endian.little) {
    //   elements = elements.reversed.toList();
    // }
    // return elements.toUint8List();
  }
}

extension StringExt on String {
  bool get isDirectory => FileSystemEntity.isDirectorySync(this);
  bool get isFile => FileSystemEntity.isFileSync(this);

  String replaceExtension(String extension) =>
      '${path.withoutExtension(this)}.$extension';
}
