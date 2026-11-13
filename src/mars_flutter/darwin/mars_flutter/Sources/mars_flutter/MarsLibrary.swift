import Foundation

/** Loads the Flutter-bundled mars.framework and resolves mars.h symbols. */
internal class MarsLibrary {
    static let shared: MarsLibrary = MarsLibrary()
    
    private init() {}
    
    typealias MarsCreateBuffer = @convention(c) () -> UnsafeMutableRawPointer?
    typealias MarsFreeBuffer = @convention(c) (UnsafeMutableRawPointer?) -> Void
    typealias MarsReadBuffer = @convention(c) (
        UnsafeMutableRawPointer?,
        UnsafeMutableRawPointer?,
        Int
    ) -> Int
    typealias MarsXlogAppenderOpen = @convention(c) (
        Int32,
        UnsafePointer<CChar>?,
        UnsafePointer<CChar>?,
        Int32,
        UnsafePointer<CChar>?,
        Int32,
        Int32,
        UnsafePointer<CChar>?
    ) -> Void
    typealias MarsXlogAppenderClose = @convention(c) () -> Void
    typealias MarsXlogAppenderFlushSync = @convention(c) () -> Void
    typealias MarsXlogAppenderSetConsoleLog = @convention(c) (Int32) -> Void
    typealias MarsXlogAppenderSetMaxFileSize = @convention(c) (UInt64) -> Void
    typealias MarsXlogAppenderSetMaxAliveDuration = @convention(c) (Int64) -> Void
    typealias MarsXlogXloggerSetLevel = @convention(c) (Int32) -> Void
    typealias MarsXlogXloggerIsEnabledFor = @convention(c) (Int32) -> Int32
    typealias MarsXlogXloggerWrite = @convention(c) (
        Int32,
        UnsafePointer<CChar>?,
        UnsafePointer<CChar>?,
        Int32,
        UnsafePointer<CChar>?,
        UnsafePointer<CChar>?
    ) -> Void
    typealias MarsXlogDecode = @convention(c) (
        UnsafeRawPointer?,
        Int,
        UnsafeMutableRawPointer?,
        UnsafePointer<CChar>?
    ) -> Int32
    
    // TODO(thread-safety): `lazy var` initialization is unsynchronized in
    // Swift. Concurrent first access to the same symbol from multiple
    // threads races on the initializer (usually a benign duplicate dlsym,
    // worst case a torn read of the Result payload). Resolve every symbol
    // once in `init()` — protected by the dispatch_once semantics of
    // `static let shared` — or guard accessors with NSRecursiveLock once
    // the symbol set grows. Kept lazy for now so unused symbols are never
    // resolved.
    private lazy var handle_result: Result<UnsafeMutableRawPointer, Error> = Result {
        guard let frameworksUrl = Bundle.main.privateFrameworksURL else {
            throw MarsError.dlopenError("Private frameworks url is unavailable")
        }
        let marsUrl = frameworksUrl.appendingPathComponent("mars.framework/mars")
        guard let handle = dlopen(marsUrl.path, RTLD_NOW | RTLD_LOCAL) else {
            guard let errorPtr = dlerror() else {
                throw MarsError.dlopenError("Unknown dynamic loader error")
            }
            let error = String(cString: errorPtr)
            throw MarsError.dlopenError(error)
        }
        return handle
    }
    private var handle: UnsafeMutableRawPointer {
        get throws { try handle_result.get() }
    }
    
    private lazy var mars_create_buffer_result: Result<MarsCreateBuffer, Error> = Result {
        try self.handle.resolve("mars_create_buffer")
    }
    var mars_create_buffer: MarsCreateBuffer {
        get throws { try mars_create_buffer_result.get() }
    }
    
    private lazy var mars_free_buffer_result: Result<MarsFreeBuffer, Error> = Result {
        try self.handle.resolve("mars_free_buffer")
    }
    var mars_free_buffer: MarsFreeBuffer {
        get throws { try mars_free_buffer_result.get() }
    }
    
    private lazy var mars_read_buffer_result: Result<MarsReadBuffer, Error> = Result {
        try self.handle.resolve("mars_read_buffer")
    }
    var mars_read_buffer: MarsReadBuffer {
        get throws { try mars_read_buffer_result.get() }
    }
    
    private lazy var mars_xlog_appender_open_result: Result<MarsXlogAppenderOpen, Error> = Result {
        try self.handle.resolve("mars_xlog_appender_open")
    }
    var mars_xlog_appender_open: MarsXlogAppenderOpen {
        get throws { try mars_xlog_appender_open_result.get() }
    }
    
    private lazy var mars_xlog_appender_close_result: Result<MarsXlogAppenderClose, Error> = Result {
        try self.handle.resolve("mars_xlog_appender_close")
    }
    var mars_xlog_appender_close: MarsXlogAppenderClose {
        get throws { try mars_xlog_appender_close_result.get() }
    }
    
    private lazy var mars_xlog_appender_flush_sync_result: Result<MarsXlogAppenderFlushSync, Error> = Result {
        try self.handle.resolve("mars_xlog_appender_flush_sync")
    }
    var mars_xlog_appender_flush_sync: MarsXlogAppenderFlushSync {
        get throws { try mars_xlog_appender_flush_sync_result.get() }
    }
    
    private lazy var mars_xlog_appender_set_console_log_result: Result<MarsXlogAppenderSetConsoleLog, Error> = Result {
        try self.handle.resolve("mars_xlog_appender_set_console_log")
    }
    var mars_xlog_appender_set_console_log: MarsXlogAppenderSetConsoleLog {
        get throws { try mars_xlog_appender_set_console_log_result.get() }
    }
    
    private lazy var mars_xlog_appender_set_max_file_size_result: Result<MarsXlogAppenderSetMaxFileSize, Error> = Result {
        try self.handle.resolve("mars_xlog_appender_set_max_file_size")
    }
    var mars_xlog_appender_set_max_file_size: MarsXlogAppenderSetMaxFileSize {
        get throws { try mars_xlog_appender_set_max_file_size_result.get() }
    }
    
    private lazy var mars_xlog_appender_set_max_alive_duration_result: Result<MarsXlogAppenderSetMaxAliveDuration, Error> = Result {
        try self.handle.resolve("mars_xlog_appender_set_max_alive_duration")
    }
    var mars_xlog_appender_set_max_alive_duration: MarsXlogAppenderSetMaxAliveDuration {
        get throws { try mars_xlog_appender_set_max_alive_duration_result.get() }
    }
    
    private lazy var mars_xlog_xlogger_set_level_result: Result<MarsXlogXloggerSetLevel, Error> = Result {
        try self.handle.resolve("mars_xlog_xlogger_set_level")
    }
    var mars_xlog_xlogger_set_level: MarsXlogXloggerSetLevel {
        get throws { try mars_xlog_xlogger_set_level_result.get() }
    }
    
    private lazy var mars_xlog_xlogger_is_enabled_for_result: Result<MarsXlogXloggerIsEnabledFor, Error> = Result {
        try self.handle.resolve("mars_xlog_xlogger_is_enabled_for")
    }
    var mars_xlog_xlogger_is_enabled_for: MarsXlogXloggerIsEnabledFor {
        get throws { try mars_xlog_xlogger_is_enabled_for_result.get() }
    }
    
    private lazy var mars_xlog_xlogger_write_result: Result<MarsXlogXloggerWrite, Error> = Result {
        try self.handle.resolve("mars_xlog_xlogger_write")
    }
    var mars_xlog_xlogger_write: MarsXlogXloggerWrite {
        get throws { try mars_xlog_xlogger_write_result.get() }
    }
    
    private lazy var mars_xlog_decode_result: Result<MarsXlogDecode, Error> = Result {
        try self.handle.resolve("mars_xlog_decode")
    }
    var mars_xlog_decode: MarsXlogDecode {
        get throws { try mars_xlog_decode_result.get() }
    }
}

fileprivate extension UnsafeMutableRawPointer {
    func resolve<T>(_ name: String) throws -> T {
        guard let symbol = dlsym(self, name) else {
            throw MarsError.dlsymError(name)
        }
        return unsafeBitCast(symbol, to: T.self)
    }
}
