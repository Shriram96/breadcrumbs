//
//  VPNDetectorTool.swift
//  breadcrumbs
//
//  System diagnostic tool for detecting VPN connection status
//

import Foundation
import Network
import SystemConfiguration

// MARK: - Input/Output Models

/// Input model for VPN detection
struct VPNDetectorInput: ToolInput, Codable {
    /// Optional: specific interface to check (if nil, checks all)
    let interfaceName: String?

    enum CodingKeys: String, CodingKey {
        case interfaceName = "interface_name"
    }

    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}

/// Output model for VPN detection results
struct VPNDetectorOutput: ToolOutput {
    let isConnected: Bool
    let vpnType: String?
    let interfaceName: String?
    let ipAddress: String?
    let timestamp: Date

    func toFormattedString() -> String {
        var result = "VPN Connection Status:\n"
        result += "- Connected: \(isConnected ? "YES" : "NO")\n"

        if isConnected {
            if let type = vpnType {
                result += "- VPN Type: \(type)\n"
            }
            if let interface = interfaceName {
                result += "- Interface: \(interface)\n"
            }
            if let ip = ipAddress {
                result += "- IP Address: \(ip)\n"
            }
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        result += "- Checked at: \(formatter.string(from: timestamp))"

        return result
    }
}

// MARK: - VPN Detector Tool

/// Tool for detecting VPN connection status on macOS
struct VPNDetectorTool: AITool {

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
                    "description": "Optional: Specific network interface to check (e.g., 'utun0', 'ppp0'). If not provided, all interfaces will be checked."
                ]
            ],
            "required": []
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

    // MARK: - Private Detection Logic

    private func detectVPN(interfaceName: String? = nil) async throws -> VPNDetectorOutput {
        Logger.tools("VPNDetectorTool.detectVPN: Starting detection for interface: \(interfaceName ?? "all")")
        
        var isConnected = false
        var vpnType: String?
        var detectedInterface: String?
        var ipAddress: String?

        // Method 1: Check for VPN interfaces (utun, ppp, tap, tun)
        let vpnInterfaces = getVPNInterfaces()
        Logger.tools("VPNDetectorTool.detectVPN: Found \(vpnInterfaces.count) VPN interfaces: \(vpnInterfaces)")

        if let specificInterface = interfaceName {
            // Check specific interface
            if vpnInterfaces.contains(specificInterface) {
                isConnected = true
                detectedInterface = specificInterface
                vpnType = determineVPNType(from: specificInterface)
                ipAddress = getIPAddress(for: specificInterface)
            }
        } else {
            // Check all VPN interfaces
            if let firstVPNInterface = vpnInterfaces.first {
                isConnected = true
                detectedInterface = firstVPNInterface
                vpnType = determineVPNType(from: firstVPNInterface)
                ipAddress = getIPAddress(for: firstVPNInterface)
            }
        }

        // Method 2: Check SystemConfiguration for VPN services
        if !isConnected {
            isConnected = checkSystemConfigurationVPN()
            Logger.tools("VPNDetectorTool.detectVPN: SystemConfiguration check result: \(isConnected)")
        }

        let result = VPNDetectorOutput(
            isConnected: isConnected,
            vpnType: vpnType,
            interfaceName: detectedInterface,
            ipAddress: ipAddress,
            timestamp: Date()
        )
        
        Logger.tools("VPNDetectorTool.detectVPN: Final result - isConnected: \(result.isConnected), type: \(result.vpnType ?? "nil"), interface: \(result.interfaceName ?? "nil")")
        return result
    }

    /// Get list of active VPN-related network interfaces
    private func getVPNInterfaces() -> [String] {
        var interfaces: [String] = []

        // Common VPN interface prefixes
        let vpnPrefixes = ["utun", "ppp", "tap", "tun", "ipsec"]

        // Get all network interfaces
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return interfaces }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)

            // Check if interface name matches VPN patterns
            for prefix in vpnPrefixes {
                if name.hasPrefix(prefix) && !interfaces.contains(name) {
                    // Check if interface is up and running
                    let flags = Int32(interface.ifa_flags)
                    if (flags & IFF_UP) != 0 && (flags & IFF_RUNNING) != 0 {
                        interfaces.append(name)
                    }
                }
            }
        }

        return interfaces
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

        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)

            if name == interfaceName {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if let addr = interface.ifa_addr,
                   addr.pointee.sa_family == UInt8(AF_INET) {
                    getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                              &hostname, socklen_t(hostname.count),
                              nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostname)
                    break
                }
            }
        }

        return address
    }

    /// Check VPN status using SystemConfiguration framework
    /// This method may fail if app is sandboxed without proper entitlements
    private func checkSystemConfigurationVPN() -> Bool {
        // Note: This requires access to SystemConfiguration which may be restricted in sandbox
        // The app should be running with proper entitlements or without strict sandbox

        // Try to create preferences - will fail if sandboxed
        guard let prefs = SCPreferencesCreate(nil, "VPNDetector" as CFString, nil) else {
            // Sandbox restriction - return false and rely on interface detection
            print("VPNDetector: Cannot access SystemConfiguration (sandbox restriction)")
            return false
        }

        guard let services = SCPreferencesGetValue(prefs, "NetworkServices" as CFString) as? NSDictionary else {
            print("VPNDetector: Cannot read network services")
            return false
        }

        for (_, value) in services {
            if let service = value as? NSDictionary,
               let serviceType = service["Type"] as? String,
               serviceType == "VPN" {
                // Check if this VPN service is active
                if let serviceID = service["ServiceID"] as? String {
                    guard let dynamicStore = SCDynamicStoreCreate(nil, "VPNDetector" as CFString, nil, nil) else {
                        continue
                    }
                    let key = "State:/Network/Service/\(serviceID)/IPv4" as CFString
                    if let _ = SCDynamicStoreCopyValue(dynamicStore, key) {
                        return true
                    }
                }
            }
        }

        return false
    }
}
