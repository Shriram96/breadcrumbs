# GitHub Workflows

This directory contains a single, streamlined CI workflow for the Breadcrumbs project.

## Workflow

### 🚀 CI (`ci.yml`)
Simple CI workflow that mirrors the development machine setup:

- **Build**: Uses `swift build` (same as dev machine)
- **Test**: Uses `swift test --enable-code-coverage` (same as dev machine)
- **Coverage**: Generates and uploads coverage reports to Codecov
- **Lint**: Runs SwiftLint for code quality
- **Format**: Checks code formatting with SwiftFormat

## Workflow Triggers

### Automatic Triggers
- **Push to main/develop**: CI runs automatically
- **Pull requests to main/develop**: CI runs automatically

## What It Does

1. **Checkout code** from the repository
2. **Setup Swift 5.9** (matches development environment)
3. **Cache dependencies** for faster builds
4. **Build the package** using Swift Package Manager
5. **Run tests with coverage** collection
6. **Generate coverage report** in LCOV format
7. **Upload coverage** to Codecov
8. **Run SwiftLint** for code quality checks
9. **Check formatting** with SwiftFormat

## Requirements

### Secrets
- `GITHUB_TOKEN`: Automatically provided by GitHub

## Usage

The workflow runs automatically on:
1. **Push to main/develop branches**
2. **Pull requests to main/develop branches**

No manual intervention required - it mirrors your local development workflow.

## Troubleshooting

### Common Issues
- **Swift version**: Uses Swift 5.9 (matches .swift-version file)
- **Coverage upload**: Automatically uploads to Codecov
- **Linting**: Uses project's .swiftlint.yml configuration
- **Formatting**: Uses project's .swiftformat configuration

### Workflow Status
Check the "Actions" tab in GitHub to see workflow status and logs.