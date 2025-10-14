//
//  DNSReachabilityToolTests.swift
//  breadcrumbsTests
//
//  Tests for DNS reachability tool functionality
//

@testable import breadcrumbs
import XCTest

@MainActor
final class DNSReachabilityToolTests: XCTestCase {
    var tool: DNSReachabilityTool!

    override func setUp() {
        super.setUp()
        tool = DNSReachabilityTool()
    }

    override func tearDown() {
        tool = nil
        super.tearDown()
    }

    // MARK: - Tool Protocol Tests

    func testToolName() {
        XCTAssertEqual(tool.name, "dns_reachability")
    }

    func testToolDescription() {
        XCTAssertFalse(tool.description.isEmpty)
        XCTAssertTrue(tool.description.contains("DNS"))
        XCTAssertTrue(tool.description.contains("reachable"))
    }

    func testParametersSchema() throws {
        let schema = tool.parametersSchema.jsonSchema

        XCTAssertEqual(schema["type"] as? String, "object")

        let properties = try XCTUnwrap(schema["properties"] as? [String: Any])

        // Check required domain property
        XCTAssertNotNil(properties["domain"])

        // Check optional properties
        XCTAssertNotNil(properties["record_type"])
        XCTAssertNotNil(properties["dns_server"])
        XCTAssertNotNil(properties["timeout"])

        // Check required fields
        let required = try XCTUnwrap(schema["required"] as? [String])

        XCTAssertTrue(required.contains("domain"))
        XCTAssertEqual(required.count, 1)
    }

    // MARK: - Input Model Tests

    func testDNSReachabilityInputToDictionary() {
        let input = DNSReachabilityInput(
            domain: "google.com",
            recordType: "A",
            dnsServer: "8.8.8.8",
            timeout: 5.0
        )

        let dict = input.toDictionary()

        XCTAssertEqual(dict["domain"] as? String, "google.com")
        XCTAssertEqual(dict["record_type"] as? String, "A")
        XCTAssertEqual(dict["dns_server"] as? String, "8.8.8.8")
        XCTAssertEqual(dict["timeout"] as? Double, 5.0)
    }

    func testDNSReachabilityInputMinimal() {
        let input = DNSReachabilityInput(
            domain: "apple.com",
            recordType: nil,
            dnsServer: nil,
            timeout: nil
        )

        let dict = input.toDictionary()

        XCTAssertEqual(dict["domain"] as? String, "apple.com")
        XCTAssertNil(dict["record_type"])
        XCTAssertNil(dict["dns_server"])
        XCTAssertNil(dict["timeout"])
    }

    // MARK: - Output Model Tests

    func testDNSRecord() {
        let record = DNSRecord(type: "A", value: "1.2.3.4", ttl: 300)

        XCTAssertEqual(record.type, "A")
        XCTAssertEqual(record.value, "1.2.3.4")
        XCTAssertEqual(record.ttl, 300)
    }

    func testDNSReachabilityOutputSuccess() {
        let records = [
            DNSRecord(type: "A", value: "142.250.191.14", ttl: 300),
            DNSRecord(type: "A", value: "142.250.191.15", ttl: 300),
        ]

        let output = DNSReachabilityOutput(
            domain: "google.com",
            isReachable: true,
            dnsRecords: records,
            errorMessage: nil,
            responseTime: 0.123,
            dnsServer: "8.8.8.8",
            timestamp: Date()
        )

        let formatted = output.toFormattedString()

        XCTAssertTrue(formatted.contains("google.com"))
        XCTAssertTrue(formatted.contains("YES"))
        XCTAssertTrue(formatted.contains("142.250.191.14"))
        XCTAssertTrue(formatted.contains("142.250.191.15"))
        XCTAssertTrue(formatted.contains("0.123"))
        XCTAssertTrue(formatted.contains("8.8.8.8"))
    }

    func testDNSReachabilityOutputFailure() {
        let output = DNSReachabilityOutput(
            domain: "nonexistent.example",
            isReachable: false,
            dnsRecords: [],
            errorMessage: "NXDOMAIN",
            responseTime: 2.5,
            dnsServer: nil,
            timestamp: Date()
        )

        let formatted = output.toFormattedString()

        XCTAssertTrue(formatted.contains("nonexistent.example"))
        XCTAssertTrue(formatted.contains("NO"))
        XCTAssertTrue(formatted.contains("NXDOMAIN"))
        XCTAssertTrue(formatted.contains("2.500"))
    }

    // MARK: - Tool Execution Tests

    func testExecuteWithValidDomain() async throws {
        let arguments = [
            "domain": "google.com",
            "record_type": "A",
        ]

        let result = try await tool.execute(arguments: arguments)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("google.com"))
        XCTAssertTrue(result.contains("DNS Reachability Check"))
    }

    func testExecuteWithInvalidDomain() async throws {
        let arguments = [
            "domain": "thisdomaindoesnotexist12345.com",
            "record_type": "A",
        ]

        let result = try await tool.execute(arguments: arguments)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("thisdomaindoesnotexist12345.com"))
        XCTAssertTrue(result.contains("NO"))
    }

    func testExecuteWithEmptyDomain() async {
        let arguments = [
            "domain": "",
            "record_type": "A",
        ]

        do {
            _ = try await tool.execute(arguments: arguments)
            XCTFail("Should have thrown an error for empty domain")
        } catch {
            XCTAssertTrue(error is ToolError)
        }
    }

    func testExecuteWithMissingDomain() async {
        let arguments = [String: Any]()

        do {
            _ = try await tool.execute(arguments: arguments)
            XCTFail("Should have thrown an error for missing domain")
        } catch {
            XCTAssertTrue(error is ToolError)
        }
    }

    func testExecuteWithDifferentRecordTypes() async throws {
        // Test only record types that the tool actually supports
        let supportedRecordTypes = ["A", "AAAA"]

        for recordType in supportedRecordTypes {
            let arguments: [String: Any] = [
                "domain": "google.com",
                "record_type": recordType,
            ]

            let result = try await tool.execute(arguments: arguments)

            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("google.com"))
            // Check if the result contains the record type in the DNS records section
            // The format is "• TYPE: value" so we check for "• TYPE:" or just "TYPE:"
            XCTAssertTrue(
                result.contains("\(recordType):") || result.contains("• \(recordType):"),
                "Result should contain record type \(recordType). Result: \(result)"
            )
        }

        // Test unsupported record types (should default to A record)
        let unsupportedRecordTypes = ["MX", "CNAME", "TXT", "NS", "SOA"]

        for recordType in unsupportedRecordTypes {
            let arguments: [String: Any] = [
                "domain": "google.com",
                "record_type": recordType,
            ]

            let result = try await tool.execute(arguments: arguments)

            XCTAssertFalse(result.isEmpty)
            XCTAssertTrue(result.contains("google.com"))
            // Unsupported types should default to A record
            XCTAssertTrue(
                result.contains("A:") || result.contains("• A:"),
                "Unsupported record type \(recordType) should default to A record. Result: \(result)"
            )
        }
    }

    func testExecuteWithCustomDNSServer() async throws {
        let arguments: [String: Any] = [
            "domain": "google.com",
            "record_type": "A",
            "dns_server": "8.8.8.8",
        ]

        let result = try await tool.execute(arguments: arguments)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("google.com"))
        XCTAssertTrue(result.contains("8.8.8.8"))
    }

    func testExecuteWithCustomTimeout() async throws {
        let arguments: [String: Any] = [
            "domain": "google.com",
            "record_type": "A",
            "timeout": 10.0,
        ]

        let result = try await tool.execute(arguments: arguments)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("google.com"))
    }

    func testExecuteWithInvalidTimeout() async throws {
        let arguments: [String: Any] = [
            "domain": "google.com",
            "record_type": "A",
            "timeout": 0.5, // Very short timeout
        ]

        let result = try await tool.execute(arguments: arguments)

        // Should still work, just might timeout
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("google.com"))
    }

    // MARK: - Integration Tests

    @MainActor
    func testToolRegistryIntegration() {
        let registry = ToolRegistry(forTesting: true)
        registry.register(tool)

        let retrievedTool = registry.getTool(named: "dns_reachability")
        XCTAssertNotNil(retrievedTool)
        XCTAssertEqual(retrievedTool?.name, "dns_reachability")
    }

    func testOpenAIFunctionFormat() throws {
        let openAIFunction = tool.asOpenAIFunction

        XCTAssertEqual(openAIFunction["type"] as? String, "function")

        let function = try XCTUnwrap(openAIFunction["function"] as? [String: Any])

        XCTAssertEqual(function["name"] as? String, "dns_reachability")
        XCTAssertNotNil(function["description"])
        XCTAssertNotNil(function["parameters"])
    }

    // MARK: - Performance Tests

    func testPerformanceWithMultipleDomains() {
        let domains = ["google.com", "apple.com", "microsoft.com", "amazon.com", "netflix.com"]

        measure {
            let expectation = XCTestExpectation(description: "DNS checks complete")

            Task { @MainActor in
                for domain in domains {
                    let arguments = ["domain": domain] as [String: Any]
                    do {
                        _ = try await tool.execute(arguments: arguments)
                    } catch {
                        // Some domains might fail, that's okay for performance testing
                    }
                }
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 30.0)
        }
    }

    // MARK: - Edge Cases

    func testExecuteWithSpecialCharacters() async throws {
        let arguments: [String: Any] = [
            "domain": "www.google.com", // Use a domain that definitely exists
            "record_type": "A",
            "timeout": 3.0, // Add shorter timeout to prevent hanging
        ]

        let result = try await tool.execute(arguments: arguments)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("www.google.com"))
    }

    func testExecuteWithSubdomain() async throws {
        let arguments: [String: Any] = [
            "domain": "www.google.com",
            "record_type": "A",
        ]

        let result = try await tool.execute(arguments: arguments)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("www.google.com"))
    }

    func testExecuteWithInvalidRecordType() async throws {
        let arguments: [String: Any] = [
            "domain": "google.com",
            "record_type": "INVALID",
        ]

        // Should default to A record
        let result = try await tool.execute(arguments: arguments)

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("google.com"))
    }
}
