// Mars FFI bridge - C ABI implementation over the Mars C++ SDK.
//
// Wraps the official Mars APIs (xlogger, xlog appender) with a stable C
// interface declared in mars.h. Uses only public Mars headers; no changes
// are made to the vendored Tencent source.

#include "mars.h"

#include <stdint.h>
#include <string.h>

#include "mars/comm/time_utils.h"
#include "mars/comm/verinfo.h"
#include "mars/comm/xlogger/xloggerbase.h"
#include "mars/xlog/appender.h"

extern "C" {

const char* mars_version(void) { return MARS_REVISION; }

void mars_xlog_appender_open(int mode, const char* log_dir,
                             const char* name_prefix, const char* pub_key,
                             int compress_mode, int compress_level,
                             const char* cache_dir, int cache_days) {
  mars::xlog::XLogConfig config;
  config.mode_ = static_cast<mars::xlog::TAppenderMode>(mode);
  if (log_dir != NULL) {
    config.logdir_ = log_dir;
  }
  if (name_prefix != NULL) {
    config.nameprefix_ = name_prefix;
  }
  if (pub_key != NULL) {
    config.pub_key_ = pub_key;
  }
  config.compress_mode_ = static_cast<mars::xlog::TCompressMode>(compress_mode);
  config.compress_level_ = compress_level;
  if (cache_dir != NULL) {
    config.cachedir_ = cache_dir;
  }
  config.cache_days_ = cache_days;
  mars::xlog::appender_open(config);
}

void mars_xlog_appender_close(void) { mars::xlog::appender_close(); }

void mars_xlog_flush(void) { mars::xlog::appender_flush(); }

void mars_xlog_flush_sync(void) { mars::xlog::appender_flush_sync(); }

void mars_xlog_set_console_log(int is_open) {
  mars::xlog::appender_set_console_log(is_open != 0);
}

void mars_xlog_set_max_file_size(uint64_t max_byte_size) {
  mars::xlog::appender_set_max_file_size(max_byte_size);
}

void mars_xlog_set_max_alive_duration(int64_t max_time_seconds) {
  mars::xlog::appender_set_max_alive_duration(
      static_cast<long>(max_time_seconds));
}

void mars_xlog_write(int level, const char* tag, const char* filename,
                     int line, const char* content) {
  XLoggerInfo info = XLOGGER_INFO_INITIALIZER;
  info.level = static_cast<TLogLevel>(level);
  info.tag = tag;
  info.filename = filename;
  info.func_name = "";
  info.line = line;
  info.timeval = get_timeval();
  info.pid = xlogger_pid();
  info.tid = xlogger_tid();
  info.maintid = xlogger_maintid();
  info.traceLog = 0;
  xlogger_Write(&info, content != NULL ? content : "");
}

void mars_xlog_set_level(int level) {
  xlogger_SetLevel(static_cast<TLogLevel>(level));
}

int mars_xlog_get_level(void) { return static_cast<int>(xlogger_Level()); }

int mars_xlog_is_enabled(int level) {
  return xlogger_IsEnabledFor(static_cast<TLogLevel>(level));
}

}  // extern "C"
