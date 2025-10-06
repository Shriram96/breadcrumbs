# Permissions & Security

This document explains the permissions and security measures used by the System Diagnostics chatbot.

## Required Permissions

### 1. Network Access
**Why:** The app needs to communicate with OpenAI's API to provide AI-powered diagnostic assistance.

- **Entitlement:** `com.apple.security.network.client`
- **What it does:** Allows the app to make outgoing HTTPS connections
- **Data sent:** Your diagnostic questions and tool results (VPN status, etc.)
- **Data received:** AI-generated explanations and suggestions

### 2. System Configuration Access
**Why:** To detect VPN connections and analyze network configuration.

- **Entitlement:** App Sandbox disabled (or temporary exceptions)
- **What it does:** Reads network interface information and system preferences
- **Data accessed:**
  - Network interface names (utun0, ppp0, etc.)
  - VPN connection status
  - IP addresses of network interfaces
- **Data NOT accessed:** Your VPN credentials, passwords, or browsing history

## Security Measures

### API Key Storage
Your OpenAI API key is stored securely using **macOS Keychain**:
- ✅ Encrypted by macOS
- ✅ Protected by system-level security
- ✅ Only accessible by this app
- ✅ Never transmitted except to OpenAI API
- ✅ Survives app updates (unless you delete it)
- ✅ Deleted when you click "Clear" in Settings

### Data Privacy
- **Local Processing:** VPN detection runs entirely on your Mac
- **No Tracking:** The app doesn't collect analytics or telemetry
- **No Cloud Storage:** Chat history is not stored (currently)
- **Open Source:** You can review the code to verify security

### What Gets Sent to OpenAI
Only the following data leaves your device:
1. Your chat messages (diagnostic questions)
2. Tool results (e.g., "VPN Connected: YES, Type: IKEv2")
3. Your API key (for authentication)

**NOT sent:**
- Your VPN credentials
- Browsing history
- Personal files
- System passwords

## Sandbox Status

Currently, the app runs **without App Sandbox** to enable full system diagnostic capabilities.

### Why Sandbox is Disabled
The VPN detection tool needs to:
- Read network interface information via `getifaddrs()`
- Access SystemConfiguration framework
- Query network service preferences

These operations are restricted in the App Sandbox.

### Alternative (More Restrictive)
If you prefer a sandboxed app, you can modify `breadcrumbs.entitlements` to:
1. Enable sandbox: `<key>com.apple.security.app-sandbox</key><true/>`
2. Add temporary exceptions (see commented section in file)
3. VPN detection will use interface-based method only (less accurate)

## Questions?

- **Can the app access my VPN password?** No, only connection status.
- **Is my API key safe?** Yes, it's stored in macOS Keychain with encryption.
- **Can I run this sandboxed?** Yes, but with reduced VPN detection accuracy.
- **Where is my data sent?** Only to OpenAI API (api.openai.com).

## Code Review
All security-critical code is available for review:
- **Keychain:** `breadcrumbs/Utilities/KeychainHelper.swift`
- **VPN Detection:** `breadcrumbs/Tools/VPNDetectorTool.swift`
- **Entitlements:** `breadcrumbs/breadcrumbs.entitlements`
