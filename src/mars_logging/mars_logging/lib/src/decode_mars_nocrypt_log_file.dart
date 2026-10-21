import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

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

ZLibCodec get zlib =>
    ZLibCodec(windowBits: ZLibOption.maxWindowBits, raw: true);

(bool, String) isGoodLogBuffer(Uint8List buffer, int offset, int count) {
  if (offset == buffer.length) {
    return (true, '');
  }

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
    return (false, 'offset:$offset > buffer.length:${buffer.length}');
  }
  final view = ByteData.view(buffer.buffer);
  final length = view.getUint32(
    offset + headerLen - 4 - cryptKeyLen,
    Endian.little,
  );
  if (offset + headerLen + length + 1 > buffer.length) {
    return (
      false,
      'log length:$length, end pos ${offset + headerLen + length + 1} > buffer.length:${buffer.length}',
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

int decodeBuffer(Uint8List buffer, int offset, BytesBuilder outBuffer) {
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
      case kMagicCompressStart2:
      case kMagicSyncZstdStart:
      case kMagicAsyncZstdStart:
        stdout.writeln('use wrong decode script');
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
    outBuffer.add(utf8.encode('[F]decode_log_file.dart decompress err, $e\n'));
  }

  return offset + headerLen + length + 1;
}

void parseFile(File file, File outFile) {
  final buffer = file.readAsBytesSync();
  var startPos = getLogStartPos(buffer, 2);
  if (startPos == -1) return;
  final outbuffer = BytesBuilder();
  while (true) {
    startPos = decodeBuffer(buffer, startPos, outbuffer);
    if (startPos == -1) break;
  }
  if (outbuffer.isEmpty) return;
  outFile.writeAsBytesSync(outbuffer.toBytes());
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
