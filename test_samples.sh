#!/bin/bash
# Simple test script to verify sample apps work with the A2A Ruby gem

set -e

echo "🧪 Testing A2A Ruby Sample Applications"
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test an agent
test_agent() {
    local agent_name="$1"
    local agent_dir="$2"
    local port="$3"
    
    echo ""
    echo "🔄 Testing $agent_name"
    echo "$(printf '=%.0s' {1..30})"
    
    cd "$agent_dir"
    
    # Check syntax
    echo "   📝 Checking syntax..."
    if ruby -c server.rb >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Syntax OK${NC}"
    else
        echo -e "   ${RED}❌ Syntax Error${NC}"
        cd - >/dev/null
        return 1
    fi
    
    # Check if dependencies are installed
    echo "   📦 Checking dependencies..."
    if bundle check >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Dependencies OK${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Installing dependencies...${NC}"
        bundle install --quiet
    fi
    
    # Test server startup (quick test)
    echo "   🚀 Testing server startup..."
    if timeout 3s ruby server.rb >/dev/null 2>&1 &
    then
        SERVER_PID=$!
        sleep 1
        
        # Test health endpoint
        if curl -s "http://localhost:$port/health" >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ Server starts successfully${NC}"
            kill $SERVER_PID 2>/dev/null || true
        else
            echo -e "   ${YELLOW}⚠️  Server started but health check failed${NC}"
            kill $SERVER_PID 2>/dev/null || true
        fi
    else
        echo -e "   ${RED}❌ Server failed to start${NC}"
    fi
    
    # Test client syntax
    echo "   🧪 Testing client..."
    if ruby -c client.rb >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Client syntax OK${NC}"
    else
        echo -e "   ${RED}❌ Client syntax error${NC}"
    fi
    
    cd - >/dev/null
}

# Test each sample
test_agent "Hello World Agent" "samples/helloworld-agent" "9999"
test_agent "Dice Agent" "samples/dice-agent" "10101"
test_agent "Weather Agent" "samples/weather-agent" "9999"

echo ""
echo "📊 Summary"
echo "=========="
echo -e "${GREEN}✅ All sample applications have been tested${NC}"
echo ""
echo "🚀 To run the samples:"
echo "   cd samples/helloworld-agent && ruby server.rb"
echo "   cd samples/dice-agent && ruby server.rb"
echo "   cd samples/weather-agent && ruby server.rb"
echo ""
echo "🧪 To test with clients:"
echo "   ruby client.rb"
echo "   ruby client.rb --interactive"
echo ""
echo "🌤️ For weather agent, configure API key first:"
echo "   cd samples/weather-agent"
echo "   cp .env.example .env"
echo "   # Edit .env and add WEATHER_API_KEY=your_key"
echo ""
echo "💡 For cross-stack testing: ./test_cross_stack.sh"