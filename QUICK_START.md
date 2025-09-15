# A2A Ruby Samples - Quick Start Guide

Get up and running with A2A Ruby samples in 5 minutes!

## 🚀 One-Command Setup

```bash
# Clone and setup samples (includes A2A Ruby gem from GitHub)
git clone https://github.com/traylinx/a2a-ruby-samples.git
cd a2a-ruby-samples
./setup.sh
```

The samples use the A2A Ruby gem directly from GitHub, so no separate installation is needed!

## 🎯 Try Your First Agent

### 1. Hello World Agent (30 seconds)

```bash
# Terminal 1: Start the agent
cd samples/helloworld-agent
ruby server.rb

# Terminal 2: Test the agent
ruby client.rb
```

**Expected Output:**
```
🧪 Testing Hello World A2A Agent
📡 Connecting to: http://localhost:9999/a2a

📋 Test 1: Getting agent card...
   ✅ Agent Name: HelloWorldAgent
   ✅ Description: Simple Hello World agent
   ✅ Skills: greeting
   ✅ Capabilities: 2 methods

💬 Test 2: Sending simple message...
   ✅ Response: Hello World! You said: 'Hello there!'

✅ All tests completed!
```

### 2. Interactive Dice Agent (1 minute)

```bash
# Terminal 1: Start the dice agent
cd samples/dice-agent
ruby server.rb

# Terminal 2: Interactive mode
ruby client.rb --interactive
```

**Try these commands:**
```
You: roll a 20-sided dice
Agent: 🎲 Rolling dice with 20 sides... You rolled: 15!

You: is 15 prime?
Agent: 🔢 Checking 15 for prime numbers...
       ❌ Not prime: 15

You: show my stats
Agent: 📊 Your Rolling Statistics:
       • Total rolls: 1
       • Average roll: 15.0
       • Highest roll: 15
```

## 🌐 Cross-Stack Testing (2 minutes)

Test Ruby agents with Python clients:

```bash
# Automated cross-stack testing
./test_cross_stack.sh
```

**Manual cross-stack test:**
```bash
# 1. Start Ruby Hello World agent
cd samples/helloworld-agent
ruby server.rb &

# 2. Test with Python client (if available)
cd ../../../a2a-samples/samples/python/agents/helloworld
uv run test_client.py --base-url http://localhost:9999

# 3. Success! Ruby ↔ Python compatibility confirmed
```

## 🧪 Run All Tests

```bash
# Comprehensive test suite
./test_all.sh
```

## 🎮 What's Next?

### Explore More Samples
- **Weather Agent**: External API integration
- **Streaming Chat**: Real-time communication
- **Rails Integration**: Full web application

### Build Your Own Agent
```ruby
# my_agent.rb
require 'a2a'

class MyAgent
  include A2A::Server::Agent
  
  a2a_skill "my_skill" do |skill|
    skill.description = "My custom functionality"
  end
  
  a2a_method "my_method" do |params|
    { message: "Hello from my agent!" }
  end
end

# Start server
app = A2A::Server::RackApp.new(MyAgent.new)
Rack::Handler::Puma.run(app, Port: 9999)
```

### Cross-Language Development
- Ruby agents ↔ Python clients ✅
- Python agents ↔ Ruby clients ✅
- Multi-language agent orchestration ✅

## 🆘 Need Help?

- **Stuck?** Check the individual sample READMEs
- **Errors?** Run `./test_all.sh` to diagnose issues
- **Cross-stack issues?** Run `./test_cross_stack.sh`
- **Questions?** Open an issue on GitHub

## 📚 Learn More

- [A2A Ruby SDK Documentation](https://github.com/traylinx/a2a-ruby/docs/)
- [A2A Protocol Specification](https://a2a-protocol.org)
- [Sample Applications Guide](README.md)

---

**You're ready to build amazing A2A agents! 🎉**