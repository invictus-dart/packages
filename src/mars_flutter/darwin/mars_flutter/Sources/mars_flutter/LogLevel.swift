//
//  LogLevel.swift
//  mars_flutter
//
//  Created by 闫守旺 on 2026/11/13.
//

public enum LogLevel: Int32 {
    // Mars assigns ALL and VERBOSE the same native value. Swift enum raw
    // values must be unique, so `all` is an alias rather than another case.
    public static let all = LogLevel.verbose
    
    case verbose = 0
    case debug = 1
    case info = 2
    case warn = 3
    case error = 4
    case fatal = 5
    case none = 6
}
