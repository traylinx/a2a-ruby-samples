# Hello World Agent

The simplest possible A2A agent that demonstrates basic agent-to-agent communication using the A2A Ruby SDK.

## What This Example Demonstrates

- Basic A2A agent setup
- Simple message handling
- Agent card generation
- Client-server communication
- JSON-RPC 2.0 protocol usage

## Quick Start

### Prerequisites
Ensure the A2A Ruby gem is available:

**Option 1: Use local development gem (recommended)**
```bash
# From the a2a-ruby-samples root directory
./setup.sh
```

**Option 2: Manual gem installation**
```bash
# Build and install the gem from source
cd ../../../a2a-ruby
gem build a2a-ruby.gemspec
gem install a2a-ruby-1.0.0.gem
cd ../a2a-ruby-samples/samples/helloworld-agent
```

### Installation

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Start the agent server:**
   ```bash
   ruby server.rb
   ```
   
   The server will start on `http://localhost:9999`

3. **Test with the client (in another terminal):**
   ```bash
   ruby client.rb
   ```

## What Happens

1. **Server**: Creates a simple agent that responds to any message with "Hello World!"
2. **Client**: Connects to the agent, sends a test message, and displays the response
3. **Protocol**: Uses JSON-RPC 2.0 over HTTP for communication

## Files

- `server.rb` - The A2A agent server implementation
- `client.rb` - Test client that communicates with the agent
- `Gemfile` - Ruby dependencies
- `spec/` - Test suite

## Agent Capabilities

The Hello World agent provides:

- **Skill**: `greeting` - Simple greeting functionality
- **Method**: `greet` - Returns a hello world message
- **Transport**: HTTP with JSON-RPC 2.0
- **Authentication**: None (public agent)

## Testing

Run the test suite:
```bash
bundle exec rspec
```

## Docker Support

Run with Docker:
```bash
docker-compose up
```

Test the containerized agent:
```bash
curl -X POST http://localhost:9999/a2a/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "message/send",
    "params": {
      "message": {
        "messageId": "test-123",
        "role": "user",
        "parts": [{"kind": "text", "text": "Hello!"}]
      }
    },
    "id": 1
  }'
```

## Cross-Stack Testing

Test protocol compatibility between Ruby and Python implementations:

### Test Ruby Agent with Python Client
```bash
# 1. Start this Ruby agent
ruby server.rb

# 2. In another terminal, test with Python client
cd ../../../../a2a-samples/samples/python/agents/helloworld
uv run test_client.py --base-url http://localhost:9999
```

### Test Python Agent with Ruby Client
```bash
# 1. Start Python Hello World agent
cd ../../../../a2a-samples/samples/python/agents/helloworld
uv run .

# 2. In another terminal, test with this Ruby client
cd ../../../../a2a-ruby-samples/samples/helloworld-agent
AGENT_URL=http://localhost:9999 ruby client.rb
```

### Protocol Compliance Verification
```bash
# Test JSON-RPC 2.0 compliance
bundle exec rspec spec/protocol_compliance_spec.rb

# Test A2A protocol compliance
bundle exec rspec spec/a2a_compliance_spec.rb
```

## Next Steps

- Try the [Dice Agent](../dice-agent/) for interactive functionality
- Explore [Weather Agent](../weather-agent/) for external API integration
- Test cross-language compatibility with Python agents
- Check out multi-agent orchestration examples

## Code Walkthrough

### Server Implementation

The server creates an A2A agent using the Ruby SDK:

```ruby
class HelloWorldAgent
  include A2A::Server::Agent
  
  # Define agent skills
  a2a_skill "greeting" do |skill|
    skill.description = "Simple greeting functionality"
    skill.tags = ["greeting", "hello", "basic"]
  end
  
  # Define A2A methods
  a2a_method "greet" do |params|
    { message: "Hello World!" }
  end
end
```

### Client Implementation

The client connects and sends messages:

```ruby
client = A2A::Client::HttpClient.new("http://localhost:9999/a2a")

message = A2A::Types::Message.new(
  message_id: SecureRandom.uuid,
  role: "user",
  parts: [A2A::Types::TextPart.new(text: "Hello!")]
)

response = client.send_message(message)
puts response.parts.first.text  # "Hello World!"
```

This example demonstrates the core concepts of A2A communication in the simplest possible way.