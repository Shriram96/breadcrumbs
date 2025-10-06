# Breadcrumbs Unit Tests

This directory contains comprehensive unit tests for the breadcrumbs app, following Apple's testing best practices and ensuring high code coverage.

## Test Structure

### Mocks/
- **MockAIModel.swift** - Mock implementation of AIModel for testing
- **MockAITool.swift** - Mock implementation of AITool and ToolRegistry for testing
- **MockKeychainHelper.swift** - Mock implementation of KeychainHelper for testing

### Models/
- **ChatMessageTests.swift** - Tests for ChatMessage and related data structures
- **ItemTests.swift** - Tests for Item SwiftData model
- **OpenAIModelTests.swift** - Tests for OpenAIModel implementation

### ViewModels/
- **ChatViewModelTests.swift** - Tests for ChatViewModel business logic

### Tools/
- **VPNDetectorToolTests.swift** - Tests for VPNDetectorTool functionality

### Utilities/
- **KeychainHelperTests.swift** - Tests for KeychainHelper security utilities
- **LoggerTests.swift** - Tests for Logger utility

### Protocols/
- **AIModelTests.swift** - Tests for AIModel protocol and related structures
- **AIToolTests.swift** - Tests for AITool protocol and related structures

### Integration/
- **AppIntegrationTests.swift** - End-to-end integration tests

### TestHelpers/
- **TestUtilities.swift** - Test utilities and helper functions

## Test Coverage

The test suite covers:

### ✅ Models and Data Structures
- ChatMessage creation, serialization, and validation
- Item SwiftData model persistence and operations
- ToolCall and ToolResult data structures
- MessageRole enum values and serialization

### ✅ Business Logic
- ChatViewModel message handling and state management
- Tool execution and error handling
- AI model integration and response processing
- Tool registry management

### ✅ Utilities and Helpers
- KeychainHelper secure storage operations
- Logger functionality across all categories
- Biometric authentication integration
- Error handling and edge cases

### ✅ AI Integration
- OpenAI model message conversion
- Tool calling and response handling
- Streaming and non-streaming responses
- Error scenarios and recovery

### ✅ System Tools
- VPN detection functionality
- Network interface analysis
- System configuration access
- Tool parameter validation

### ✅ Integration Testing
- End-to-end chat flow testing
- Component interaction validation
- Error recovery scenarios
- Performance and memory management

## Running Tests

### Command Line
```bash
# Run all tests
xcodebuild test -scheme breadcrumbs -destination 'platform=macOS'

# Run specific test class
xcodebuild test -scheme breadcrumbs -destination 'platform=macOS' -only-testing:breadcrumbsTests/ChatViewModelTests

# Run with coverage
xcodebuild test -scheme breadcrumbs -destination 'platform=macOS' -enableCodeCoverage YES
```

### Xcode
1. Open the project in Xcode
2. Select the breadcrumbs scheme
3. Press `Cmd+U` to run all tests
4. Use the Test Navigator to run specific tests

## Test Best Practices

### Mocking Strategy
- **MockAIModel**: Simulates AI model responses for predictable testing
- **MockAITool**: Provides controlled tool execution for testing
- **MockKeychainHelper**: Isolates keychain operations for unit testing

### Async Testing
- Uses `XCTestExpectation` for async operations
- Proper timeout handling for network operations
- Concurrent access testing for thread safety

### Error Testing
- Tests both success and failure scenarios
- Validates error messages and types
- Ensures proper error propagation

### Performance Testing
- Measures critical path performance
- Tests with large datasets
- Validates memory usage patterns

### Edge Cases
- Empty and nil value handling
- Special character and Unicode support
- Boundary condition testing
- Resource cleanup validation

## Test Data Management

### Cleanup
- Automatic cleanup in `setUp` and `tearDown` methods
- Test-specific data isolation
- Keychain and registry cleanup utilities

### Test Data Generation
- Random data generation for stress testing
- Consistent test data for reproducible results
- Mock data factories for complex objects

## Coverage Goals

- **Statements**: >90%
- **Branches**: >85%
- **Functions**: >95%
- **Lines**: >90%

## Continuous Integration

Tests are designed to run in CI environments:
- No external dependencies
- Deterministic results
- Fast execution
- Proper cleanup

## Debugging Tests

### Common Issues
1. **Async timeout**: Increase timeout values for slow operations
2. **Keychain access**: Ensure proper entitlements in test target
3. **Mock configuration**: Verify mock setup before assertions
4. **Memory leaks**: Use memory debugging tools for complex tests

### Debug Commands
```bash
# Run tests with verbose output
xcodebuild test -scheme breadcrumbs -destination 'platform=macOS' -verbose

# Run tests with specific configuration
xcodebuild test -scheme breadcrumbs -destination 'platform=macOS' -configuration Debug
```

## Contributing

When adding new tests:
1. Follow the existing naming conventions
2. Include both positive and negative test cases
3. Add appropriate mocks for external dependencies
4. Update this README with new test coverage
5. Ensure tests run in isolation
6. Add performance tests for critical paths
