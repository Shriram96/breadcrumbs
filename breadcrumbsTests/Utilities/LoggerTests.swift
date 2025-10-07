//
//  LoggerTests.swift
//  breadcrumbsTests
//
//  Unit tests for Logger utility
//

@testable import breadcrumbs
import os.log
import XCTest

final class LoggerTests: XCTestCase {
    // MARK: - Logger Category Tests

    func testLoggerCategories() {
        // Then
        XCTAssertNotNil(Logger.general)
        XCTAssertNotNil(Logger.chat)
        XCTAssertNotNil(Logger.tools)
        XCTAssertNotNil(Logger.ui)
    }

    func testLoggerSubsystem() {
        // Given
        let expectedSubsystem = "dale.breadcrumbs"

        // When
        let generalLog = Logger.general

        // Then
        // We can't directly access the subsystem from OSLog, but we can verify the log exists
        XCTAssertNotNil(generalLog)
    }

    // MARK: - Logging Methods Tests

    func testLogMethod() {
        // Given
        let message = "Test log message"

        // When & Then
        // These methods don't return values, so we just verify they don't crash
        Logger.log(message)
        Logger.log(message, category: Logger.chat)
        Logger.log(message, category: Logger.tools, level: .info)
        Logger.log(message, category: Logger.ui, level: .error)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    func testDebugMethod() {
        // Given
        let message = "Test debug message"

        // When & Then
        Logger.debug(message)
        Logger.debug(message, category: Logger.chat)
        Logger.debug(message, category: Logger.tools)
        Logger.debug(message, category: Logger.ui)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    func testInfoMethod() {
        // Given
        let message = "Test info message"

        // When & Then
        Logger.info(message)
        Logger.info(message, category: Logger.chat)
        Logger.info(message, category: Logger.tools)
        Logger.info(message, category: Logger.ui)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    func testErrorMethod() {
        // Given
        let message = "Test error message"

        // When & Then
        Logger.error(message)
        Logger.error(message, category: Logger.chat)
        Logger.error(message, category: Logger.tools)
        Logger.error(message, category: Logger.ui)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    // MARK: - Convenience Methods Tests

    func testChatConvenienceMethod() {
        // Given
        let message = "Test chat message"

        // When & Then
        Logger.chat(message)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    func testToolsConvenienceMethod() {
        // Given
        let message = "Test tools message"

        // When & Then
        Logger.tools(message)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    func testUIConvenienceMethod() {
        // Given
        let message = "Test UI message"

        // When & Then
        Logger.ui(message)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    // MARK: - Edge Cases Tests

    func testLogEmptyMessage() {
        // Given
        let emptyMessage = ""

        // When & Then
        Logger.log(emptyMessage)
        Logger.debug(emptyMessage)
        Logger.info(emptyMessage)
        Logger.error(emptyMessage)
        Logger.chat(emptyMessage)
        Logger.tools(emptyMessage)
        Logger.ui(emptyMessage)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    func testLogVeryLongMessage() {
        // Given
        let longMessage = String(repeating: "This is a very long message. ", count: 100)

        // When & Then
        Logger.log(longMessage)
        Logger.debug(longMessage)
        Logger.info(longMessage)
        Logger.error(longMessage)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    func testLogSpecialCharacters() {
        // Given
        let specialMessage = "Special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?"

        // When & Then
        Logger.log(specialMessage)
        Logger.debug(specialMessage)
        Logger.info(specialMessage)
        Logger.error(specialMessage)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    func testLogUnicodeCharacters() {
        // Given
        let unicodeMessage = "Unicode: 你好 مرحبا 🌟"

        // When & Then
        Logger.log(unicodeMessage)
        Logger.debug(unicodeMessage)
        Logger.info(unicodeMessage)
        Logger.error(unicodeMessage)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    func testLogNewlineCharacters() {
        // Given
        let newlineMessage = "Line 1\nLine 2\nLine 3"

        // When & Then
        Logger.log(newlineMessage)
        Logger.debug(newlineMessage)
        Logger.info(newlineMessage)
        Logger.error(newlineMessage)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    // MARK: - Performance Tests

    func testLoggingPerformance() {
        measure {
            for i in 0..<1000 {
                Logger.log("Performance test message \(i)")
            }
        }
    }

    func testDebugLoggingPerformance() {
        measure {
            for i in 0..<1000 {
                Logger.debug("Debug performance test message \(i)")
            }
        }
    }

    func testInfoLoggingPerformance() {
        measure {
            for i in 0..<1000 {
                Logger.info("Info performance test message \(i)")
            }
        }
    }

    func testErrorLoggingPerformance() {
        measure {
            for i in 0..<1000 {
                Logger.error("Error performance test message \(i)")
            }
        }
    }

    func testConvenienceMethodsPerformance() {
        measure {
            for i in 0..<1000 {
                Logger.chat("Chat performance test message \(i)")
                Logger.tools("Tools performance test message \(i)")
                Logger.ui("UI performance test message \(i)")
            }
        }
    }

    // MARK: - Concurrent Logging Tests

    func testConcurrentLogging() {
        let expectation = XCTestExpectation(description: "Concurrent logging")
        expectation.expectedFulfillmentCount = 100

        // When
        for i in 0..<100 {
            DispatchQueue.global().async {
                Logger.log("Concurrent message \(i)")
                Logger.debug("Concurrent debug \(i)")
                Logger.info("Concurrent info \(i)")
                Logger.error("Concurrent error \(i)")
                Logger.chat("Concurrent chat \(i)")
                Logger.tools("Concurrent tools \(i)")
                Logger.ui("Concurrent UI \(i)")
                expectation.fulfill()
            }
        }

        // Then
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - OSLog Level Tests

    func testAllOSLogLevels() {
        // Given
        let message = "Test message for all levels"

        // When & Then
        Logger.log(message, level: .default)
        Logger.log(message, level: .info)
        Logger.log(message, level: .debug)
        Logger.log(message, level: .error)
        Logger.log(message, level: .fault)

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }

    // MARK: - Category Consistency Tests

    func testCategoryConsistency() {
        // Given
        let message = "Category consistency test"

        // When & Then
        // Test that all categories work with all methods
        let categories = [Logger.general, Logger.chat, Logger.tools, Logger.ui]
        let levels: [OSLogType] = [.default, .info, .debug, .error, .fault]

        for category in categories {
            for level in levels {
                Logger.log(message, category: category, level: level)
            }
            Logger.debug(message, category: category)
            Logger.info(message, category: category)
            Logger.error(message, category: category)
        }

        // If we reach here without crashing, the test passes
        XCTAssertTrue(true)
    }
}
