// Mars FFI bridge - C ABI implementation over the Mars C++ SDK.
//
// Wraps the official Mars APIs (xlogger, xlog appender) with a stable C
// interface declared in mars.h. Uses only public Mars headers; no changes
// are made to the vendored Tencent source.

#include "mars.h"

#include <stdint.h>
#include <string.h>

#include "mars/comm/time_utils.h"
#include "mars/comm/xlogger/xloggerbase.h"
#include "mars/xlog/appender.h"

extern "C"
{
  void mars_xlog_appender_open(int mode, const char *logs_dir, const char *cache_dir, int cache_days, const char *name_prefix, int compress_mode, int compress_level, const char *pub_key)
  {
    mars::xlog::XLogConfig config;
    config.mode_ = static_cast<mars::xlog::TAppenderMode>(mode);
    config.logdir_ = logs_dir;
    config.cachedir_ = cache_dir;
    config.cache_days_ = cache_days;
    config.nameprefix_ = name_prefix;
    config.compress_mode_ = static_cast<mars::xlog::TCompressMode>(compress_mode);
    config.compress_level_ = compress_level;
    config.pub_key_ = pub_key;
    mars::xlog::appender_open(config);
  }

  void mars_xlog_appender_close()
  {
    mars::xlog::appender_close();
  }

  void mars_xlog_appender_flush()
  {
    mars::xlog::appender_flush();
  }

  void mars_xlog_appender_flush_sync()
  {
    mars::xlog::appender_flush_sync();
  }

  void mars_xlog_appender_set_console_log(int is_open)
  {
    mars::xlog::appender_set_console_log(is_open != 0);
  }

  void mars_xlog_appender_set_max_file_size(uint64_t max_byte_size)
  {
    mars::xlog::appender_set_max_file_size(max_byte_size);
  }

  void mars_xlog_appender_set_max_alive_duration(int64_t max_time_seconds)
  {
    mars::xlog::appender_set_max_alive_duration(static_cast<long>(max_time_seconds));
  }

  int mars_xlog_xlogger_level()
  {
    return static_cast<int>(xlogger_Level());
  }

  void mars_xlog_xlogger_set_level(int level)
  {
    xlogger_SetLevel(static_cast<TLogLevel>(level));
  }

  int mars_xlog_xlogger_is_enabled_for(int level)
  {
    return xlogger_IsEnabledFor(static_cast<TLogLevel>(level));
  }

  void mars_xlog_xlogger_write(int level, const char *tag, const char *file_name, int line, const char *func_name, const char *message)
  {
    XLoggerInfo info = XLOGGER_INFO_INITIALIZER;
    info.level = static_cast<TLogLevel>(level);
    info.tag = tag;
    info.filename = file_name;
    info.line = line;
    info.func_name = func_name;
    info.timeval = get_timeval();
    info.pid = xlogger_pid();
    info.tid = xlogger_tid();
    info.maintid = xlogger_maintid();
    info.traceLog = 0;
    xlogger_Write(&info, message);
  }
} // extern "C"
