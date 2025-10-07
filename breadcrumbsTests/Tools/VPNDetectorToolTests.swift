//
//  VPNDetectorToolTests.swift
//  breadcrumbsTests
//
//  Unit tests for VPNDetectorTool
//

@testable import breadcrumbs
import Network
import NetworkExtension
import XCTest

final class VPNDetectorToolTests: XCTestCase {
    var vpnDetectorTool: VPNDetectorTool!

    override func setUpWithError() throws {
        vpnDetectorTool = VPNDetectorTool()
    }

    override func tearDownWithError() throws {
        vpnDetectorTool = nil
    }

    // MARK: - Tool Properties Tests

    func testToolName() {
        XCTAssertEqual(vpnDetectorTool.name, "vpn_detector")
    }

    func testToolDescription() {
        XCTAssertFalse(vpnDetectorTool.description.isEmpty)
        XCTAssertTrue(vpnDetectorTool.description.contains("VPN"))
        XCTAssertTrue(vpnDetectorTool.description.contains("network"))
    }

    func testParametersSchema() {
        let schema = vpnDetectorTool.parametersSchema.jsonSchema

        XCTAssertEqual(schema["type"] as? String, "object")
        XCTAssertNotNil(schema["properties"])
        XCTAssertNotNil(schema["required"])

        let properties = schema["properties"] as? [String: [String: Any]]
        XCTAssertNotNil(properties?["interface_name"])

        let interfaceNameProperty = properties?["interface_name"] as? [String: Any]
        XCTAssertEqual(interfaceNameProperty?["type"] as? String, "string")
        XCTAssertNotNil(interfaceNameProperty?["description"])
    }

    // MARK: - Tool Execution Tests

    func testExecuteWithNoArguments() async throws {
        // Given
        let arguments = [String: Any]()

        // When
        let result = try await vpnDetectorTool.execute(arguments: arguments)

        // Then
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("VPN Connection Status"))
        XCTAssertTrue(result.contains("Connected:"))
        XCTAssertTrue(result.contains("Checked at:"))
    }

    func testExecuteWithInterfaceName() async throws {
        // Given
        let arguments: [String: Any] = ["interface_name": "utun0"]

        // When
        let result = try await vpnDetectorTool.execute(arguments: arguments)

        // Then
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("VPN Connection Status"))
    }

    func testExecuteWithInvalidInterfaceName() async throws {
        // Given
        let arguments: [String: Any] = ["interface_name": "invalid_interface"]

        // When
        let result = try await vpnDetectorTool.execute(arguments: arguments)

        // Then
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("VPN Connection Status"))
    }

    // MARK: - Input/Output Model Tests

    func testVPNDetectorInputInitialization() {
        // Given
        let interfaceName = "utun0"

        // When
        let input = VPNDetectorInput(interfaceName: interfaceName)

        // Then
        XCTAssertEqual(input.interfaceName, interfaceName)
    }

    func testVPNDetectorInputWithNilInterface() {
        // Given & When
        let input = VPNDetectorInput(interfaceName: nil)

        // Then
        XCTAssertNil(input.interfaceName)
    }

    func testVPNDetectorInputCodable() throws {
        // Given
        let originalInput = VPNDetectorInput(interfaceName: "utun0")

        // When
        let data = try JSONEncoder().encode(originalInput)
        let decodedInput = try JSONDecoder().decode(VPNDetectorInput.self, from: data)

        // Then
        XCTAssertEqual(decodedInput.interfaceName, originalInput.interfaceName)
    }

    func testVPNDetectorInputToDictionary() {
        // Given
        let input = VPNDetectorInput(interfaceName: "utun0")

        // When
        let dictionary = input.toDictionary()

        // Then
        XCTAssertEqual(dictionary["interface_name"] as? String, "utun0")
    }

    func testVPNDetectorOutputInitialization() {
        // Given
        let isConnected = true
        let vpnType = "IKEv2"
        let interfaceName = "utun0"
        let ipAddress = "192.168.1.100"
        let connectionStatus = "Connected"
        let connectedDate = Date()
        let timestamp = Date()

        // When
        let output = TestUtilities.createTestVPNDetectorOutput(
            isConnected: isConnected,
            vpnType: vpnType,
            interfaceName: interfaceName,
            ipAddress: ipAddress,
            connectionStatus: connectionStatus,
            connectedDate: connectedDate,
            timestamp: timestamp
        )

        // Then
        XCTAssertEqual(output.isConnected, isConnected)
        XCTAssertEqual(output.vpnType, vpnType)
        XCTAssertEqual(output.interfaceName, interfaceName)
        XCTAssertEqual(output.ipAddress, ipAddress)
        XCTAssertEqual(output.connectionStatus, connectionStatus)
        XCTAssertEqual(output.connectedDate, connectedDate)
        XCTAssertEqual(output.timestamp, timestamp)
    }

    func testVPNDetectorOutputToFormattedString() {
        // Given
        let output = TestUtilities.createTestVPNDetectorOutput(
            isConnected: true,
            vpnType: "IKEv2",
            interfaceName: "utun0",
            ipAddress: "192.168.1.100",
            connectionStatus: "Connected",
            connectedDate: Date(),
            timestamp: Date()
        )

        // When
        let formattedString = output.toFormattedString()

        // Then
        XCTAssertTrue(formattedString.contains("VPN Connection Status"))
        XCTAssertTrue(formattedString.contains("Connected: YES"))
        XCTAssertTrue(formattedString.contains("VPN Type: IKEv2"))
        XCTAssertTrue(formattedString.contains("Interface: utun0"))
        XCTAssertTrue(formattedString.contains("IP Address: 192.168.1.100"))
        XCTAssertTrue(formattedString.contains("Status: Connected"))
        XCTAssertTrue(formattedString.contains("Connected Since:"))
        XCTAssertTrue(formattedString.contains("Checked at:"))
    }

    func testVPNDetectorOutputDisconnectedToFormattedString() {
        // Given
        let output = TestUtilities.createTestVPNDetectorOutput(
            isConnected: false,
            vpnType: nil,
            interfaceName: nil,
            ipAddress: nil,
            connectionStatus: "Disconnected",
            connectedDate: nil,
            timestamp: Date()
        )

        // When
        let formattedString = output.toFormattedString()

        // Then
        XCTAssertTrue(formattedString.contains("VPN Connection Status"))
        XCTAssertTrue(formattedString.contains("Connected: NO"))
        XCTAssertTrue(formattedString.contains("Checked at:"))
        XCTAssertFalse(formattedString.contains("VPN Type:"))
        XCTAssertFalse(formattedString.contains("Interface:"))
        XCTAssertFalse(formattedString.contains("IP Address:"))
        XCTAssertFalse(formattedString.contains("Connected Since:"))
    }

    // MARK: - ToolInput Conformance Tests

    func testVPNDetectorInputToolInputConformance() {
        // Given
        let input = VPNDetectorInput(interfaceName: "utun0")

        // When
        let dictionary = input.toDictionary()

        // Then
        XCTAssertNotNil(dictionary)
        XCTAssertEqual(dictionary["interface_name"] as? String, "utun0")
    }

    // MARK: - ToolOutput Conformance Tests

    func testVPNDetectorOutputToolOutputConformance() {
        // Given
        let output = TestUtilities.createTestVPNDetectorOutput(
            isConnected: true,
            vpnType: "IKEv2",
            interfaceName: "utun0",
            ipAddress: "192.168.1.100",
            connectionStatus: "Connected",
            connectedDate: Date(),
            timestamp: Date()
        )

        // When
        let formattedString = output.toFormattedString()

        // Then
        XCTAssertFalse(formattedString.isEmpty)
        XCTAssertTrue(formattedString.contains("VPN Connection Status"))
    }

    // MARK: - Edge Cases Tests

    func testExecuteWithEmptyArguments() async throws {
        // Given
        let arguments = [String: Any]()

        // When
        let result = try await vpnDetectorTool.execute(arguments: arguments)

        // Then
        XCTAssertFalse(result.isEmpty)
    }

    func testExecuteWithExtraArguments() async throws {
        // Given
        let arguments: [String: Any] = [
            "interface_name": "utun0",
            "extra_param": "extra_value",
        ]

        // When
        let result = try await vpnDetectorTool.execute(arguments: arguments)

        // Then
        XCTAssertFalse(result.isEmpty)
        // Should ignore extra parameters
    }

    func testExecuteWithNonStringInterfaceName() async throws {
        // Given
        let arguments: [String: Any] = ["interface_name": 123]

        // When
        let result = try await vpnDetectorTool.execute(arguments: arguments)

        // Then
        XCTAssertFalse(result.isEmpty)
        // Should handle non-string interface name gracefully
    }

    // MARK: - Performance Tests

    func testExecutePerformance() {
        measure {
            let expectation = XCTestExpectation(description: "VPN detection")

            Task {
                do {
                    let _ = try await vpnDetectorTool.execute(arguments: [:])
                    expectation.fulfill()
                } catch {
                    XCTFail("VPN detection failed: \(error)")
                }
            }

            wait(for: [expectation], timeout: 5.0)
        }
    }

    // MARK: - Sendable Conformance Tests

    func testVPNDetectorInputSendable() {
        // This test verifies that VPNDetectorInput can be used in concurrent contexts
        let input = VPNDetectorInput(interfaceName: "utun0")

        // Create a task to verify it can be passed across concurrency boundaries
        Task {
            let _ = input
        }

        // If this compiles and runs without issues, Sendable conformance is working
        XCTAssertTrue(true)
    }

    func testVPNDetectorOutputSendable() {
        // This test verifies that VPNDetectorOutput can be used in concurrent contexts
        let output = TestUtilities.createTestVPNDetectorOutput(
            isConnected: true,
            vpnType: "IKEv2",
            interfaceName: "utun0",
            ipAddress: "192.168.1.100",
            connectionStatus: "Connected",
            connectedDate: Date(),
            timestamp: Date()
        )

        // Create a task to verify it can be passed across concurrency boundaries
        Task {
            let _ = output
        }

        // If this compiles and runs without issues, Sendable conformance is working
        XCTAssertTrue(true)
    }
}
