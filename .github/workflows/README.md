# GitHub Workflows

This directory contains GitHub Actions workflows for the Breadcrumbs project.

## Workflows

### 🚀 CI (`ci.yml`)
Main CI orchestrator that determines which workflows should run based on file changes.

### 🔨 Swift Build and Test (`swift.yml`)
- Builds the Swift package using `swift build`
- Runs unit tests with code coverage
- Performs linting with SwiftLint
- Checks code formatting
- Uploads coverage reports to Codecov

### 📱 Xcode Build and Test (`xcode.yml`)
- Builds the macOS app using Xcode
- Runs unit tests with code coverage
- Runs UI tests
- Creates app archives
- Exports app for distribution
- Uploads coverage reports to Codecov

### 🔒 Security Scan (`security.yml`)
- Performs security audits on dependencies
- Scans for hardcoded secrets using TruffleHog
- Runs CodeQL analysis for security vulnerabilities
- Reviews dependencies for security issues
- Runs weekly on schedule

### 🚀 Release (`release.yml`)
- Triggers on version tags (e.g., `v1.0.0`)
- Builds release version of the app
- Creates DMG for distribution
- Creates GitHub releases with assets
- Can be triggered manually with workflow_dispatch

## Workflow Triggers

### Automatic Triggers
- **Push to main/develop**: All workflows run
- **Pull requests to main/develop**: All workflows run
- **Version tags**: Release workflow runs
- **Weekly schedule**: Security scan runs

### Manual Triggers
- **Release workflow**: Can be triggered manually with a version input

## Requirements

### Secrets
- `GITHUB_TOKEN`: Automatically provided by GitHub

### Files
- `ExportOptions.plist`: Required for Xcode export functionality

## Coverage Reports

Code coverage is collected and uploaded to Codecov for both:
- Swift Package Manager tests
- Xcode tests

## Security

The security workflow includes:
- Dependency vulnerability scanning
- Secret detection
- CodeQL static analysis
- Dependency license checking

## Usage

1. **Development**: Workflows run automatically on push/PR
2. **Release**: Create a version tag (e.g., `v1.0.0`) to trigger release
3. **Manual Release**: Use the "Actions" tab to manually trigger a release

## Troubleshooting

### Common Issues
- **Xcode version**: Workflows use Xcode 15.0, update if needed
- **Coverage upload**: Ensure Codecov integration is set up
- **Export options**: Verify `ExportOptions.plist` exists and is valid

### Workflow Status
Check the "Actions" tab in GitHub to see workflow status and logs.
