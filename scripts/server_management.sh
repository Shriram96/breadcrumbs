#!/bin/bash

# Breadcrumbs Server Management Script
# Provides easy commands for managing the breadcrumbs HTTP server

set -e

# Configuration
PLIST_NAME="com.breadcrumbs.server"
PLIST_PATH="/Library/LaunchDaemons/${PLIST_NAME}.plist"
APP_PATH="/Applications/breadcrumbs.app"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

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

# Check if running as root for system-wide operations
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This operation requires root privileges. Please run with sudo."
        exit 1
    fi
}

# Check if app exists
check_app() {
    if [[ ! -d "$APP_PATH" ]]; then
        log_error "Breadcrumbs app not found at $APP_PATH"
        log_info "Please build and install the app first"
        exit 1
    fi
}

# Install launch daemon
install_daemon() {
    log_info "Installing breadcrumbs server as launch daemon..."
    check_root
    check_app
    
    # Copy plist file
    cp "$PROJECT_DIR/launchd/${PLIST_NAME}.plist" "$PLIST_PATH"
    
    # Set proper permissions
    chown root:wheel "$PLIST_PATH"
    chmod 644 "$PLIST_PATH"
    
    # Load the daemon
    launchctl load "$PLIST_PATH"
    
    log_success "Launch daemon installed and loaded"
    log_info "Server should be running on http://localhost:8181"
}

# Uninstall launch daemon
uninstall_daemon() {
    log_info "Uninstalling breadcrumbs server daemon..."
    check_root
    
    # Unload the daemon
    if [[ -f "$PLIST_PATH" ]]; then
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
        rm -f "$PLIST_PATH"
        log_success "Launch daemon uninstalled"
    else
        log_warning "Launch daemon not found"
    fi
}

# Start server manually
start_server() {
    log_info "Starting breadcrumbs server manually..."
    check_app
    
    # Check if server is already running
    if curl -s http://localhost:8181/api/v1/health > /dev/null 2>&1; then
        log_warning "Server appears to be already running on port 8181"
        return 0
    fi
    
    # Start server in background
    nohup "$APP_PATH/Contents/MacOS/breadcrumbs" --server-mode --port 8181 > /tmp/breadcrumbs-server.log 2>&1 &
    SERVER_PID=$!
    
    # Wait a moment and check if it started
    sleep 2
    if kill -0 $SERVER_PID 2>/dev/null; then
        log_success "Server started with PID $SERVER_PID"
        log_info "Logs: /tmp/breadcrumbs-server.log"
        log_info "API: http://localhost:8181/api/v1"
    else
        log_error "Failed to start server"
        log_info "Check logs: /tmp/breadcrumbs-server.log"
        exit 1
    fi
}

# Stop server
stop_server() {
    log_info "Stopping breadcrumbs server..."
    
    # Try to stop via launchctl first
    if [[ -f "$PLIST_PATH" ]]; then
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
    fi
    
    # Kill any running processes
    pkill -f "breadcrumbs.*server-mode" 2>/dev/null || true
    
    # Wait a moment
    sleep 1
    
    # Check if still running
    if curl -s http://localhost:8181/api/v1/health > /dev/null 2>&1; then
        log_warning "Server may still be running"
    else
        log_success "Server stopped"
    fi
}

# Check server status
status() {
    log_info "Checking breadcrumbs server status..."
    
    # Check launch daemon status
    if [[ -f "$PLIST_PATH" ]]; then
        if launchctl list | grep -q "$PLIST_NAME"; then
            log_success "Launch daemon is loaded"
        else
            log_warning "Launch daemon plist exists but not loaded"
        fi
    else
        log_info "No launch daemon installed"
    fi
    
    # Check if server is responding
    if curl -s http://localhost:8181/api/v1/health > /dev/null 2>&1; then
        log_success "Server is responding on http://localhost:8181"
        
        # Get health info
        HEALTH_RESPONSE=$(curl -s http://localhost:8181/api/v1/health 2>/dev/null || echo "{}")
        if [[ "$HEALTH_RESPONSE" != "{}" ]]; then
            echo "Health status:"
            echo "$HEALTH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_RESPONSE"
        fi
    else
        log_warning "Server is not responding on port 8181"
    fi
    
    # Check for running processes
    if pgrep -f "breadcrumbs.*server-mode" > /dev/null; then
        log_info "Breadcrumbs server processes found:"
        pgrep -f "breadcrumbs.*server-mode" | while read pid; do
            echo "  PID $pid: $(ps -p $pid -o command= 2>/dev/null || echo 'Unknown')"
        done
    else
        log_info "No breadcrumbs server processes found"
    fi
}

# Test the API
test_api() {
    log_info "Testing breadcrumbs API..."
    
    if ! curl -s http://localhost:8181/api/v1/health > /dev/null 2>&1; then
        log_error "Server is not running. Start it first with: $0 start"
        exit 1
    fi
    
    log_info "Running API tests..."
    
    # Test health endpoint
    echo "1. Health check:"
    curl -s http://localhost:8181/api/v1/health | python3 -m json.tool 2>/dev/null || echo "Failed"
    
    echo -e "\n2. Tools list:"
    curl -s http://localhost:8181/api/v1/tools | python3 -m json.tool 2>/dev/null || echo "Failed"
    
    echo -e "\n3. Chat test (VPN detection):"
    curl -s -X POST http://localhost:8181/api/v1/chat \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer demo-key-123" \
        -d '{"message": "Check my VPN status", "tools_enabled": true}' | \
        python3 -m json.tool 2>/dev/null || echo "Failed"
    
    log_success "API tests completed"
}

# Show logs
logs() {
    log_info "Showing server logs..."
    
    if [[ -f "/tmp/breadcrumbs-server.log" ]]; then
        tail -f /tmp/breadcrumbs-server.log
    else
        log_warning "No log file found at /tmp/breadcrumbs-server.log"
        log_info "Try starting the server first"
    fi
}

# Show help
show_help() {
    echo "Breadcrumbs Server Management"
    echo "============================"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  install     Install as system launch daemon (requires sudo)"
    echo "  uninstall   Remove system launch daemon (requires sudo)"
    echo "  start       Start server manually"
    echo "  stop        Stop server"
    echo "  restart     Restart server"
    echo "  status      Check server status"
    echo "  test        Test API endpoints"
    echo "  logs        Show server logs"
    echo "  help        Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 install    # Install as system service"
    echo "  $0 start      # Start manually for testing"
    echo "  $0 test       # Test the API"
    echo "  $0 status     # Check if running"
}

# Main script logic
case "${1:-help}" in
    install)
        install_daemon
        ;;
    uninstall)
        uninstall_daemon
        ;;
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server
        sleep 2
        start_server
        ;;
    status)
        status
        ;;
    test)
        test_api
        ;;
    logs)
        logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

