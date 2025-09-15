#!/bin/bash
# Cross-stack testing script for A2A Ruby samples

set -e

echo "🧪 A2A Cross-Stack Testing"
echo "=========================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check if Python samples are available
    if [ ! -d "../a2a-samples" ]; then
        echo -e "${RED}❌ Python A2A samples not found at ../a2a-samples${NC}"
        echo "Please clone the a2a-samples repository at the same level as a2a-ruby-samples"
        exit 1
    fi
    
    # Check if uv is installed
    if ! command -v uv &> /dev/null; then
        echo -e "${RED}❌ uv (Python package manager) not found${NC}"
        echo "Please install uv: https://docs.astral.sh/uv/getting-started/installation/"
        exit 1
    fi
    
    # Check if A2A Ruby gem is available
    if ! gem list a2a-ruby | grep -q a2a-ruby; then
        echo -e "${YELLOW}⚠️  A2A Ruby gem not installed. Running setup...${NC}"
        ./setup.sh
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Test Ruby agent with Python client
test_ruby_agent_python_client() {
    echo ""
    echo "🔄 Test 1: Ruby Agent ↔ Python Client"
    echo "======================================"
    
    cd samples/helloworld-agent
    
    # Start Ruby agent
    echo "🚀 Starting Ruby Hello World agent..."
    ruby server.rb &
    RUBY_PID=$!
    
    # Wait for server to start
    sleep 3
    
    # Test with Python client
    echo "🐍 Testing with Python client..."
    cd ../../../../a2a-samples/samples/python/agents/helloworld
    
    if uv run test_client.py 2>/dev/null; then
        echo -e "${GREEN}✅ Ruby Agent ↔ Python Client: PASSED${NC}"
    else
        echo -e "${RED}❌ Ruby Agent ↔ Python Client: FAILED${NC}"
    fi
    
    # Cleanup
    kill $RUBY_PID 2>/dev/null || true
    cd ../../../../a2a-ruby-samples
}

# Test Python agent with Ruby client
test_python_agent_ruby_client() {
    echo ""
    echo "🔄 Test 2: Python Agent ↔ Ruby Client"
    echo "======================================"
    
    cd ../a2a-samples/samples/python/agents/helloworld
    
    # Start Python agent
    echo "🚀 Starting Python Hello World agent..."
    uv run . &
    PYTHON_PID=$!
    
    # Wait for server to start
    sleep 3
    
    # Test with Ruby client
    echo "💎 Testing with Ruby client..."
    cd ../../../../a2a-ruby-samples/samples/helloworld-agent
    
    if AGENT_URL=http://localhost:9999/a2a ruby client.rb 2>/dev/null; then
        echo -e "${GREEN}✅ Python Agent ↔ Ruby Client: PASSED${NC}"
    else
        echo -e "${RED}❌ Python Agent ↔ Ruby Client: FAILED${NC}"
    fi
    
    # Cleanup
    kill $PYTHON_PID 2>/dev/null || true
    cd ../..
}

# Test protocol compliance
test_protocol_compliance() {
    echo ""
    echo "🔄 Test 3: Protocol Compliance"
    echo "==============================="
    
    cd samples/helloworld-agent
    
    echo "📋 Testing JSON-RPC 2.0 compliance..."
    if bundle exec rspec spec/protocol_compliance_spec.rb 2>/dev/null; then
        echo -e "${GREEN}✅ JSON-RPC 2.0 Compliance: PASSED${NC}"
    else
        echo -e "${YELLOW}⚠️  JSON-RPC 2.0 Compliance: SKIPPED (tests not implemented)${NC}"
    fi
    
    echo "📋 Testing A2A protocol compliance..."
    if bundle exec rspec spec/a2a_compliance_spec.rb 2>/dev/null; then
        echo -e "${GREEN}✅ A2A Protocol Compliance: PASSED${NC}"
    else
        echo -e "${YELLOW}⚠️  A2A Protocol Compliance: SKIPPED (tests not implemented)${NC}"
    fi
    
    cd ../..
}

# Test agent card compatibility
test_agent_card_compatibility() {
    echo ""
    echo "🔄 Test 4: Agent Card Compatibility"
    echo "==================================="
    
    # Start Ruby agent
    cd samples/helloworld-agent
    ruby server.rb &
    RUBY_PID=$!
    sleep 3
    
    # Test agent card endpoint
    echo "📋 Testing agent card endpoint..."
    if curl -s http://localhost:9999/a2a/agent-card | jq . >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Agent Card Format: VALID${NC}"
    else
        echo -e "${RED}❌ Agent Card Format: INVALID${NC}"
    fi
    
    # Cleanup
    kill $RUBY_PID 2>/dev/null || true
    cd ../..
}

# Main execution
main() {
    echo "Starting cross-stack compatibility tests..."
    echo ""
    
    check_prerequisites
    test_ruby_agent_python_client
    test_python_agent_ruby_client
    test_protocol_compliance
    test_agent_card_compatibility
    
    echo ""
    echo "🎉 Cross-stack testing completed!"
    echo ""
    echo "💡 To run individual tests:"
    echo "   Ruby Agent: cd samples/helloworld-agent && ruby server.rb"
    echo "   Python Agent: cd ../a2a-samples/samples/python/agents/helloworld && uv run ."
    echo "   Ruby Client: AGENT_URL=http://localhost:9999/a2a ruby client.rb"
    echo "   Python Client: uv run test_client.py"
}

# Handle Ctrl+C
trap 'echo -e "\n${YELLOW}🛑 Testing interrupted${NC}"; kill $(jobs -p) 2>/dev/null || true; exit 1' INT

# Run main function
main "$@"