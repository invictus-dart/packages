//
//  MarsError.swift
//  mars_flutter
//
//  Created by 闫守旺 on 2026/11/13.
//

public enum MarsError: Error, CustomStringConvertible {
    case dlopenError(String)
    case dlsymError(String)
    case decodeError(String)
    
    public var description: String {
        switch self {
        case .dlopenError(let message):
            return "dlopen error: \(message)"
        case .dlsymError(let symbol):
            return "dlsym error: \(symbol)"
        case .decodeError(let message):
            return "decode error: \(message)"
        }
    }
}
