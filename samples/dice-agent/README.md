# 🎲 Dice Agent

An interactive A2A agent that rolls dice and performs mathematical operations like prime number checking. This sample demonstrates function calling, state management, and natural language processing with the A2A Ruby SDK.

## What This Example Demonstrates

- Interactive agent functionality
- Function calling and tool usage
- State management across requests
- Complex response generation
- Mathematical operations
- User input validation

## Quick Start

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Start the agent server:**
   ```bash
   ruby server.rb
   ```
   
   The server will start on `http://localhost:10101`

3. **Test with the client:**
   ```bash
   ruby client.rb
   ```

4. **Try interactive mode:**
   ```bash
   ruby client.rb --interactive
   ```

## Agent Capabilities

The Dice Agent provides:

- **roll_dice(sides)** - Roll an N-sided dice (default: 6 sides)
- **check_prime(numbers)** - Check if numbers are prime
- **get_statistics()** - Get rolling statistics
- **reset_stats()** - Reset rolling history

### Example Interactions

```
User: "Roll a 20-sided dice"
Agent: "🎲 Rolling a 20-sided dice... You rolled: 15!"

User: "Is 15 prime?"
Agent: "🔢 Checking if 15 is prime... No, 15 is not prime (divisible by 3 and 5)"

User: "Roll two 6-sided dice and check if they're prime"
Agent: "🎲 Rolling two 6-sided dice... You rolled: 3 and 5!
        🔢 Checking for primes... Both 3 and 5 are prime numbers! 🎉"
```

## Features

### Dice Rolling
- Support for any number of sides (1-100)
- Multiple dice rolling
- Roll history tracking
- Statistics (total rolls, average, highest/lowest)

### Prime Number Checking
- Efficient prime checking algorithm
- Batch prime checking for multiple numbers
- Educational explanations for non-prime numbers

### Interactive Responses
- Contextual responses based on previous rolls
- Emoji and formatting for better UX
- Error handling with helpful messages

## Files

- `server.rb` - The dice agent server implementation
- `client.rb` - Interactive test client
- `dice_agent.rb` - Core agent logic with tools
- `spec/` - Comprehensive test suite

## Testing

Run the test suite:
```bash
bundle exec rspec
```

Test specific functionality:
```bash
bundle exec rspec spec/dice_agent_spec.rb
bundle exec rspec spec/server_spec.rb
```

## Docker Support

Run with Docker:
```bash
docker-compose up
```

## API Examples

### Roll a dice
```bash
curl -X POST http://localhost:10101/a2a/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "roll_dice",
    "params": {"sides": 20},
    "id": 1
  }'
```

### Check prime numbers
```bash
curl -X POST http://localhost:10101/a2a/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "check_prime",
    "params": {"numbers": [7, 8, 9, 11]},
    "id": 2
  }'
```

### Send natural language message
```bash
curl -X POST http://localhost:10101/a2a/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "message/send",
    "params": {
      "message": {
        "messageId": "test-123",
        "role": "user",
        "parts": [{"kind": "text", "text": "Roll three dice and tell me if any are prime"}]
      }
    },
    "id": 3
  }'
```

## Code Architecture

### DiceAgent Class
The core agent logic with mathematical functions:

```ruby
class DiceAgent
  def roll_dice(sides = 6)
    # Dice rolling logic with validation
  end
  
  def check_prime(numbers)
    # Prime checking with explanations
  end
  
  def process_natural_language(text)
    # Parse user intent and execute appropriate functions
  end
end
```

### A2A Integration
The agent integrates with A2A protocol:

```ruby
class DiceA2AAgent
  include A2A::Server::Agent
  
  a2a_skill "dice_rolling" do |skill|
    skill.description = "Roll dice and perform mathematical operations"
  end
  
  a2a_method "roll_dice" do |params|
    @dice_agent.roll_dice(params[:sides])
  end
end
```

## Next Steps

- Try the [Weather Agent](../weather-agent/) for external API integration
- Explore [Streaming Chat Agent](../streaming-chat-agent/) for real-time communication
- Check out [Rails Weather Service](../rails-weather-service/) for web application integration