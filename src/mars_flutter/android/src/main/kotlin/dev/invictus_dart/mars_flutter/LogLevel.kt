package dev.invictus_dart.mars_flutter

enum class LogLevel(val value: Int) {
    ALL(0),
    VERBOSE(0),
    DEBUG(1),
    INFO(2),
    WARN(3),
    ERROR(4),
    FATAL(5),
    NONE(6),
}