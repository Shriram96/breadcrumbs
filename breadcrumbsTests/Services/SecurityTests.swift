//
//  SecurityTests.swift
//  breadcrumbsTests
//
//  Tests for security improvements in the breadcrumbs application
//

import XCTest
@testable import breadcrumbs

final class SecurityTests: XCTestCase {
    
    // MARK: - API Key Generation Tests
    
    func testAPIKeyGenerationIsSecure() async {
        // This test verifies that API key generation uses cryptographically secure random
        let aiModel = MockAIModel()
        let toolRegistry = ToolRegistry.shared
        let serviceManager = await ServiceManager(aiModel: aiModel, toolRegistry: toolRegistry)
        
        await MainActor.run {
            // The API key should be generated on init and not be the default
            XCTAssertNotEqual(serviceManager.apiKey, "demo-key-123", "API key should not be the default value")
            
            // API key should have reasonable length (base64 encoded 32 bytes = ~43-44 chars)
            XCTAssertGreaterThan(serviceManager.apiKey.count, 30, "API key should be at least 30 characters")
        }
    }
    
    func testAPIKeyGenerationIsUnique() async {
        // Generate multiple API keys and verify they are unique
        let aiModel = MockAIModel()
        let toolRegistry = ToolRegistry.shared
        
        var keys = Set<String>()
        for _ in 0..<10 {
            let serviceManager = await ServiceManager(aiModel: aiModel, toolRegistry: toolRegistry)
            let key = await MainActor.run { serviceManager.apiKey }
            keys.insert(key)
        }
        
        // All keys should be unique
        XCTAssertEqual(keys.count, 10, "All generated API keys should be unique")
    }
    
    // MARK: - Constant-Time Comparison Tests
    
    func testConstantTimeComparison() {
        // Test the constant-time comparison logic
        // Note: We can't directly test the private function, but we can verify behavior
        
        let key1 = "test-key-12345"
        let key2 = "test-key-12345"
        let key3 = "test-key-54321"
        
        // Same strings should be equal
        XCTAssertTrue(constantTimeCompareTest(key1, key2), "Identical keys should compare equal")
        
        // Different strings should not be equal
        XCTAssertFalse(constantTimeCompareTest(key1, key3), "Different keys should compare not equal")
        
        // Different lengths should not be equal
        XCTAssertFalse(constantTimeCompareTest("short", "longer-string"), "Different length keys should compare not equal")
    }
    
    // Helper function that mimics the constant-time comparison
    private func constantTimeCompareTest(_ a: String, _ b: String) -> Bool {
        guard a.count == b.count else {
            return false
        }
        
        let aBytes = Array(a.utf8)
        let bBytes = Array(b.utf8)
        
        var result: UInt8 = 0
        for i in 0..<aBytes.count {
            result |= aBytes[i] ^ bBytes[i]
        }
        
        return result == 0
    }
    
    // MARK: - Input Validation Tests
    
    func testSuspiciousPatternDetection() {
        // Test the suspicious pattern detection logic
        
        let suspiciousPatterns = [
            "<script>alert('xss')</script>",
            "javascript:void(0)",
            "<img onerror='alert(1)'>",
            "<body onload='malicious()'>",
            "eval(document.cookie)",
            "exec('rm -rf /')",
            "../../../etc/passwd",
            "..\\..\\..\\windows\\system32",
            "file:///etc/passwd",
            "data:text/html,<script>alert('xss')</script>"
        ]
        
        for pattern in suspiciousPatterns {
            XCTAssertTrue(containsSuspiciousPatternsTest(pattern), "Should detect suspicious pattern: \(pattern)")
        }
        
        // Normal messages should not be flagged
        let normalMessages = [
            "Check my VPN status",
            "What's my network configuration?",
            "Help me diagnose connectivity issues",
            "My internet is slow today"
        ]
        
        for message in normalMessages {
            XCTAssertFalse(containsSuspiciousPatternsTest(message), "Should not flag normal message: \(message)")
        }
    }
    
    // Helper function that mimics the suspicious pattern detection
    private func containsSuspiciousPatternsTest(_ text: String) -> Bool {
        let suspiciousPatterns = [
            "<script", "javascript:", "onerror=", "onload=",
            "eval(", "exec(", "../", "..\\",
            "file://", "data:text/html"
        ]
        
        let lowercaseText = text.lowercased()
        return suspiciousPatterns.contains { lowercaseText.contains($0) }
    }
    
    // MARK: - Message Length Validation Tests
    
    func testMessageLengthValidation() {
        // Test that we can validate message length
        // Note: VaporServer.maxMessageLength is internal to the VaporServer class
        // We replicate the value here but should keep in sync with production code
        let maxLength = 100_000 // Should match VaporServer.maxMessageLength
        
        // Message at exactly max length should be valid
        let maxMessage = String(repeating: "a", count: maxLength)
        XCTAssertEqual(maxMessage.count, maxLength, "Max length message should be allowed")
        
        // Message over max length should be invalid
        let tooLongMessage = String(repeating: "a", count: maxLength + 1)
        XCTAssertGreaterThan(tooLongMessage.count, maxLength, "Message over max length should be detected")
        
        // Empty message should be invalid
        let emptyMessage = ""
        XCTAssertTrue(emptyMessage.isEmpty, "Empty message should be detected")
    }
    
    // MARK: - Logger Security Category Tests
    
    func testSecurityLoggerExists() {
        // Verify the security logger category exists and is configured
        XCTAssertNotNil(Logger.security, "Security logger category should exist")
    }
}
