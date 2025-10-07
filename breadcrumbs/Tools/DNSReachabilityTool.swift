//
//  DNSReachabilityTool.swift
//  breadcrumbs
//
//  DNS reachability tool for checking domain connectivity and DNS resolution
//

import AsyncDNSResolver
import Foundation

// MARK: - DNSReachabilityInput

/// Input model for DNS reachability checks
struct DNSReachabilityInput: ToolInput, Codable {
    enum CodingKeys: String, CodingKey {
        case domain
        case recordType = "record_type"
        case dnsServer = "dns_server"
        case timeout
    }

    /// Domain name to check (e.g., "google.com", "outlook.com")
    let domain: String

    /// Optional: DNS record type to check (default: A record)
    let recordType: String?

    /// Optional: DNS server to use for the query (default: system DNS)
    let dnsServer: String?

    /// Optional: Timeout in seconds (default: 5.0)
    let timeout: Double?

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

// MARK: - DNSRecord

/// DNS record information
struct DNSRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case value
        case ttl
    }

    let type: String
    let value: String
    let ttl: Int32?
}

// MARK: - DNSReachabilityOutput

/// Output model for DNS reachability results
struct DNSReachabilityOutput: ToolOutput {
    let domain: String
    let isReachable: Bool
    let dnsRecords: [DNSRecord]
    let errorMessage: String?
    let responseTime: TimeInterval?
    let dnsServer: String?
    let timestamp: Date

    func toFormattedString() -> String {
        var result = "DNS Reachability Check for \(domain):\n"
        result += "- Reachable: \(isReachable ? "YES" : "NO")\n"

        if let responseTime = responseTime {
            result += "- Response Time: \(String(format: "%.3f", responseTime))s\n"
        }

        if let dnsServer = dnsServer {
            result += "- DNS Server: \(dnsServer)\n"
        }

        if !dnsRecords.isEmpty {
            result += "- DNS Records Found (\(dnsRecords.count)):\n"
            for record in dnsRecords {
                result += "  • \(record.type): \(record.value)"
                if let ttl = record.ttl {
                    result += " (TTL: \(ttl)s)"
                }
                result += "\n"
            }
        }

        if let errorMessage = errorMessage {
            result += "- Error: \(errorMessage)\n"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        result += "- Checked at: \(formatter.string(from: timestamp))"

        return result
    }
}

// MARK: - DNSReachabilityTool

/// Tool for checking DNS reachability and domain connectivity
struct DNSReachabilityTool: AITool {
    // MARK: Internal

    let name = "dns_reachability"

    let description = """
    Checks if a domain is reachable via DNS resolution. \
    Use this tool when users report connectivity issues, can't reach specific websites, \
    or when troubleshooting network problems. \
    This tool can help diagnose DNS issues, VPN connectivity problems, \
    or general internet connectivity issues. \
    Examples: "I can't reach google.com", "Is outlook.com down?", "My VPN isn't working"
    """

    var parametersSchema: ToolParameterSchema {
        ToolParameterSchema([
            "type": "object",
            "properties": [
                "domain": [
                    "type": "string",
                    "description": "Domain name to check (e.g., 'google.com', 'outlook.com', 'apple.com')",
                ],
                "record_type": [
                    "type": "string",
                    "description": "DNS record type to query (A, AAAA). Default: A",
                    "enum": ["A", "AAAA"],
                ],
                "dns_server": [
                    "type": "string",
                    "description": "Optional: Specific DNS server to use (e.g., '8.8.8.8', '1.1.1.1'). Default: system DNS",
                ],
                "timeout": [
                    "type": "number",
                    "description": "Timeout in seconds for DNS query. Default: 5.0",
                    "minimum": 1.0,
                    "maximum": 30.0,
                ],
            ],
            "required": ["domain"],
        ])
    }

    func execute(arguments: [String: Any]) async throws -> String {
        Logger.tools("DNSReachabilityTool.execute called with arguments: \(arguments)")

        // Parse input
        guard let domain = arguments["domain"] as? String, !domain.isEmpty else {
            throw ToolError.invalidArguments("Domain is required and cannot be empty")
        }

        let recordType = arguments["record_type"] as? String ?? "A"
        let dnsServer = arguments["dns_server"] as? String
        let timeout = arguments["timeout"] as? Double ?? 5.0

        Logger
            .tools(
                "DNSReachabilityTool: domain=\(domain), recordType=\(recordType), dnsServer=\(dnsServer ?? "system"), timeout=\(timeout)"
            )

        // Perform DNS check
        Logger.tools("DNSReachabilityTool: Starting DNS reachability check...")
        let output = try await checkDNSReachability(
            domain: domain,
            recordType: recordType,
            dnsServer: dnsServer,
            timeout: timeout
        )
        Logger.tools("DNSReachabilityTool: DNS check completed - isReachable: \(output.isReachable)")

        // Return formatted string
        let result = output.toFormattedString()
        Logger.tools("DNSReachabilityTool: Returning result: \(result.prefix(100))...")
        return result
    }

    // MARK: Private

    // MARK: - Private DNS Logic

    private func checkDNSReachability(
        domain: String,
        recordType: String,
        dnsServer: String?,
        timeout: Double
    ) async throws
        -> DNSReachabilityOutput
    {
        Logger.tools("DNSReachabilityTool.checkDNSReachability: Starting check for \(domain)")

        let startTime = Date()
        var dnsRecords = [DNSRecord]()
        var errorMessage: String?
        var isReachable = false

        do {
            // Create DNS resolver
            let resolver = try AsyncDNSResolver()

            // Perform DNS query based on record type
            switch recordType.uppercased() {
            case "A":
                let aRecords = try await resolver.queryA(name: domain)
                dnsRecords = aRecords.map { record in
                    DNSRecord(type: "A", value: record.address.description, ttl: record.ttl)
                }
                isReachable = !aRecords.isEmpty

            case "AAAA":
                let aaaaRecords = try await resolver.queryAAAA(name: domain)
                dnsRecords = aaaaRecords.map { record in
                    DNSRecord(type: "AAAA", value: record.address.description, ttl: record.ttl)
                }
                isReachable = !aaaaRecords.isEmpty

            default:
                // Default to A record for unknown types
                let aRecords = try await resolver.queryA(name: domain)
                dnsRecords = aRecords.map { record in
                    DNSRecord(type: "A", value: record.address.description, ttl: record.ttl)
                }
                isReachable = !aRecords.isEmpty
            }

            Logger
                .tools(
                    "DNSReachabilityTool.checkDNSReachability: Found \(dnsRecords.count) \(recordType) records for \(domain)"
                )

        } catch {
            Logger
                .tools(
                    "DNSReachabilityTool.checkDNSReachability: DNS query failed for \(domain): \(error.localizedDescription)"
                )
            errorMessage = error.localizedDescription
            isReachable = false
        }

        let responseTime = Date().timeIntervalSince(startTime)

        let result = DNSReachabilityOutput(
            domain: domain,
            isReachable: isReachable,
            dnsRecords: dnsRecords,
            errorMessage: errorMessage,
            responseTime: responseTime,
            dnsServer: dnsServer,
            timestamp: Date()
        )

        Logger
            .tools(
                "DNSReachabilityTool.checkDNSReachability: DNS check completed for \(domain) - reachable: \(isReachable), records: \(dnsRecords.count), time: \(String(format: "%.3f", responseTime))s"
            )
        return result
    }
}
