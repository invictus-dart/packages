//
//  XLogImpl.swift
//  mars_logging
//
//  Created by 闫守旺 on 2025/3/19.
//

import Foundation
import mars

class XLogImpl: XLogHostApi {
    func open(mode: AppenderModeApi, level: XLogLevelApi, logsDir: String, cacheDir: String, cacheDays: Int64, namePrefix: String, compressMode: CompressModeApi, compressLevel: CompressLevelApi, pubKey: String, useConsole: Bool, maxFileSize: Int64, maxAliveDuration: Int64) throws {
        XLog.open(mode.impl, level: level.impl, logsDir: logsDir, cacheDir: cacheDir, cacheDays: Int32(cacheDays), namePrefix: namePrefix, compressMode: compressMode.impl, compressLevel: compressLevel.impl, pubKey: pubKey, useConsole: useConsole, maxFileSize: UInt64(maxFileSize), maxAliveDuration: Int(maxAliveDuration))
    }
    
    func flush(isSync: Bool) throws {
        XLog.flush(isSync)
    }
    
    func close() throws {
        XLog.close()
    }
    
    func verbose(tag: String, message: String) throws {
        XLog.verbose(tag, message: message)
    }
    
    func debug(tag: String, message: String) throws {
        XLog.debug(tag, message: message)
    }
    
    func info(tag: String, message: String) throws {
        XLog.info(tag, message: message)
    }
    
    func warning(tag: String, message: String) throws {
        XLog.warning(tag, message: message)
    }
    
    func error(tag: String, message: String) throws {
        XLog.error(tag, message: message)
    }
    
    func fatal(tag: String, message: String) throws {
        XLog.fatal(tag, message: message)
    }
}

extension AppenderModeApi {
    var impl: AppenderMode {
        switch self {
        case .async:
            return .async
        case .sync:
            return .sync
        }
    }
}

extension XLogLevelApi {
    var impl: XLogLevel {
        switch self {
        case .all:
            return .all
        case .verbose:
            return .verbose
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .fatal:
            return .fatal
        case .none:
            return .none
        }
    }
}

extension CompressModeApi {
    var impl: CompressMode {
        switch self {
        case .zlib:
            return .zlib
        case .zstd:
            return .zstd
        }
    }
    
}

extension CompressLevelApi {
    var impl: CompressLevel {
        switch self {
        case .level1:
            return .level1
        case .level2:
            return .level2
        case .level3:
            return .level3
        case .level4:
            return .level4
        case .level5:
            return .level5
        case .level6:
            return .level6
        case .level7:
            return .level7
        case .level8:
            return .level8
        case .level9:
            return .level9
        }
    }
}
