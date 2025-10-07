# 🛠 Setup & Installation Guide

This guide provides comprehensive instructions for setting up and installing Breadcrumbs on your macOS system.

## 📋 Prerequisites

### System Requirements

- **macOS**: 15.0 (Sequoia) or later
- **Architecture**: Intel x64 or Apple Silicon (M1/M2/M3)
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Storage**: 100MB available space
- **Network**: Internet connection for OpenAI API access

### Development Requirements

- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later
- **Command Line Tools**: Latest version
- **Git**: For version control

### API Requirements

- **OpenAI API Key**: Required for AI functionality
  - Visit [OpenAI Platform](https://platform.openai.com/api-keys)
  - Create account and generate API key
  - Ensure sufficient API credits

## 🚀 Installation Methods

### Method 1: Download Pre-built Release (Recommended)

1. **Download the Latest Release**:
   - Go to the [Releases page](https://github.com/yourusername/breadcrumbs/releases)
   - Download the latest `.dmg` file
   - File will be named `Breadcrumbs-v1.0.0.dmg`

2. **Install the Application**:
   ```bash
   # Mount the DMG file
   open Breadcrumbs-v1.0.0.dmg
   
   # Drag Breadcrumbs to Applications folder
   # Or use command line:
   cp -R /Volumes/Breadcrumbs/Breadcrumbs.app /Applications/
   ```

3. **Launch the Application**:
   ```bash
   # From Applications folder
   open /Applications/Breadcrumbs.app
   
   # Or from Spotlight
   # Press Cmd+Space, type "Breadcrumbs", press Enter
   ```

### Method 2: Build from Source

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/breadcrumbs.git
   cd breadcrumbs
   ```

2. **Open in Xcode**:
   ```bash
   open breadcrumbs.xcodeproj
   ```

3. **Configure Build Settings**:
   - Select the `breadcrumbs` target
   - Go to Build Settings
   - Ensure deployment target is set to macOS 15.0+

4. **Build and Run**:
   - Select your target device (Mac)
   - Press `Cmd+R` to build and run
   - Or use Product → Run from the menu

### Method 3: Command Line Build

1. **Build Using xcodebuild**:
   ```bash
   # Build the project
   xcodebuild -project breadcrumbs.xcodeproj \
              -scheme breadcrumbs \
              -configuration Release \
              -derivedDataPath ./build
   
   # The built app will be in ./build/Build/Products/Release/
   ```

2. **Install the Built App**:
   ```bash
   # Copy to Applications
   cp -R ./build/Build/Products/Release/breadcrumbs.app /Applications/
   ```

## ⚙️ Initial Configuration

### 1. First Launch Setup

When you first launch Breadcrumbs, you'll see the welcome screen:

1. **Click "Setup OpenAI API Key"**
2. **Enter your API key** in the secure field
3. **Enable Touch ID/Face ID** (recommended)
4. **Click "Save"**

### 2. API Key Configuration

#### Getting an OpenAI API Key

1. **Visit OpenAI Platform**:
   - Go to [platform.openai.com](https://platform.openai.com)
   - Sign up or log in to your account

2. **Create API Key**:
   - Navigate to API Keys section
   - Click "Create new secret key"
   - Copy the key (starts with `sk-`)
   - **Important**: Save the key securely - you won't be able to see it again

3. **Configure in Breadcrumbs**:
   - Open Settings (gear icon)
   - Go to API Key tab
   - Paste your API key
   - Enable biometric protection
   - Click "Save"

#### API Key Security

- **Biometric Protection**: Enable Touch ID/Face ID for secure access
- **Keychain Storage**: Keys are stored in macOS Keychain
- **No Network Transmission**: Keys are never sent over the network except to OpenAI
- **Local Processing**: All diagnostic operations run locally

### 3. Server Configuration (Optional)

If you want to enable remote API access:

1. **Open Settings** → Server tab
2. **Configure Port** (default: 8181)
3. **Generate API Key** for remote access
4. **Start Server** when needed

## 🔧 Advanced Configuration

### Environment Variables

For development or server deployment:

```bash
# Set OpenAI API key as environment variable
export OPENAI_API_KEY="sk-your-api-key-here"

# Set server port
export BREADCRUMBS_PORT="8181"

# Set log level
export BREADCRUMBS_LOG_LEVEL="debug"
```

### Configuration Files

Breadcrumbs stores configuration in:

- **API Keys**: macOS Keychain (`com.breadcrumbs.systemdiagnostics`)
- **User Preferences**: `~/Library/Preferences/com.breadcrumbs.systemdiagnostics.plist`
- **Logs**: Console.app (search for "breadcrumbs")

### Custom Tool Configuration

To add custom diagnostic tools:

1. **Create Tool Implementation**:
   ```swift
   struct MyCustomTool: AITool {
       let name = "my_custom_tool"
       let description = "My custom diagnostic tool"
       
       var parametersSchema: ToolParameterSchema {
           ToolParameterSchema([
               "type": "object",
               "properties": [
                   "parameter": [
                       "type": "string",
                       "description": "Parameter description"
                   ]
               ]
           ])
       }
       
       func execute(arguments: [String: Any]) async throws -> String {
           // Implementation
           return "Tool result"
       }
   }
   ```

2. **Register in ToolRegistry**:
   ```swift
   // In ToolRegistry.swift
   private func registerDefaultTools() {
       register(MyCustomTool())
       // ... other tools
   }
   ```

## 🚨 Troubleshooting

### Common Issues

#### 1. App Won't Launch

**Symptoms**: App crashes on launch or shows error dialog

**Solutions**:
```bash
# Check system requirements
sw_vers

# Verify app signature
codesign -dv --verbose=4 /Applications/Breadcrumbs.app

# Check Console for errors
log show --predicate 'process == "Breadcrumbs"' --last 1h
```

#### 2. API Key Issues

**Symptoms**: "API key is missing" or authentication errors

**Solutions**:
- Verify API key is correct and starts with `sk-`
- Check API key has sufficient credits
- Ensure internet connection is working
- Try regenerating API key in OpenAI dashboard

#### 3. VPN Detection Not Working

**Symptoms**: VPN status shows as disconnected when it should be connected

**Solutions**:
- Check app has necessary permissions
- Verify VPN is actually connected
- Try different VPN types (IKEv2 vs OpenVPN)
- Check Console for permission errors

#### 4. Server Won't Start

**Symptoms**: HTTP server fails to start or shows port conflicts

**Solutions**:
```bash
# Check if port is in use
lsof -i :8181

# Try different port
# Change port in Settings → Server tab

# Check firewall settings
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

#### 5. Biometric Authentication Issues

**Symptoms**: Touch ID/Face ID not working or not available

**Solutions**:
- Ensure biometric authentication is enabled in System Preferences
- Check if biometrics are enrolled
- Try using password fallback
- Restart the app

### Debug Mode

Enable debug logging for troubleshooting:

1. **Open Terminal**
2. **Set environment variable**:
   ```bash
   export BREADCRUMBS_LOG_LEVEL="debug"
   ```
3. **Launch app from Terminal**:
   ```bash
   /Applications/Breadcrumbs.app/Contents/MacOS/Breadcrumbs
   ```

### Log Analysis

View detailed logs:

```bash
# View recent logs
log show --predicate 'process == "Breadcrumbs"' --last 1h

# View specific category
log show --predicate 'process == "Breadcrumbs" AND category == "tools"' --last 1h

# Export logs to file
log show --predicate 'process == "Breadcrumbs"' --last 1h > breadcrumbs.log
```

## 🔒 Security Configuration

### App Permissions

Breadcrumbs requires the following permissions:

1. **Network Access**: For OpenAI API calls and HTTP server
2. **System Configuration**: For VPN and network diagnostics
3. **File System Access**: For reading diagnostic reports
4. **Biometric Authentication**: For secure keychain access

### Sandbox Configuration

For development, the app runs without sandbox to access system diagnostics:

```xml
<!-- In breadcrumbs.entitlements -->
<key>com.apple.security.app-sandbox</key>
<false/>
```

For App Store distribution, specific entitlements would be required:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

### Firewall Configuration

If using the HTTP server:

1. **System Preferences** → Security & Privacy → Firewall
2. **Click "Firewall Options"**
3. **Add Breadcrumbs** to allowed applications
4. **Enable "Allow incoming connections"**

## 🧪 Testing Installation

### Verify Installation

1. **Launch Breadcrumbs**
2. **Check API Key Configuration**:
   - Settings → API Key tab
   - Verify key is stored securely

3. **Test Basic Functionality**:
   ```
   User: "Hello, can you help me with system diagnostics?"
   Expected: AI responds and offers to help
   ```

4. **Test VPN Detection**:
   ```
   User: "Is my VPN connected?"
   Expected: Tool executes and returns VPN status
   ```

5. **Test Network Diagnostics**:
   ```
   User: "Can you check if google.com is reachable?"
   Expected: DNS tool executes and returns connectivity status
   ```

### Performance Testing

```bash
# Test app launch time
time /Applications/Breadcrumbs.app/Contents/MacOS/Breadcrumbs

# Test memory usage
ps aux | grep Breadcrumbs

# Test CPU usage during tool execution
top -pid $(pgrep Breadcrumbs)
```

## 🔄 Updates and Maintenance

### Automatic Updates

Currently, Breadcrumbs doesn't support automatic updates. To update:

1. **Download latest release**
2. **Replace existing app** in Applications folder
3. **Restart the application**

### Data Backup

Breadcrumbs doesn't store user data, but you may want to backup:

- **API Keys**: Stored in Keychain (backed up with Time Machine)
- **Configuration**: User preferences (backed up with Time Machine)
- **Logs**: Console logs (optional backup)

### Uninstallation

To completely remove Breadcrumbs:

```bash
# Remove application
rm -rf /Applications/Breadcrumbs.app

# Remove preferences (optional)
rm ~/Library/Preferences/com.breadcrumbs.systemdiagnostics.plist

# Remove keychain items (optional)
# Use Keychain Access app to manually remove items
```

## 📞 Support

If you encounter issues during setup:

1. **Check this guide** for common solutions
2. **View Console logs** for error details
3. **Create GitHub issue** with:
   - macOS version
   - Error messages
   - Steps to reproduce
   - Console log excerpts

4. **Join Discussions** for community support

---

This setup guide should help you get Breadcrumbs running smoothly on your macOS system. For additional help, refer to the other documentation files or create an issue on GitHub.
