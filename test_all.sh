#!/bin/bash
# Test all A2A Ruby samples

set -e

echo "🧪 Testing All A2A Ruby Samples"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    local test_dir="$3"
    
    echo ""
    echo "🔄 Testing: $test_name"
    echo "$(printf '=%.0s' {1..50})"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ -n "$test_dir" ]; then
        cd "$test_dir"
    fi
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ $test_name: PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ $test_name: FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    if [ -n "$test_dir" ]; then
        cd - > /dev/null
    fi
}

# Test Hello World Agent
test_helloworld() {
    run_test "Hello World Agent - Unit Tests" \
             "bundle exec rspec" \
             "samples/helloworld-agent"
    
    # Integration test
    run_test "Hello World Agent - Integration Test" \
             "timeout 10s bash -c 'ruby server.rb &; sleep 3; ruby client.rb; kill %1'" \
             "samples/helloworld-agent"
}

# Test Dice Agent  
test_dice_agent() {
    run_test "Dice Agent - Unit Tests" \
             "bundle exec rspec" \
             "samples/dice-agent"
             
    # Integration test
    run_test "Dice Agent - Integration Test" \
             "timeout 10s bash -c 'ruby server.rb &; sleep 3; echo \"roll dice\" | ruby client.rb --interactive; kill %1'" \
             "samples/dice-agent"
}

# Test Weather Agent
test_weather_agent() {
    run_test "Weather Agent - Unit Tests" \
             "WEATHER_MOCK_MODE=true bundle exec rspec" \
             "samples/weather-agent"
             
    # Integration test with mock mode
    run_test "Weather Agent - Integration Test (Mock Mode)" \
             "timeout 10s bash -c 'WEATHER_MOCK_MODE=true ruby server.rb &; sleep 3; ruby client.rb; kill %1'" \
             "samples/weather-agent"
}

# Test cross-stack compatibility
test_cross_stack() {
    if [ -d "../a2a-samples" ] && command -v uv &> /dev/null; then
        run_test "Cross-Stack Compatibility" \
                 "./test_cross_stack.sh" \
                 "."
    else
        echo -e "${YELLOW}⚠️  Skipping cross-stack tests (Python samples or uv not available)${NC}"
    fi
}

# Test gem installation
test_gem_installation() {
    run_test "A2A Ruby Gem Installation" \
             "gem list a2a-ruby | grep -q a2a-ruby" \
             "."
}

# Main execution
main() {
    echo "Running comprehensive test suite for A2A Ruby samples..."
    echo ""
    
    # Check if setup has been run
    if ! gem list a2a-ruby | grep -q a2a-ruby; then
        echo "🔧 Running setup first..."
        ./setup.sh
    fi
    
    # Run all tests
    test_gem_installation
    test_helloworld
    test_dice_agent
    test_weather_agent
    test_cross_stack
    
    # Summary
    echo ""
    echo "📊 Test Summary"
    echo "==============="
    echo -e "Total Tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some tests failed${NC}"
        exit 1
    fi
}

# Handle Ctrl+C
trap 'echo -e "\n${YELLOW}🛑 Testing interrupted${NC}"; kill $(jobs -p) 2>/dev/null || true; exit 1' INT

# Run main function
main "$@"