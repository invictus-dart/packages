import Foundation

/** Shared Xlog instance, matching the Dart top-level xlog getter. */
public var xlog: Xlog { Xlog.shared }

/** Native iOS/macOS counterpart of the Dart Xlog API. */
public class Xlog {
    fileprivate static let shared: Xlog = Xlog()
    
    private init() {}
    
    public func open(
        mode: AppenderMode = .async,
        level: LogLevel = .all,
        logsDir: String,
        cacheDir: String,
        cacheDays: Int32 = 0,
        namePrefix: String? = nil,
        compressMode: CompressMode = .zlib,
        compressLevel: CompressLevel = .level6,
        pubKey: String? = nil,
        useConsole: Bool = false,
        maxFileSize: UInt64 = 0,
        maxAliveDuration: Int64 = 10 * 24 * 60 * 60
    ) throws {
        try MarsLibrary.shared.mars_xlog_xlogger_set_level(level.rawValue)
        try MarsLibrary.shared.mars_xlog_appender_set_console_log(useConsole ? 1 : 0)
        try MarsLibrary.shared.mars_xlog_appender_set_max_file_size(maxFileSize)
        try MarsLibrary.shared.mars_xlog_appender_set_max_alive_duration(maxAliveDuration)
        try logsDir.withCString { logsDirPtr in
            try cacheDir.withCString { cacheDirPtr in
                try namePrefix.withCString { namePrefixPtr in
                    try pubKey.withCString { pubKeyPtr in
                        try MarsLibrary.shared.mars_xlog_appender_open(
                            mode.rawValue,
                            logsDirPtr,
                            cacheDirPtr,
                            cacheDays,
                            namePrefixPtr,
                            compressMode.rawValue,
                            compressLevel.rawValue,
                            pubKeyPtr
                        )
                    }
                }
            }
        }
    }
    
    /** Flushes buffered logs to disk, blocking the calling thread. */
    public func flushSync() throws {
        try MarsLibrary.shared.mars_xlog_appender_flush_sync()
    }
    
    /** Runs the blocking flush on a global utility queue. */
    @concurrent
    public func flush() async throws {
        try self.flushSync()
    }
    
    public func close() throws {
        try MarsLibrary.shared.mars_xlog_appender_close()
    }
    
    public func write(_ level: LogLevel, _ tag: String, _ message: String, error: Error? = nil, stackTrace: String? = nil) throws {
        guard try MarsLibrary.shared.mars_xlog_xlogger_is_enabled_for(level.rawValue) != 0 else {
            return
        }
        var messageBuilder = message
        if let error {
            messageBuilder += "\n\(error)"
        }
        if let stackTrace {
            messageBuilder += "\n\(stackTrace)"
        }
        try tag.withCString { tagPtr in
            try messageBuilder.withCString { messagePtr in
                try MarsLibrary.shared.mars_xlog_xlogger_write(
                    level.rawValue,
                    tagPtr,
                    nil,
                    0,
                    nil,
                    messagePtr
                )
            }
        }
    }
    
    public func verbose(_ tag: String, _ message: String, error: Error? = nil, stackTrace: String? = nil) throws {
        try self.write(.verbose, tag, message, error: error, stackTrace: stackTrace)
    }
    
    public func debug(_ tag: String, _ message: String, error: Error? = nil, stackTrace: String? = nil) throws {
        try self.write(.debug, tag, message, error: error, stackTrace: stackTrace)
    }
    
    public func info(_ tag: String, _ message: String, error: Error? = nil, stackTrace: String? = nil) throws {
        try self.write(.info, tag, message, error: error, stackTrace: stackTrace)
    }
    
    public func warn(_ tag: String, _ message: String, error: Error? = nil, stackTrace: String? = nil) throws {
        try self.write(.warn, tag, message, error: error, stackTrace: stackTrace)
    }
    
    public func error(_ tag: String, _ message: String, error: Error? = nil, stackTrace: String? = nil) throws {
        try self.write(.error, tag, message, error: error, stackTrace: stackTrace)
    }
    
    public func fatal(_ tag: String, _ message: String, error: Error? = nil, stackTrace: String? = nil) throws {
        try self.write(.fatal, tag, message, error: error, stackTrace: stackTrace)
    }
    
    /** Decodes an xlog file image, blocking the calling thread. */
    public func decodeSync(_ input: [UInt8], privKey: String? = nil) throws -> [UInt8] {
        guard let buffer = try MarsLibrary.shared.mars_create_buffer() else {
            throw MarsError.decodeError("Create buffer failed")
        }
        defer { try? MarsLibrary.shared.mars_free_buffer(buffer) }
        
        let statusCode = try input.withUnsafeBytes { inputBytes in
            try privKey.withCString { privKeyPtr in
                try MarsLibrary.shared.mars_xlog_decode(inputBytes.baseAddress, input.count, buffer, privKeyPtr)
            }
        }
        guard statusCode == 0 else {
            throw MarsError.decodeError("Decode failed (\(statusCode))")
        }
        
        let expectedSize = try MarsLibrary.shared.mars_read_buffer(buffer, nil, 0)
        guard expectedSize > 0 else { return [] }
        
        var output = [UInt8](repeating: 0, count: expectedSize)
        let actualSize = try output.withUnsafeMutableBytes { outputBytes in
            try MarsLibrary.shared.mars_read_buffer(buffer, outputBytes.baseAddress, expectedSize)
        }
        guard actualSize == expectedSize else {
            throw MarsError.decodeError("Size mismatch (\(actualSize) != \(expectedSize))")
        }
        return output
    }
    
    /** Runs the blocking decoder on a global utility queue. */
    @concurrent
    public func decode(_ input: [UInt8], privKey: String? = nil) async throws -> [UInt8] {
        try self.decodeSync(input, privKey: privKey)
    }
}

fileprivate extension String? {
    func withCString<Result>(_ body: (UnsafePointer<CChar>?) throws -> Result) rethrows -> Result {
        guard let text = self else { return try body(nil) }
        return try text.withCString(body)
    }
}
