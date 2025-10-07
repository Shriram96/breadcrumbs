//
//  VPNDetectorTool.swift
//  breadcrumbs
//
//  System diagnostic tool for detecting VPN connection status
//

import Foundation
import Network
import NetworkExtension
import SystemConfiguration

// MARK: - VPNDetectorInput

/// Input model for VPN detection
struct VPNDetectorInput: ToolInput, Codable {
    enum CodingKeys: String, CodingKey {
        case interfaceName = "interface_name"
    }

    /// Optional: specific interface to check (if nil, checks all)
    let interfaceName: String?

    func toDictionary() -> [String: Any] {
        guard
            let data = try? JSONEncoder().encode(self),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [:]
        }

        return dict
    }
}

// MARK: - VPNDetectorOutput

/// Output model for VPN detection results
struct VPNDetectorOutput: ToolOutput {
    let isConnected: Bool
    let vpnType: String?
    let interfaceName: String?
    let ipAddress: String?
    let connectionStatus: String?
    let connectedDate: Date?
    let timestamp: Date

    // VPN Profile Data
    let serverAddress: String?
    let remoteIdentifier: String?
    let localIdentifier: String?
    let displayName: String?
    let hasCertificate: Bool
    let certificateInfo: String?

    func toFormattedString() -> String {
        var result = "VPN Connection Status:\n"
        result += "- Connected: \(isConnected ? "YES" : "NO")\n"

        if isConnected {
            if let status = connectionStatus {
                result += "- Status: \(status)\n"
            }
            if let type = vpnType {
                result += "- VPN Type: \(type)\n"
            }
            if let interface = interfaceName {
                result += "- Interface: \(interface)\n"
            }
            if let ip = ipAddress {
                result += "- IP Address: \(ip)\n"
            }
            if let connectedDate = connectedDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
                result += "- Connected Since: \(formatter.string(from: connectedDate))\n"
            }
        }

        // VPN Profile Data
        if let displayName = displayName {
            result += "\nVPN Profile Information:\n"
            result += "- Display Name: \(displayName)\n"
        }
        if let serverAddress = serverAddress {
            result += "- Server Address: \(serverAddress)\n"
        }
        if let remoteID = remoteIdentifier {
            result += "- Remote ID: \(remoteID)\n"
        }
        if let localID = localIdentifier {
            result += "- Local ID: \(localID)\n"
        }
        if hasCertificate {
            result += "- Certificate: Present\n"
            if let certInfo = certificateInfo {
                result += "- Certificate Info: \(certInfo)\n"
            }
        } else {
            result += "- Certificate: None\n"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        result += "\n- Checked at: \(formatter.string(from: timestamp))"

        return result
    }
}

// MARK: - VPNDetectorTool

/// Tool for detecting VPN connection status on macOS
struct VPNDetectorTool: AITool {
    // MARK: Internal

    let name = "vpn_detector"

    let description = """
    Detects if the system is currently connected to a VPN. \
    Use this tool when the user asks about VPN status, network connectivity issues, \
    or why their internet might not be working. \
    This tool can identify VPN connections and provide detailed connection information.
    """

    var parametersSchema: ToolParameterSchema {
        ToolParameterSchema([
            "type": "object",
            "properties": [
                "interface_name": [
                    "type": "string",
                    "description": "Optional: Specific network interface to check (e.g., 'utun0', 'ppp0'). If not provided, all interfaces will be checked.",
                ],
            ],
            "required": [],
        ])
    }

    func execute(arguments: [String: Any]) async throws -> String {
        Logger.tools("VPNDetectorTool.execute called with arguments: \(arguments)")

        // Parse input
        let interfaceName = arguments["interface_name"] as? String
        Logger.tools("VPNDetectorTool: interfaceName = \(interfaceName ?? "nil")")

        // Detect VPN
        Logger.tools("VPNDetectorTool: Starting VPN detection...")
        let output = try await detectVPN(interfaceName: interfaceName)
        Logger.tools("VPNDetectorTool: VPN detection completed - isConnected: \(output.isConnected)")

        // Return formatted string
        let result = output.toFormattedString()
        Logger.tools("VPNDetectorTool: Returning result: \(result.prefix(100))...")
        return result
    }

    // MARK: Private

    // MARK: - Private Detection Logic

    private func detectVPN(interfaceName: String? = nil) async throws -> VPNDetectorOutput {
        Logger.tools("VPNDetectorTool.detectVPN: Starting detection for interface: \(interfaceName ?? "all")")

        // Method 1: Check Personal VPN connections using NEVPNManager
        let personalVPNResult = await checkPersonalVPNConnections(interfaceName: interfaceName)
        if personalVPNResult.isConnected {
            Logger.tools("VPNDetectorTool.detectVPN: Found active Personal VPN connection")
            return personalVPNResult
        }

        // Method 2: Check Tunnel Provider VPN connections
        let tunnelVPNResult = await checkTunnelProviderConnections(interfaceName: interfaceName)
        if tunnelVPNResult.isConnected {
            Logger.tools("VPNDetectorTool.detectVPN: Found active Tunnel Provider VPN connection")
            return tunnelVPNResult
        }

        // Method 3: Fallback to interface-based detection for third-party VPNs
        let interfaceResult = checkVPNInterfaces(interfaceName: interfaceName)
        if interfaceResult.isConnected {
            Logger.tools("VPNDetectorTool.detectVPN: Found VPN interface (third-party VPN)")
            return interfaceResult
        }

        // Method 4: Check SystemConfiguration for VPN services
        let systemConfigResult = checkSystemConfigurationVPN(interfaceName: interfaceName)
        if systemConfigResult.isConnected {
            Logger.tools("VPNDetectorTool.detectVPN: Found VPN via SystemConfiguration")
            return systemConfigResult
        }

        // No VPN connection found
        let result = VPNDetectorOutput(
            isConnected: false,
            vpnType: nil,
            interfaceName: nil,
            ipAddress: nil,
            connectionStatus: "Disconnected",
            connectedDate: nil,
            timestamp: Date(),
            serverAddress: nil,
            remoteIdentifier: nil,
            localIdentifier: nil,
            displayName: nil,
            hasCertificate: false,
            certificateInfo: nil
        )

        Logger.tools("VPNDetectorTool.detectVPN: No VPN connection found")
        return result
    }

    // MARK: - VPN Detection Methods

    /// Check Personal VPN connections using NEVPNManager
    private func checkPersonalVPNConnections(interfaceName: String?) async -> VPNDetectorOutput {
        Logger.tools("VPNDetectorTool.checkPersonalVPNConnections: Checking Personal VPN connections")

        return await withCheckedContinuation { continuation in
            NEVPNManager.shared().loadFromPreferences { error in
                if let error = error {
                    Logger
                        .tools(
                            "VPNDetectorTool.checkPersonalVPNConnections: Error loading VPN preferences: \(error.localizedDescription)"
                        )
                    continuation.resume(returning: VPNDetectorOutput(
                        isConnected: false,
                        vpnType: nil,
                        interfaceName: nil,
                        ipAddress: nil,
                        connectionStatus: "Error loading preferences",
                        connectedDate: nil,
                        timestamp: Date(),
                        serverAddress: nil,
                        remoteIdentifier: nil,
                        localIdentifier: nil,
                        displayName: nil,
                        hasCertificate: false,
                        certificateInfo: nil
                    ))
                    return
                }

                let connection = NEVPNManager.shared().connection
                let status = connection.status
                let isConnected = (status == .connected)

                Logger
                    .tools(
                        "VPNDetectorTool.checkPersonalVPNConnections: VPN status: \(status.rawValue) (\(self.statusToString(status))), connected: \(isConnected)"
                    )

                // Additional check: if status is connected, verify there's actually a VPN interface with IP
                if isConnected {
                    let vpnInterfaces = self.getVPNInterfaces()
                    let hasValidInterface = vpnInterfaces.contains { interface in
                        if let ip = self.getIPAddress(for: interface), !ip.isEmpty {
                            Logger
                                .tools(
                                    "VPNDetectorTool.checkPersonalVPNConnections: Found VPN interface \(interface) with IP \(ip)"
                                )
                            return true
                        }
                        return false
                    }

                    if !hasValidInterface {
                        Logger
                            .tools(
                                "VPNDetectorTool.checkPersonalVPNConnections: Status says connected but no VPN interface with IP found"
                            )
                        // Override the status - if there's no interface with IP, it's not really connected
                        let correctedResult = VPNDetectorOutput(
                            isConnected: false,
                            vpnType: nil,
                            interfaceName: nil,
                            ipAddress: nil,
                            connectionStatus: "Status mismatch - no VPN interface",
                            connectedDate: nil,
                            timestamp: Date(),
                            serverAddress: nil,
                            remoteIdentifier: nil,
                            localIdentifier: nil,
                            displayName: nil,
                            hasCertificate: false,
                            certificateInfo: nil
                        )
                        continuation.resume(returning: correctedResult)
                        return
                    }
                }

                var vpnType: String?
                var detectedInterface: String?
                var ipAddress: String?
                var connectionStatus: String?
                var connectedDate: Date?

                // VPN Profile Data
                var serverAddress: String?
                var remoteIdentifier: String?
                var localIdentifier: String?
                var displayName: String?
                var hasCertificate = false
                var certificateInfo: String?

                // Extract VPN profile data from manager
                let manager = NEVPNManager.shared()
                displayName = manager.localizedDescription

                if let vpnProtocol = manager.protocolConfiguration {
                    serverAddress = vpnProtocol.serverAddress

                    // Check for certificate/identity
                    if vpnProtocol.identityReference != nil || vpnProtocol.identityData != nil {
                        hasCertificate = true
                        certificateInfo = "Certificate-based authentication configured"
                    }

                    // Extract protocol-specific data
                    if let ikev2Protocol = vpnProtocol as? NEVPNProtocolIKEv2 {
                        vpnType = "IKEv2"
                        remoteIdentifier = ikev2Protocol.remoteIdentifier
                        localIdentifier = ikev2Protocol.localIdentifier
                    } else if let ipsecProtocol = vpnProtocol as? NEVPNProtocolIPSec {
                        vpnType = "IPSec"
                        remoteIdentifier = ipsecProtocol.remoteIdentifier
                        localIdentifier = ipsecProtocol.localIdentifier
                    } else {
                        vpnType = "Personal VPN"
                    }
                }

                if isConnected {
                    connectionStatus = "Connected"
                    connectedDate = connection.connectedDate

                    // Get interface and IP information
                    if let interface = interfaceName {
                        detectedInterface = interface
                        ipAddress = self.getIPAddress(for: interface)
                    } else {
                        // Find the VPN interface
                        let vpnInterfaces = self.getVPNInterfaces()
                        if let firstInterface = vpnInterfaces.first {
                            detectedInterface = firstInterface
                            ipAddress = self.getIPAddress(for: firstInterface)
                        }
                    }
                } else {
                    connectionStatus = self.statusToString(status)
                }

                let result = VPNDetectorOutput(
                    isConnected: isConnected,
                    vpnType: vpnType,
                    interfaceName: detectedInterface,
                    ipAddress: ipAddress,
                    connectionStatus: connectionStatus,
                    connectedDate: connectedDate,
                    timestamp: Date(),
                    serverAddress: serverAddress,
                    remoteIdentifier: remoteIdentifier,
                    localIdentifier: localIdentifier,
                    displayName: displayName,
                    hasCertificate: hasCertificate,
                    certificateInfo: certificateInfo
                )

                continuation.resume(returning: result)
            }
        }
    }

    /// Check Tunnel Provider VPN connections
    private func checkTunnelProviderConnections(interfaceName: String?) async -> VPNDetectorOutput {
        Logger.tools("VPNDetectorTool.checkTunnelProviderConnections: Checking Tunnel Provider connections")

        // Load all tunnel provider managers
        return await withCheckedContinuation { continuation in
            NETunnelProviderManager.loadAllFromPreferences { managers, error in
                if let error = error {
                    Logger
                        .tools(
                            "VPNDetectorTool.checkTunnelProviderConnections: Error loading tunnel providers: \(error.localizedDescription)"
                        )
                    continuation.resume(returning: VPNDetectorOutput(
                        isConnected: false,
                        vpnType: nil,
                        interfaceName: nil,
                        ipAddress: nil,
                        connectionStatus: "Error loading tunnel providers",
                        connectedDate: nil,
                        timestamp: Date(),
                        serverAddress: nil,
                        remoteIdentifier: nil,
                        localIdentifier: nil,
                        displayName: nil,
                        hasCertificate: false,
                        certificateInfo: nil
                    ))
                    return
                }

                var isConnected = false
                var vpnType: String?
                var detectedInterface: String?
                var ipAddress: String?
                var connectionStatus: String?
                var connectedDate: Date?

                for manager in managers ?? [] {
                    let connection = manager.connection
                    let status = connection.status

                    Logger
                        .tools(
                            "VPNDetectorTool.checkTunnelProviderConnections: Tunnel provider status: \(status.rawValue) (\(self.statusToString(status)))"
                        )

                    if status == .connected {
                        // Verify there's actually a VPN interface with IP
                        let vpnInterfaces = self.getVPNInterfaces()
                        let hasValidInterface = vpnInterfaces.contains { interface in
                            if let ip = self.getIPAddress(for: interface), !ip.isEmpty {
                                Logger
                                    .tools(
                                        "VPNDetectorTool.checkTunnelProviderConnections: Found VPN interface \(interface) with IP \(ip)"
                                    )
                                return true
                            }
                            return false
                        }

                        if hasValidInterface {
                            isConnected = true
                            connectionStatus = "Connected"
                            connectedDate = connection.connectedDate
                            vpnType = "Tunnel Provider"

                            // Get interface and IP information
                            if let interface = interfaceName {
                                detectedInterface = interface
                                ipAddress = self.getIPAddress(for: interface)
                            } else {
                                if let firstInterface = vpnInterfaces.first {
                                    detectedInterface = firstInterface
                                    ipAddress = self.getIPAddress(for: firstInterface)
                                }
                            }
                            break
                        } else {
                            Logger
                                .tools(
                                    "VPNDetectorTool.checkTunnelProviderConnections: Status says connected but no VPN interface with IP found"
                                )
                        }
                    }
                }

                if !isConnected {
                    connectionStatus = "No active tunnel connections"
                }

                let result = VPNDetectorOutput(
                    isConnected: isConnected,
                    vpnType: vpnType,
                    interfaceName: detectedInterface,
                    ipAddress: ipAddress,
                    connectionStatus: connectionStatus,
                    connectedDate: connectedDate,
                    timestamp: Date(),
                    serverAddress: nil, // Tunnel providers don't expose this data
                    remoteIdentifier: nil,
                    localIdentifier: nil,
                    displayName: nil,
                    hasCertificate: false,
                    certificateInfo: nil
                )

                continuation.resume(returning: result)
            }
        }
    }

    /// Check VPN interfaces (fallback for third-party VPNs)
    private func checkVPNInterfaces(interfaceName: String?) -> VPNDetectorOutput {
        Logger.tools("VPNDetectorTool.checkVPNInterfaces: Checking VPN interfaces")

        let vpnInterfaces = getVPNInterfaces()
        Logger
            .tools("VPNDetectorTool.checkVPNInterfaces: Found \(vpnInterfaces.count) VPN interfaces: \(vpnInterfaces)")

        var isConnected = false
        var vpnType: String?
        var detectedInterface: String?
        var ipAddress: String?

        // Check if any VPN interface actually has an IP address (indicating real connection)
        let interfacesToCheck = interfaceName != nil ? [interfaceName!] : vpnInterfaces

        for interface in interfacesToCheck {
            if vpnInterfaces.contains(interface) {
                // Only consider it connected if it has an IP address
                if let ip = getIPAddress(for: interface), !ip.isEmpty {
                    isConnected = true
                    detectedInterface = interface
                    vpnType = determineVPNType(from: interface)
                    ipAddress = ip
                    Logger
                        .tools(
                            "VPNDetectorTool.checkVPNInterfaces: Found connected VPN interface \(interface) with IP \(ip)"
                        )
                    break
                } else {
                    Logger
                        .tools(
                            "VPNDetectorTool.checkVPNInterfaces: Interface \(interface) exists but has no IP address"
                        )
                }
            }
        }

        return VPNDetectorOutput(
            isConnected: isConnected,
            vpnType: vpnType,
            interfaceName: detectedInterface,
            ipAddress: ipAddress,
            connectionStatus: isConnected ? "Interface Active" : "No VPN Interface",
            connectedDate: nil,
            timestamp: Date(),
            serverAddress: nil, // Interface-based detection doesn't provide this
            remoteIdentifier: nil,
            localIdentifier: nil,
            displayName: nil,
            hasCertificate: false,
            certificateInfo: nil
        )
    }

    /// Get list of active VPN-related network interfaces
    private func getVPNInterfaces() -> [String] {
        var interfaces = [String]()

        // Common VPN interface prefixes
        let vpnPrefixes = ["utun", "ppp", "tap", "tun", "ipsec"]

        // Get all network interfaces
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return interfaces
        }

        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee else {
                continue
            }

            let name = String(cString: interface.ifa_name)

            // Check if interface name matches VPN patterns
            for prefix in vpnPrefixes {
                if name.hasPrefix(prefix), !interfaces.contains(name) {
                    // Check if interface is up and running
                    let flags = Int32(interface.ifa_flags)
                    if (flags & IFF_UP) != 0, (flags & IFF_RUNNING) != 0 {
                        interfaces.append(name)
                    }
                }
            }
        }

        return interfaces
    }

    /// Convert NEVPNStatus to string
    private func statusToString(_ status: NEVPNStatus) -> String {
        switch status {
        case .invalid:
            return "Invalid"
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .reasserting:
            return "Reasserting"
        case .disconnecting:
            return "Disconnecting"
        @unknown default:
            return "Unknown"
        }
    }

    /// Determine VPN type based on interface name
    private func determineVPNType(from interfaceName: String) -> String {
        if interfaceName.hasPrefix("utun") {
            return "IKEv2/IPSec or OpenVPN (utun)"
        } else if interfaceName.hasPrefix("ppp") {
            return "PPTP or L2TP (ppp)"
        } else if interfaceName.hasPrefix("tap") || interfaceName.hasPrefix("tun") {
            return "OpenVPN (tap/tun)"
        } else if interfaceName.hasPrefix("ipsec") {
            return "IPSec"
        }
        return "Unknown VPN Type"
    }

    /// Get IP address for a specific interface
    private func getIPAddress(for interfaceName: String) -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }

        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee else {
                continue
            }

            let name = String(cString: interface.ifa_name)

            if name == interfaceName {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if
                    let addr = interface.ifa_addr,
                    addr.pointee.sa_family == UInt8(AF_INET)
                {
                    getnameinfo(
                        addr,
                        socklen_t(addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    )
                    address = String(cString: hostname)
                    break
                }
            }
        }

        return address
    }

    /// Check VPN status using SystemConfiguration framework
    /// This method may fail if app is sandboxed without proper entitlements
    private func checkSystemConfigurationVPN(interfaceName: String?) -> VPNDetectorOutput {
        Logger.tools("VPNDetectorTool.checkSystemConfigurationVPN: Checking SystemConfiguration VPN services")

        // Note: This requires access to SystemConfiguration which may be restricted in sandbox
        // The app should be running with proper entitlements or without strict sandbox

        // Try to create preferences - will fail if sandboxed
        guard let prefs = SCPreferencesCreate(nil, "VPNDetector" as CFString, nil) else {
            // Sandbox restriction - return false and rely on interface detection
            Logger
                .tools(
                    "VPNDetectorTool.checkSystemConfigurationVPN: Cannot access SystemConfiguration (sandbox restriction)"
                )
            return VPNDetectorOutput(
                isConnected: false,
                vpnType: nil,
                interfaceName: nil,
                ipAddress: nil,
                connectionStatus: "Sandbox restriction",
                connectedDate: nil,
                timestamp: Date(),
                serverAddress: nil,
                remoteIdentifier: nil,
                localIdentifier: nil,
                displayName: nil,
                hasCertificate: false,
                certificateInfo: nil
            )
        }
        guard let services = SCPreferencesGetValue(prefs, "NetworkServices" as CFString) as? NSDictionary else {
            Logger.tools("VPNDetectorTool.checkSystemConfigurationVPN: Cannot read network services")
            return VPNDetectorOutput(
                isConnected: false,
                vpnType: nil,
                interfaceName: nil,
                ipAddress: nil,
                connectionStatus: "Cannot read network services",
                connectedDate: nil,
                timestamp: Date(),
                serverAddress: nil,
                remoteIdentifier: nil,
                localIdentifier: nil,
                displayName: nil,
                hasCertificate: false,
                certificateInfo: nil
            )
        }

        for (_, value) in services {
            if
                let service = value as? NSDictionary,
                let serviceType = service["Type"] as? String,
                serviceType == "VPN"
            {
                // Check if this VPN service is active
                if let serviceID = service["ServiceID"] as? String {
                    guard let dynamicStore = SCDynamicStoreCreate(nil, "VPNDetector" as CFString, nil, nil) else {
                        continue
                    }

                    let key = "State:/Network/Service/\(serviceID)/IPv4" as CFString
                    if let _ = SCDynamicStoreCopyValue(dynamicStore, key) {
                        Logger
                            .tools(
                                "VPNDetectorTool.checkSystemConfigurationVPN: Found active VPN service: \(serviceID)"
                            )

                        // Get interface and IP information
                        var detectedInterface: String?
                        var ipAddress: String?

                        if let interface = interfaceName {
                            detectedInterface = interface
                            ipAddress = getIPAddress(for: interface)
                        } else {
                            let vpnInterfaces = getVPNInterfaces()
                            if let firstInterface = vpnInterfaces.first {
                                detectedInterface = firstInterface
                                ipAddress = getIPAddress(for: firstInterface)
                            }
                        }

                        return VPNDetectorOutput(
                            isConnected: true,
                            vpnType: "System VPN",
                            interfaceName: detectedInterface,
                            ipAddress: ipAddress,
                            connectionStatus: "Connected via SystemConfiguration",
                            connectedDate: nil,
                            timestamp: Date(),
                            serverAddress: nil, // SystemConfiguration doesn't expose this
                            remoteIdentifier: nil,
                            localIdentifier: nil,
                            displayName: nil,
                            hasCertificate: false,
                            certificateInfo: nil
                        )
                    }
                }
            }
        }

        return VPNDetectorOutput(
            isConnected: false,
            vpnType: nil,
            interfaceName: nil,
            ipAddress: nil,
            connectionStatus: "No active VPN services",
            connectedDate: nil,
            timestamp: Date(),
            serverAddress: nil,
            remoteIdentifier: nil,
            localIdentifier: nil,
            displayName: nil,
            hasCertificate: false,
            certificateInfo: nil
        )
    }
}
