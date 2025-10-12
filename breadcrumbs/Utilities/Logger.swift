import Foundation
import os.log

/// Simple logger utility for debugging
enum Logger {
    // MARK: Internal

    // MARK: - Log Categories

    static let general: OSLog = .init(subsystem: subsystem, category: "general")
    static let chat: OSLog = .init(subsystem: subsystem, category: "chat")
    static let tools: OSLog = .init(subsystem: subsystem, category: "tools")
    static let ui: OSLog = .init(subsystem: subsystem, category: "ui")
    static let security: OSLog = .init(subsystem: subsystem, category: "security")

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
    
    static func security(_ message: String, level: OSLogType = .error) {
        log(message, category: security, level: level)
    }

    // MARK: Private

    private static let subsystem = "dale.breadcrumbs"
}
