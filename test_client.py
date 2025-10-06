#!/usr/bin/env python3
"""
Breadcrumbs API Test Client

Simple Python client to test the breadcrumbs HTTP API.
This demonstrates how external systems can interact with the diagnostic server.
"""

import requests
import json
import sys
import time
import logging
from typing import Dict, Any, Optional

# Set up detailed logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class BreadcrumbsClient:
    """Client for interacting with the Breadcrumbs HTTP API"""
    
    def __init__(self, base_url: str = "http://localhost:8181", api_key: str = "demo-key-123"):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.session = requests.Session()
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {api_key}'
        })
    
    def health_check(self) -> Dict[str, Any]:
        """Check if the server is healthy"""
        url = f"{self.base_url}/api/v1/health"
        logger.info(f"🏥 Health check request to: {url}")
        logger.debug(f"📋 Headers: {dict(self.session.headers)}")
        
        try:
            logger.debug("🔄 Sending GET request...")
            response = self.session.get(url, timeout=10)
            logger.info(f"📊 Response status: {response.status_code}")
            logger.debug(f"📋 Response headers: {dict(response.headers)}")
            logger.debug(f"📤 Response content: {response.text}")
            
            response.raise_for_status()
            result = response.json()
            logger.info("✅ Health check successful")
            return result
        except requests.exceptions.RequestException as e:
            logger.error(f"❌ Health check failed: {e}")
            logger.error(f"❌ Error type: {type(e)}")
            return {"error": str(e), "status": "unhealthy"}
    
    def list_tools(self) -> Dict[str, Any]:
        """Get list of available diagnostic tools"""
        url = f"{self.base_url}/api/v1/tools"
        logger.info(f"🔧 Tools list request to: {url}")
        logger.debug(f"📋 Headers: {dict(self.session.headers)}")
        
        try:
            logger.debug("🔄 Sending GET request...")
            response = self.session.get(url, timeout=10)
            logger.info(f"📊 Response status: {response.status_code}")
            logger.debug(f"📋 Response headers: {dict(response.headers)}")
            logger.debug(f"📤 Response content: {response.text}")
            
            response.raise_for_status()
            result = response.json()
            logger.info("✅ Tools list successful")
            return result
        except requests.exceptions.RequestException as e:
            logger.error(f"❌ Tools list failed: {e}")
            logger.error(f"❌ Error type: {type(e)}")
            return {"error": str(e)}
    
    def send_message(self, message: str, conversation_id: Optional[str] = None, tools_enabled: bool = True) -> Dict[str, Any]:
        """Send a diagnostic message to the AI"""
        url = f"{self.base_url}/api/v1/chat"
        payload = {
            "message": message,
            "tools_enabled": tools_enabled
        }
        
        if conversation_id:
            payload["conversation_id"] = conversation_id
        
        logger.info(f"💬 Chat request to: {url}")
        logger.debug(f"📋 Headers: {dict(self.session.headers)}")
        logger.debug(f"📤 Payload: {json.dumps(payload, indent=2)}")
        
        try:
            logger.debug("🔄 Sending POST request...")
            response = self.session.post(url, json=payload, timeout=30)
            logger.info(f"📊 Response status: {response.status_code}")
            logger.debug(f"📋 Response headers: {dict(response.headers)}")
            logger.debug(f"📤 Response content: {response.text}")
            
            response.raise_for_status()
            result = response.json()
            logger.info("✅ Chat request successful")
            return result
        except requests.exceptions.RequestException as e:
            logger.error(f"❌ Chat request failed: {e}")
            logger.error(f"❌ Error type: {type(e)}")
            return {"error": str(e)}
    
    def test_vpn_detection(self) -> Dict[str, Any]:
        """Test VPN detection specifically"""
        return self.send_message("Check my VPN status and provide detailed information")
    
    def test_network_diagnostics(self) -> Dict[str, Any]:
        """Test general network diagnostics"""
        return self.send_message("Run network diagnostics and check connectivity issues")

def print_response(title: str, response: Dict[str, Any]):
    """Pretty print API responses"""
    print(f"\n{'='*60}")
    print(f"{title}")
    print(f"{'='*60}")
    print(json.dumps(response, indent=2, default=str))

def main(client: BreadcrumbsClient = None):
    """Main test function"""
    print("Breadcrumbs API Test Client")
    print("=" * 40)
    
    # Initialize client if not provided
    if client is None:
        client = BreadcrumbsClient()
    
    # Test 1: Health Check
    print("\n1. Testing Health Check...")
    health = client.health_check()
    print_response("Health Check Response", health)
    
    if "error" in health:
        print(f"\n❌ Server is not responding: {health['error']}")
        print("Make sure the breadcrumbs server is running on localhost:8181")
        sys.exit(1)
    
    # Test 2: List Available Tools
    print("\n2. Testing Tools List...")
    tools = client.list_tools()
    print_response("Available Tools", tools)
    
    # Test 3: VPN Detection
    print("\n3. Testing VPN Detection...")
    vpn_result = client.test_vpn_detection()
    print_response("VPN Detection Result", vpn_result)
    
    # Test 4: Network Diagnostics
    print("\n4. Testing Network Diagnostics...")
    network_result = client.test_network_diagnostics()
    print_response("Network Diagnostics Result", network_result)
    
    # Test 5: Interactive Mode
    print("\n5. Interactive Mode")
    print("Enter messages to send to the diagnostic AI (type 'quit' to exit):")
    
    conversation_id = None
    while True:
        try:
            message = input("\n> ").strip()
            if message.lower() in ['quit', 'exit', 'q']:
                break
            
            if not message:
                continue
            
            result = client.send_message(message, conversation_id=conversation_id)
            
            if "error" in result:
                print(f"❌ Error: {result['error']}")
            else:
                print(f"\n🤖 AI Response: {result.get('response', 'No response')}")
                if result.get('tools_used'):
                    print(f"🔧 Tools used: {', '.join(result['tools_used'])}")
                
                # Update conversation ID for context
                conversation_id = result.get('conversation_id')
        
        except KeyboardInterrupt:
            print("\n\nGoodbye!")
            break
        except Exception as e:
            print(f"❌ Error: {e}")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Breadcrumbs API Test Client')
    parser.add_argument('--host', default='localhost', help='Server host (default: localhost)')
    parser.add_argument('--port', type=int, default=8181, help='Server port (default: 8181)')
    parser.add_argument('--api-key', default='demo-key-123', help='API key (default: demo-key-123)')
    parser.add_argument('--message', help='Single message to send (skips interactive mode)')
    parser.add_argument('--tools', action='store_true', help='Enable tools for the message')
    parser.add_argument('--verbose', '-v', action='store_true', help='Enable verbose logging')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    else:
        logging.getLogger().setLevel(logging.INFO)
    
    # Initialize client with command line arguments
    base_url = f"http://{args.host}:{args.port}"
    client = BreadcrumbsClient(base_url=base_url, api_key=args.api_key)
    
    if args.message:
        # Single message mode
        print(f"Breadcrumbs API Test Client - Single Message Mode")
        print(f"Server: {base_url}")
        print(f"API Key: {args.api_key}")
        print(f"Message: {args.message}")
        print(f"Tools Enabled: {args.tools}")
        print("=" * 60)
        
        result = client.send_message(args.message, tools_enabled=args.tools)
        print_response("Response", result)
    else:
        # Full test mode
        main(client)

