// Mars FFI bridge - C ABI implementation over the Mars C++ SDK.
//
// Wraps the official Mars APIs (xlogger, xlog appender) with a stable C
// interface declared in mars.h. Uses public Mars headers plus the local
// (non-vendored) xlog decoder in src/xlog/; no changes are made to the
// vendored Tencent source.

#include "mars.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "mars/comm/time_utils.h"
#include "mars/comm/xlogger/xloggerbase.h"
#include "mars/xlog/appender.h"
#include "xlog/decode.h"

// mars.h forward-declares MarsBuffer for the FFI surface; the definition is
// private to this bridge implementation (decode() is MarsBuffer-free).
struct MarsBuffer
{
  char *value; // buffer bytes (library-allocated; NULL only when size is 0)
  size_t size; // length in bytes
};

extern "C"
{
  MarsBuffer *mars_create_buffer()
  {
    // calloc(1, ...) zero-initializes the handle (value = NULL, size = 0)
    // and returns NULL on allocation failure.
    return static_cast<MarsBuffer *>(calloc(1, sizeof(MarsBuffer)));
  }

  void mars_free_buffer(MarsBuffer *buffer)
  {
    if (NULL == buffer)
    {
      return;
    }
    // Must be freed here: the storage comes from this library's C runtime
    // (static /MT on Windows), which may differ from the caller's allocator.
    free(buffer->value);
    free(buffer);
  }

  int mars_write_buffer(MarsBuffer *buffer, const char *input, size_t size)
  {
    if (NULL == input && size > 0)
    {
      return -1;
    }
    if (NULL == buffer)
    {
      return -1;
    }
    if (0 == size)
    {
      free(buffer->value);
      buffer->value = NULL;
      buffer->size = 0;
    }
    else
    {
      char *tmp = static_cast<char *>(realloc(buffer->value, size));
      if (NULL == tmp)
      {
        return -2;
      }
      memcpy(tmp, input, size);
      buffer->value = tmp;
      buffer->size = size;
    }
    return 0;
  }

  size_t mars_read_buffer(const MarsBuffer *buffer, char *output, size_t size)
  {
    if (NULL == buffer)
    {
      return 0;
    }
    if (NULL == output || size < buffer->size)
    {
      return buffer->size; // required size, nothing copied
    }
    if (buffer->size > 0)
    {
      memcpy(output, buffer->value, buffer->size);
    }
    return buffer->size;
  }

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

  int mars_xlog_decode(const char *input, size_t size, MarsBuffer *buffer, const char *priv_key)
  {
    if (NULL == input || 0 == size || NULL == buffer)
    {
      return -1;
    }
    return decode(input, size, &buffer->value, &buffer->size, priv_key);
  }
} // extern "C"
