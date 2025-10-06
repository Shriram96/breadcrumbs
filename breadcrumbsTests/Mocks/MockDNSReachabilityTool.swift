//
//  MockDNSReachabilityTool.swift
//  breadcrumbsTests
//
//  Mock implementation of DNS reachability tool for testing
//

import Foundation
@testable import breadcrumbs

/// Mock implementation of DNS reachability tool for testing
struct MockDNSReachabilityTool: AITool {
    
    let name = "dns_reachability"
    
    let description = "Mock DNS reachability tool for testing"
    
    var parametersSchema: ToolParameterSchema {
        ToolParameterSchema([
            "type": "object",
            "properties": [
                "domain": [
                    "type": "string",
                    "description": "Domain name to check"
                ],
                "record_type": [
                    "type": "string",
                    "description": "DNS record type to query"
                ],
                "dns_server": [
                    "type": "string",
                    "description": "DNS server to use"
                ],
                "timeout": [
                    "type": "number",
                    "description": "Timeout in seconds"
                ]
            ],
            "required": ["domain"]
        ])
    }
    
    // Mock behavior configuration
    var shouldSucceed: Bool = true
    var mockRecords: [DNSRecord] = []
    var mockError: String? = nil
    var mockResponseTime: TimeInterval = 0.1
    
    func execute(arguments: [String: Any]) async throws -> String {
        guard let domain = arguments["domain"] as? String, !domain.isEmpty else {
            throw ToolError.invalidArguments("Domain is required and cannot be empty")
        }
        
        let recordType = arguments["record_type"] as? String ?? "A"
        let dnsServer = arguments["dns_server"] as? String
        let timeout = arguments["timeout"] as? Double ?? 5.0
        
        if shouldSucceed {
            let records = mockRecords.isEmpty ? [
                DNSRecord(type: recordType, value: "1.2.3.4", ttl: 300)
            ] : mockRecords
            
            let output = DNSReachabilityOutput(
                domain: domain,
                isReachable: true,
                dnsRecords: records,
                errorMessage: nil,
                responseTime: mockResponseTime,
                dnsServer: dnsServer,
                timestamp: Date()
            )
            
            return output.toFormattedString()
        } else {
            let output = DNSReachabilityOutput(
                domain: domain,
                isReachable: false,
                dnsRecords: [],
                errorMessage: mockError ?? "Mock DNS error",
                responseTime: mockResponseTime,
                dnsServer: dnsServer,
                timestamp: Date()
            )
            
            return output.toFormattedString()
        }
    }
}
