#!/bin/bash

# Setup script for Vapor HTTP server integration
# This script helps set up the Vapor dependencies and build the server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log_info "Setting up Vapor HTTP server for breadcrumbs..."

# Check if we're in the right directory
if [[ ! -f "$PROJECT_DIR/Package.swift" ]]; then
    log_error "Package.swift not found. Please run this script from the project root."
    exit 1
fi

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    log_error "Swift is not installed or not in PATH"
    exit 1
fi

log_info "Swift version: $(swift --version)"

# Check if Xcode is available (for macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v xcodebuild &> /dev/null; then
        log_warning "Xcode command line tools not found. Some features may not work."
    else
        log_info "Xcode version: $(xcodebuild -version | head -n1)"
    fi
fi

# Resolve dependencies
log_info "Resolving Swift package dependencies..."
cd "$PROJECT_DIR"

if swift package resolve; then
    log_success "Dependencies resolved successfully"
else
    log_error "Failed to resolve dependencies"
    exit 1
fi

# Build the project
log_info "Building breadcrumbs server..."
if swift build; then
    log_success "Build completed successfully"
else
    log_error "Build failed"
    exit 1
fi

# Check if the executable was created
if [[ -f "$PROJECT_DIR/.build/debug/breadcrumbs-server" ]]; then
    log_success "Executable created: .build/debug/breadcrumbs-server"
else
    log_warning "Executable not found. This might be expected if building for Xcode."
fi

# Test the server (optional)
if [[ "${1:-}" == "--test" ]]; then
    log_info "Testing server startup..."
    
    # Start server in background
    timeout 5s "$PROJECT_DIR/.build/debug/breadcrumbs-server" --port 8081 --api-key test-key &
    SERVER_PID=$!
    
    # Wait a moment for server to start
    sleep 2
    
    # Test health endpoint
    if curl -s http://localhost:8081/api/v1/health > /dev/null; then
        log_success "Server test passed - health endpoint responding"
    else
        log_warning "Server test failed - health endpoint not responding"
    fi
    
    # Kill the test server
    kill $SERVER_PID 2>/dev/null || true
fi

log_success "Vapor setup completed!"
log_info ""
log_info "Next steps:"
log_info "1. Open the project in Xcode"
log_info "2. Add Vapor as a dependency in Xcode (File > Add Package Dependencies)"
log_info "3. Use the server management script: ./scripts/server_management.sh start"
log_info "4. Test the API: ./scripts/server_management.sh test"
log_info ""
log_info "For more information, see RMI_README.md"







