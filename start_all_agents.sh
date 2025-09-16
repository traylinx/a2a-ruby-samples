#!/bin/bash

# A2A Ruby Samples - Start All Agents
# This script starts all three sample agents on different ports

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Function to wait for server to start
wait_for_server() {
    local port=$1
    local name=$2
    local timeout=30
    local count=0
    
    while [ $count -lt $timeout ]; do
        if curl -s "http://localhost:$port/health" > /dev/null 2>&1; then
            print_success "$name is ready on port $port"
            return 0
        fi
        sleep 1
        ((count++))
    done
    print_warn "$name failed to start on port $port"
    return 1
}

# Function to stop all background processes
cleanup() {
    if [ "${CLEANUP_STARTED:-}" != "true" ]; then
        CLEANUP_STARTED=true
        print_info "Stopping all agents..."
        local pids=$(jobs -p 2>/dev/null || true)
        if [ -n "$pids" ]; then
            echo "$pids" | xargs kill 2>/dev/null || true
            wait 2>/dev/null || true
        fi
        print_info "All agents stopped."
    fi
}

# Set up cleanup on exit
trap cleanup EXIT

print_info "Starting A2A Ruby Sample Agents"
print_info "================================"

cd "$(dirname "$0")"

# Update bundles for all agents
print_info "Updating bundles..."
for agent in helloworld-agent weather-agent dice-agent; do
    (cd "samples/$agent" && bundle install --quiet)
done

# Start all three agents
print_info "Starting agents..."

# Hello World Agent - Port 9999
print_info "Starting Hello World Agent on port 9999..."
(cd samples/helloworld-agent && PORT=9999 ruby server.rb) &

# Weather Agent - Port 10000
print_info "Starting Weather Agent on port 10000..."
(cd samples/weather-agent && PORT=10000 ruby server.rb) &

# Dice Agent - Port 10001
print_info "Starting Dice Agent on port 10001..."
(cd samples/dice-agent && PORT=10001 ruby server.rb) &

# Wait for all servers to start
print_info "Waiting for servers to start..."
sleep 3

wait_for_server 9999 "Hello World Agent"
wait_for_server 10000 "Weather Agent"
wait_for_server 10001 "Dice Agent"

print_success "All agents are running!"
print_info ""
print_info "Agent URLs:"
print_info "==========="
print_info "Hello World Agent: http://localhost:9999"
print_info "Weather Agent:     http://localhost:10000"
print_info "Dice Agent:        http://localhost:10001"
print_info ""
print_info "Health Checks:"
print_info "=============="
print_info "curl http://localhost:9999/health"
print_info "curl http://localhost:10000/health"
print_info "curl http://localhost:10001/health"
print_info ""
print_info "Agent Cards:"
print_info "============"
print_info "curl http://localhost:9999/a2a/agent-card"
print_info "curl http://localhost:10000/a2a/agent-card"
print_info "curl http://localhost:10001/a2a/agent-card"
print_info ""
print_info "Press Ctrl+C to stop all agents"

# Keep the script running
while true; do
    sleep 1
done