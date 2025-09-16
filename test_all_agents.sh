#!/bin/bash

# A2A Ruby Samples - Complete Test Suite
# This script starts all three sample agents and tests all their endpoints

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[✓]${NC} $message"
            ((PASSED_TESTS++))
            ((TOTAL_TESTS++))
            ;;
        "FAIL")
            echo -e "${RED}[✗]${NC} $message"
            ((FAILED_TESTS++))
            ((TOTAL_TESTS++))
            ;;
        "WARN")
            echo -e "${YELLOW}[!]${NC} $message"
            ;;
    esac
}

# Function to test HTTP endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/response.json "$url")
    local status_code=${response: -3}
    
    if [ "$status_code" -eq "$expected_status" ]; then
        print_status "SUCCESS" "$name - HTTP $status_code"
        return 0
    else
        print_status "FAIL" "$name - Expected HTTP $expected_status, got $status_code"
        return 1
    fi
}

# Function to test JSON-RPC endpoint
test_jsonrpc() {
    local name=$1
    local url=$2
    local payload=$3
    local expect_error=${4:-false}  # New parameter to indicate if we expect an error
    
    # Capture the full response including logs
    local full_response=$(curl -s -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$payload" 2>&1)
    
    # Extract just the JSON part (last line that starts with { or [)
    local json_response=$(echo "$full_response" | grep -E '^[\{\[]' | tail -1)
    
    # If no JSON found, try to find it in the full response
    if [ -z "$json_response" ]; then
        # Look for JSON-like content in the response
        json_response=$(echo "$full_response" | sed -n 's/.*\(\{.*\}\).*/\1/p' | tail -1)
    fi
    
    # Save response for debugging
    echo "$json_response" > /tmp/last_response.json
    
    # Check if we have a valid JSON response
    if [ -z "$json_response" ]; then
        print_status "FAIL" "$name - No JSON response found"
        return 1
    fi
    
    # Check if response is valid JSON
    if ! echo "$json_response" | jq . > /dev/null 2>&1; then
        print_status "FAIL" "$name - Invalid JSON response"
        return 1
    fi
    
    # Check if response is an array (batch response)
    if echo "$json_response" | jq -e 'type == "array"' > /dev/null 2>&1; then
        # Handle batch response - check if all elements are valid JSON-RPC responses
        local batch_valid=true
        local batch_size=$(echo "$json_response" | jq 'length')
        
        for ((i=0; i<batch_size; i++)); do
            # Check if each element has either result or error, and jsonrpc field
            if ! echo "$json_response" | jq -e ".[$i].jsonrpc" > /dev/null 2>&1; then
                batch_valid=false
                break
            fi
            if ! echo "$json_response" | jq -e ".[$i].result or .[$i].error" > /dev/null 2>&1; then
                batch_valid=false
                break
            fi
        done
        
        if [ "$batch_valid" = true ]; then
            print_status "SUCCESS" "$name - JSON-RPC Batch Success ($batch_size responses)"
            return 0
        else
            print_status "FAIL" "$name - Invalid JSON-RPC batch response format"
            return 1
        fi
    # Check if response contains error (single response)
    elif echo "$json_response" | jq -e '.error' > /dev/null 2>&1; then
        local error_message=$(echo "$json_response" | jq -r '.error.message')
        if [ "$expect_error" = true ]; then
            print_status "SUCCESS" "$name - JSON-RPC Error (Expected): $error_message"
            return 0
        else
            print_status "FAIL" "$name - JSON-RPC Error: $error_message"
            return 1
        fi
    elif echo "$json_response" | jq -e '.result' > /dev/null 2>&1; then
        if [ "$expect_error" = true ]; then
            print_status "FAIL" "$name - Expected error but got success"
            return 1
        else
            print_status "SUCCESS" "$name - JSON-RPC Success"
            return 0
        fi
    elif echo "$json_response" | jq -e '.jsonrpc' > /dev/null 2>&1; then
        # Valid JSON-RPC response structure
        if [ "$expect_error" = true ]; then
            print_status "FAIL" "$name - Expected error but got success"
            return 1
        else
            print_status "SUCCESS" "$name - JSON-RPC Success"
            return 0
        fi
    else
        print_status "FAIL" "$name - Invalid JSON-RPC response format"
        return 1
    fi
}

# Function to wait for server to start
wait_for_server() {
    local port=$1
    local timeout=30
    local count=0
    
    while [ $count -lt $timeout ]; do
        if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
            return 0
        fi
        sleep 1
        ((count++))
    done
    return 1
}

# Function to stop all background processes
cleanup() {
    if [ "${CLEANUP_STARTED:-}" != "true" ]; then
        CLEANUP_STARTED=true
        print_status "INFO" "Cleaning up background processes..."
        local pids=$(jobs -p 2>/dev/null || true)
        if [ -n "$pids" ]; then
            echo "$pids" | xargs kill 2>/dev/null || true
            wait 2>/dev/null || true
        fi
    fi
}

# Set up cleanup on exit
trap cleanup EXIT

print_status "INFO" "Starting A2A Ruby Samples Test Suite"
print_status "INFO" "========================================"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    print_status "FAIL" "jq is required but not installed. Please install jq first."
    exit 1
fi

# Update bundles for all agents
print_status "INFO" "Updating bundles for all agents..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

for agent in helloworld-agent weather-agent dice-agent; do
    print_status "INFO" "Updating bundle for $agent..."
    (cd "samples/$agent" && bundle install --quiet)
done

# Start all three agents
print_status "INFO" "Starting all agents..."

# Hello World Agent - Port 9999
print_status "INFO" "Starting Hello World Agent on port 9999..."
(cd samples/helloworld-agent && PORT=9999 ruby server.rb) &
HELLO_PID=$!

# Weather Agent - Port 10000 (with mock mode for testing)
print_status "INFO" "Starting Weather Agent on port 10000..."
(cd samples/weather-agent && WEATHER_MOCK_MODE=true PORT=10000 ruby server.rb) &
WEATHER_PID=$!

# Dice Agent - Port 10001
print_status "INFO" "Starting Dice Agent on port 10001..."
(cd samples/dice-agent && PORT=10001 ruby server.rb) &
DICE_PID=$!

# Wait for all servers to start
print_status "INFO" "Waiting for servers to start..."

if wait_for_server 9999; then
    print_status "SUCCESS" "Hello World Agent started successfully"
else
    print_status "FAIL" "Hello World Agent failed to start"
fi

if wait_for_server 10000; then
    print_status "SUCCESS" "Weather Agent started successfully"
else
    print_status "FAIL" "Weather Agent failed to start"
fi

if wait_for_server 10001; then
    print_status "SUCCESS" "Dice Agent started successfully"
else
    print_status "FAIL" "Dice Agent failed to start"
fi

print_status "INFO" ""
print_status "INFO" "Testing All Endpoints"
print_status "INFO" "====================="

# Test Hello World Agent (Port 9999)
print_status "INFO" ""
print_status "INFO" "Testing Hello World Agent..."

test_endpoint "Hello World - Health Check" "http://localhost:9999/health"
test_endpoint "Hello World - Agent Card" "http://localhost:9999/a2a/agent-card"
test_endpoint "Hello World - Web Interface" "http://localhost:9999/"

# Test Hello World JSON-RPC methods
test_jsonrpc "Hello World - greet method" "http://localhost:9999/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"greet","params":{"name":"Test"},"id":1}'

test_jsonrpc "Hello World - message/send method" "http://localhost:9999/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"message/send","params":{"message":{"messageId":"test-123","role":"user","parts":[{"kind":"text","text":"Hello World!"}]}},"id":2}'

# Test Weather Agent (Port 10000)
print_status "INFO" ""
print_status "INFO" "Testing Weather Agent..."

test_endpoint "Weather - Health Check" "http://localhost:10000/health"
test_endpoint "Weather - Agent Card" "http://localhost:10000/a2a/agent-card"
test_endpoint "Weather - Web Interface" "http://localhost:10000/"

# Test Weather JSON-RPC methods
test_jsonrpc "Weather - get_current_weather method" "http://localhost:10000/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"get_current_weather","params":{"location":"London"},"id":3}'

test_jsonrpc "Weather - get_forecast method" "http://localhost:10000/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"get_forecast","params":{"location":"New York","days":3},"id":4}'

test_jsonrpc "Weather - get_weather_by_coordinates method" "http://localhost:10000/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"get_weather_by_coordinates","params":{"latitude":51.5074,"longitude":-0.1278},"id":5}'

test_jsonrpc "Weather - search_cities method" "http://localhost:10000/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"search_cities","params":{"query":"London"},"id":6}'

test_jsonrpc "Weather - message/send method" "http://localhost:10000/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"message/send","params":{"message":{"messageId":"test-456","role":"user","parts":[{"kind":"text","text":"What is the weather in Tokyo?"}]}},"id":7}'

# Test Dice Agent (Port 10001)
print_status "INFO" ""
print_status "INFO" "Testing Dice Agent..."

test_endpoint "Dice - Health Check" "http://localhost:10001/health"
test_endpoint "Dice - Agent Card" "http://localhost:10001/a2a/agent-card"
test_endpoint "Dice - Web Interface" "http://localhost:10001/"

# Test Dice JSON-RPC methods
test_jsonrpc "Dice - roll_dice method" "http://localhost:10001/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"roll_dice","params":{"sides":6,"count":2},"id":6}'

test_jsonrpc "Dice - check_prime method" "http://localhost:10001/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"check_prime","params":{"numbers":[7,8,9,11]},"id":8}'

test_jsonrpc "Dice - get_statistics method" "http://localhost:10001/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"get_statistics","params":{},"id":9}'

test_jsonrpc "Dice - reset_stats method" "http://localhost:10001/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"reset_stats","params":{},"id":10}'

test_jsonrpc "Dice - message/send method" "http://localhost:10001/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"message/send","params":{"message":{"messageId":"test-789","role":"user","parts":[{"kind":"text","text":"Roll a 20-sided dice"}]}},"id":11}'

# Test error handling
print_status "INFO" ""
print_status "INFO" "Testing Error Handling..."

test_jsonrpc "Hello World - Invalid method" "http://localhost:9999/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"invalid_method","params":{},"id":12}' true

test_jsonrpc "Weather - Invalid location" "http://localhost:10000/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"get_current_weather","params":{"location":""},"id":13}' false

test_jsonrpc "Dice - Invalid parameters" "http://localhost:10001/a2a/rpc" \
    '{"jsonrpc":"2.0","method":"roll_dice","params":{"sides":0},"id":14}' false

# Test batch requests
print_status "INFO" ""
print_status "INFO" "Testing Batch Requests..."

test_jsonrpc "Hello World - Batch request" "http://localhost:9999/a2a/rpc" \
    '[{"jsonrpc":"2.0","method":"greet","params":{"name":"Alice"},"id":15},{"jsonrpc":"2.0","method":"greet","params":{"name":"Bob"},"id":16}]'

# Print final results
print_status "INFO" ""
print_status "INFO" "Test Results Summary"
print_status "INFO" "===================="
print_status "INFO" "Total Tests: $TOTAL_TESTS"
print_status "INFO" "Passed: $PASSED_TESTS"
print_status "INFO" "Failed: $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    print_status "SUCCESS" "All tests passed! 🎉"
    exit 0
else
    print_status "FAIL" "Some tests failed. Check the output above for details."
    exit 1
fi