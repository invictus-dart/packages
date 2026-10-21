import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:zstd/zstd.dart';

import 'util.dart';

const kMagicNoCompressStart = 0x03;
const kMagicNoCompressStart1 = 0x06;
const kMagicNoCompressNoCryptStart = 0x08;
const kMagicCompressStart = 0x04;
const kMagicCompressStart1 = 0x05;
const kMagicCompressStart2 = 0x07;
const kMagicCompressNoCryptStart = 0x09;

const kMagicSyncZstdStart = 0x0A;
const kMagicSyncNoCryptZstdStart = 0x0B;
const kMagicAsyncZstdStart = 0x0C;
const kMagicAsyncNoCryptZstdStart = 0x0D;

const kMagicEnd = 0x00;

var lastSeq = 0;

const kPrivKey =
    '145aa7717bf9745b91e9569b80bbf1eedaa6cc6cd0e26317d810e35710f44cf8';
const kPubKey =
    '572d1e2710ae5fbca54c76a382fdd44050b3a675cb2bf39feebe85ef63d947aff0fa4943f1112e8b6af34bebebbaefa1a0aae055d9259b89a1858f7cc9af9df1';

ZLibCodec get zlib =>
    ZLibCodec(windowBits: ZLibOption.maxWindowBits, raw: true);

Uint8List teaDecipher(Uint8List v, Uint8List k) {
  const op = 0xFFFFFFFF;
  var v0 = ByteData.sublistView(v, 0, 4).getUint32(0, Endian.little);
  var v1 = ByteData.sublistView(v, 4, 8).getUint32(0, Endian.little);
  final k1 = ByteData.sublistView(k, 0, 4).getUint32(0, Endian.little);
  final k2 = ByteData.sublistView(k, 4, 8).getUint32(0, Endian.little);
  final k3 = ByteData.sublistView(k, 8, 12).getUint32(0, Endian.little);
  final k4 = ByteData.sublistView(k, 12, 16).getUint32(0, Endian.little);
  const delta = 0x9E3779B9;
  var s = (delta << 4) & op;
  for (int i = 0; i < 16; i++) {
    v1 = (v1 - (((v0 << 4) + k3) ^ (v0 + s) ^ ((v0 >> 5) + k4))) & op;
    v0 = (v0 - (((v1 << 4) + k1) ^ (v1 + s) ^ ((v1 >> 5) + k2))) & op;
    s = (s - delta) & op;
  }
  final result = ByteData(8);
  result.setUint32(0, v0, Endian.little);
  result.setUint32(4, v1, Endian.little);
  return result.buffer.asUint8List();
}

Uint8List teaDecrypt(Uint8List v, Uint8List k) {
  final num = v.length - (v.length % 8);
  final ret = BytesBuilder();
  for (int i = 0; i < num; i += 8) {
    final x = teaDecipher(v.sublist(i, i + 8), k);
    ret.add(x);
  }
  ret.add(v.sublist(num));
  return ret.toBytes();
}

(bool, String) isGoodLogBuffer(Uint8List buffer, int offset, int count) {
  if (offset >= buffer.length) return (true, '');

  final int cryptKeyLen;
  final magicStart = buffer[offset];
  switch (magicStart) {
    case kMagicNoCompressStart:
    case kMagicCompressStart:
    case kMagicCompressStart1:
      cryptKeyLen = 4;
      break;
    case kMagicCompressStart2:
    case kMagicNoCompressStart1:
    case kMagicNoCompressNoCryptStart:
    case kMagicCompressNoCryptStart:
    case kMagicSyncZstdStart:
    case kMagicSyncNoCryptZstdStart:
    case kMagicAsyncZstdStart:
    case kMagicAsyncNoCryptZstdStart:
      cryptKeyLen = 64;
      break;
    default:
      return (false, 'buffer[$offset]:$magicStart != MAGIC_NUM_START');
  }

  final headerLen = 1 + 2 + 1 + 1 + 4 + cryptKeyLen;

  if (offset + headerLen + 1 + 1 > buffer.length) {
    return (false, 'offset:$offset > len(buffer):${buffer.length}');
  }
  final view = ByteData.view(buffer.buffer);
  final length = view.getUint32(
    offset + headerLen - 4 - cryptKeyLen,
    Endian.little,
  );
  if (offset + headerLen + length + 1 > buffer.length) {
    return (
      false,
      'log length:$length, end pos ${offset + headerLen + length} > len(buffer):${buffer.length}',
    );
  }
  if (kMagicEnd != buffer[offset + headerLen + length]) {
    return (
      false,
      'log length:$length, buffer[${offset + headerLen + length}]:${buffer[offset + headerLen + length]} != MAGIC_END',
    );
  }

  if (count <= 1) {
    return (true, '');
  } else {
    return isGoodLogBuffer(buffer, offset + headerLen + length + 1, count - 1);
  }
}

int getLogStartPos(Uint8List buffer, int count) {
  for (var i = 0; i < buffer.length; i++) {
    final magicStart = buffer[i];
    if (magicStart == kMagicNoCompressStart ||
        magicStart == kMagicNoCompressStart1 ||
        magicStart == kMagicCompressStart ||
        magicStart == kMagicCompressStart1 ||
        magicStart == kMagicCompressStart2 ||
        magicStart == kMagicCompressNoCryptStart ||
        magicStart == kMagicNoCompressNoCryptStart ||
        magicStart == kMagicSyncZstdStart ||
        magicStart == kMagicSyncNoCryptZstdStart ||
        magicStart == kMagicAsyncZstdStart ||
        magicStart == kMagicAsyncNoCryptZstdStart) {
      final (ok, _) = isGoodLogBuffer(buffer, i, count);
      if (ok) return i;
    }
  }
  return -1;
}

int decodeBuffer(
  Uint8List buffer,
  int offset,
  BytesBuilder outBuffer,
  String privKey,
) {
  if (offset >= buffer.length) return -1;
  final (ok, err) = isGoodLogBuffer(buffer, offset, 1);
  if (!ok) {
    final fixPos = getLogStartPos(buffer.sublist(offset), 1);
    if (fixPos == -1) {
      return -1;
    } else {
      outBuffer.add(
        utf8.encode(
          "[F]decode_log_file.dart decode error len=$fixPos, result:$err\n",
        ),
      );
      offset += fixPos;
    }
  }

  final int cryptKeyLen;
  final magicStart = buffer[offset];
  switch (magicStart) {
    case kMagicNoCompressStart:
    case kMagicCompressStart:
    case kMagicCompressStart1:
      cryptKeyLen = 4;
    case kMagicCompressStart2:
    case kMagicNoCompressStart1:
    case kMagicNoCompressNoCryptStart:
    case kMagicCompressNoCryptStart:
    case kMagicSyncZstdStart:
    case kMagicSyncNoCryptZstdStart:
    case kMagicAsyncZstdStart:
    case kMagicAsyncNoCryptZstdStart:
      cryptKeyLen = 64;
      break;
    default:
      outBuffer.add(
        utf8.encode(
          'in decodeBuffer buffer[$offset]:$magicStart != MAGIC_NUM_START\n',
        ),
      );
      return -1;
  }

  final view = ByteData.view(buffer.buffer, offset);
  final headerLen = 1 + 2 + 1 + 1 + 4 + cryptKeyLen;
  final length = view.getUint32(headerLen - 4 - cryptKeyLen, Endian.little);

  final seq = view.getUint16(
    headerLen - 4 - cryptKeyLen - 2 - 2,
    Endian.little,
  );
  // final beginHour = view.getUint8(headerLen - 4 - cryptKeyLen - 1 - 1);
  // final endHour = view.getUint8(headerLen - 4 - cryptKeyLen - 1);

  if (seq != 0 && seq != 1 && lastSeq != 0 && seq != (lastSeq + 1)) {
    outBuffer.add(
      utf8.encode(
        "[F]decode_log_file.py log seq:${lastSeq + 1}-${seq - 1} is missing\n",
      ),
    );
  }

  if (seq != 0) {
    lastSeq = seq;
  }

  var tmpBuffer = buffer.sublist(
    offset + headerLen,
    offset + headerLen + length,
  );

  try {
    switch (magicStart) {
      case kMagicNoCompressStart1:
      case kMagicSyncZstdStart:
        break;
      case kMagicCompressStart2:
      case kMagicAsyncZstdStart:
        final ecParams = ECCurve_secp256k1();
        final ecPubKeyX = buffer.sublist(
          offset + headerLen - cryptKeyLen,
          offset + headerLen - cryptKeyLen ~/ 2,
        );
        final ecPubKeyY = buffer.sublist(
          offset + headerLen - cryptKeyLen ~/ 2,
          offset + headerLen,
        );
        final ecPubKey = ECPublicKey(
          ecParams.curve.createPoint(
            ecPubKeyX.toBigInt(Endian.big),
            ecPubKeyY.toBigInt(Endian.big),
          ),
          ecParams,
        );
        final ecD = BigInt.parse(privKey, radix: 16);
        final ecPrivKey = ECPrivateKey(ecD, ecParams);
        final ecAgreement = ECDHBasicAgreement()..init(ecPrivKey);
        final teaKey = ecAgreement
            .calculateAgreement(ecPubKey)
            .toUint8List(Endian.big);

        tmpBuffer = teaDecrypt(tmpBuffer, teaKey);
        if (magicStart == kMagicCompressStart2) {
          tmpBuffer = zlib.decode(tmpBuffer).toUint8List();
        } else {
          tmpBuffer = zstd.decode(tmpBuffer).toUint8List();
        }
        break;
      case kMagicAsyncNoCryptZstdStart:
        tmpBuffer = zstd.decode(tmpBuffer).toUint8List();
        break;
      case kMagicCompressStart:
      case kMagicCompressNoCryptStart:
        tmpBuffer = zlib.decode(tmpBuffer).toUint8List();
        break;
      case kMagicCompressStart1:
        final decompressData = BytesBuilder();
        while (tmpBuffer.isNotEmpty) {
          final tmpView = ByteData.view(tmpBuffer.buffer);
          final singleLogLen = tmpView.getUint16(0, Endian.little);
          decompressData.add(tmpBuffer.sublist(2, singleLogLen + 2));
          tmpBuffer = tmpBuffer.sublist(singleLogLen + 2);
        }
        tmpBuffer = zlib.decode(decompressData.toBytes()).toUint8List();
        break;
      default:
        break;
    }
    outBuffer.add(tmpBuffer);
  } catch (e) {
    outBuffer.add(utf8.encode("[F]decode_log_file.dart decompress err, $e\n"));
  }

  return offset + headerLen + length + 1;
}

void parseFile(File file, File outFile) {
  final buffer = file.readAsBytesSync();
  var startPos = getLogStartPos(buffer, 2);
  if (startPos == -1) return;
  final outBuffer = BytesBuilder();
  while (true) {
    startPos = decodeBuffer(buffer, startPos, outBuffer, kPrivKey);
    if (startPos == -1) break;
  }
  if (outBuffer.isEmpty) return;
  outFile.writeAsBytesSync(outBuffer.toBytes());
}

void main(List<String> args) {
  switch (args.length) {
    case 1:
      final path = args[0];
      if (path.isDirectory) {
        final files =
            Directory(path)
                .listSync()
                .whereType<File>()
                .where((e) => e.path.endsWith('.xlog'))
                .toList();
        for (var file in files) {
          lastSeq = 0;
          final outFile = File(file.path.replaceExtension('log'));
          parseFile(file, outFile);
        }
      } else {
        final file = File(path);
        final outFile = File(file.path.replaceExtension('log'));
        parseFile(file, outFile);
      }
      break;
    case 2:
      final file = File(args[0]);
      final outFile = File(args[1]);
      parseFile(file, outFile);
      break;
    default:
      var files =
          Directory.current
              .listSync()
              .whereType<File>()
              .where((e) => e.path.endsWith('.xlog'))
              .toList();
      for (var file in files) {
        lastSeq = 0;
        final outFile = File(file.path.replaceExtension('log'));
        parseFile(file, outFile);
      }
      break;
  }
}
