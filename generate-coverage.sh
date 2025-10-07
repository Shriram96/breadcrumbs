#!/bin/bash

# Generate test coverage report for breadcrumbs project
# Usage: ./generate-coverage.sh

set -e

echo "🧪 Running tests with coverage..."
swift test --enable-code-coverage

echo "📊 Coverage data generated in .build/arm64-apple-macosx/debug/codecov/"

# List coverage files
echo "📁 Coverage files:"
ls -la .build/arm64-apple-macosx/debug/codecov/

echo ""
echo "✅ Coverage generation complete!"
echo "📈 To view coverage data, you can use:"
echo "   xcrun llvm-cov show .build/arm64-apple-macosx/debug/breadcrumbsPackageTests.xctest/Contents/MacOS/breadcrumbsPackageTests -instr-profile=.build/arm64-apple-macosx/debug/codecov/*.profraw"
echo ""
echo "📋 Or use Xcode's built-in coverage tools by opening the project in Xcode and running tests."
