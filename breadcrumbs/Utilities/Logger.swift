import Foundation
import os.log

/// Simple logger utility for debugging
struct Logger {
    private static let subsystem = "dale.breadcrumbs"
    
    // MARK: - Log Categories
    
    static let general = OSLog(subsystem: subsystem, category: "general")
    static let chat = OSLog(subsystem: subsystem, category: "chat")
    static let tools = OSLog(subsystem: subsystem, category: "tools")
    static let ui = OSLog(subsystem: subsystem, category: "ui")
    
    // MARK: - Logging Methods
    
    static func log(_ message: String, category: OSLog = general, level: OSLogType = .default) {
        os_log("%{public}@", log: category, type: level, message)
    }
    
    static func debug(_ message: String, category: OSLog = general) {
        log(message, category: category, level: .debug)
    }
    
    static func info(_ message: String, category: OSLog = general) {
        log(message, category: category, level: .info)
    }
    
    static func error(_ message: String, category: OSLog = general) {
        log(message, category: category, level: .error)
    }
    
    // MARK: - Convenience Methods
    
    static func chat(_ message: String) {
        debug(message, category: chat)
    }
    
    static func tools(_ message: String) {
        debug(message, category: tools)
    }
    
    static func ui(_ message: String) {
        debug(message, category: ui)
    }
}
