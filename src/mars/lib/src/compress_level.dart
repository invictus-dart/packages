/// Compression level for log files, 1 (fastest) to 9 (smallest output).
///
/// Valid for both [CompressMode.zlib] and [CompressMode.zstd]; the default
/// [CompressLevel.level6] matches upstream Mars.
enum CompressLevel {
  level1(1),
  level2(2),
  level3(3),
  level4(4),
  level5(5),
  level6(6),
  level7(7),
  level8(8),
  level9(9);

  final int value;

  const CompressLevel(this.value);
}
