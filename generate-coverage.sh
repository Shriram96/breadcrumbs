#!/bin/bash

# Generate test coverage report for breadcrumbs project
# Usage: ./generate-coverage.sh

set -e

echo "🧪 Running tests with coverage..."
swift test --enable-code-coverage

echo "📊 Coverage data generated"

# Find the profdata file
PROFDATA_FILE=$(find .build -name "*.profdata" | head -1)
if [ -z "$PROFDATA_FILE" ]; then
  echo "❌ No profdata file found. Listing .build directory:"
  find .build -type f -name "*.profdata" -o -name "*.profraw" | head -10
  exit 1
fi

echo "📁 Using profdata file: $PROFDATA_FILE"

# Generate LCOV coverage report
echo "📈 Generating LCOV coverage report..."
xcrun llvm-cov export -format=lcov -instr-profile="$PROFDATA_FILE" .build/debug/breadcrumbsPackageTests.xctest/Contents/MacOS/breadcrumbsPackageTests > coverage.lcov

# Verify coverage file was created
if [ -f coverage.lcov ]; then
  echo "✅ Coverage report generated successfully"
  echo "📊 Coverage file size: $(wc -l < coverage.lcov) lines"
  echo "📁 Coverage file: coverage.lcov"
else
  echo "❌ Failed to generate coverage report"
  exit 1
fi

echo ""
echo "✅ Coverage generation complete!"
echo "📈 To view coverage data, you can use:"
echo "   xcrun llvm-cov show .build/debug/breadcrumbsPackageTests.xctest/Contents/MacOS/breadcrumbsPackageTests -instr-profile=\"$PROFDATA_FILE\""
echo ""
echo "📋 Or use Xcode's built-in coverage tools by opening the project in Xcode and running tests."
echo "📊 Or upload coverage.lcov to Codecov or other coverage services."
