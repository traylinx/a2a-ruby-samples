# A2A Ruby Sample Applications

This repository contains sample applications demonstrating how to use the [A2A Ruby SDK](https://github.com/a2aproject/a2a-ruby) to build agent-to-agent communication systems.

## 🚀 Quick Start

### Prerequisites

1. **Build the A2A Ruby gem locally:**
   ```bash
   # Navigate to the A2A Ruby gem directory
   cd ../a2a-ruby
   
   # Build the gem
   gem build a2a-ruby.gemspec
   
   # Install locally
   gem install a2a-ruby-1.0.0.gem
   ```

2. **Or use local development setup:**
   ```bash
   # Each sample can use the local gem via path in Gemfile
   # This is already configured in the sample Gemfiles
   ```

### Running Samples

1. **Choose a sample to run:**
   ```bash
   cd samples/helloworld-agent
   bundle install
   ruby server.rb
   ```

2. **Test with the client:**
   ```bash
   # In another terminal
   ruby client.rb
   ```

3. **Cross-stack testing with Python agents:**
   ```bash
   # Test Ruby client with Python agent
   cd ../../../a2a-samples/samples/python/agents/helloworld
   uv run .
   
   # Then test Ruby client against Python agent
   cd ../../../../a2a-ruby-samples/samples/helloworld-agent
   AGENT_URL=http://localhost:9999 ruby client.rb
   ```

## 📁 Sample Applications

### 🌟 **Basic Examples**

#### [Hello World Agent](samples/helloworld-agent/)
The simplest possible A2A agent that responds with "Hello World!"
- **Tech**: Plain Ruby
- **Features**: Basic agent setup, simple message handling
- **Use Case**: Learning A2A basics

#### [Dice Agent](samples/dice-agent/)
Interactive agent that rolls dice and checks for prime numbers
- **Tech**: Plain Ruby with tools
- **Features**: Function calling, interactive responses, state management
- **Use Case**: Game mechanics, interactive agents

#### [Weather Agent](samples/weather-agent/)
Practical weather service agent with real API integration
- **Tech**: Plain Ruby with external APIs
- **Features**: External service integration, error handling, caching
- **Use Case**: Service integration, real-world data

### 🌐 **Web Framework Examples**

#### [Rails Weather Service](samples/rails-weather-service/)
Full Rails application with A2A agent integration
- **Tech**: Rails 7+ with A2A Engine
- **Features**: Web UI, background jobs, database storage, authentication
- **Use Case**: Production web applications

#### [Sinatra Dice Service](samples/sinatra-dice-service/)
Lightweight web service using Sinatra
- **Tech**: Sinatra with A2A middleware
- **Features**: REST API, JSON responses, middleware
- **Use Case**: Microservices, lightweight APIs

### 🤖 **Multi-Agent Examples**

#### [Multi-Agent Client](samples/multi-agent-client/)
Client that communicates with multiple agents
- **Tech**: Plain Ruby client
- **Features**: Multiple agent connections, task orchestration, streaming
- **Use Case**: Agent orchestration, complex workflows

#### [Agent Marketplace](samples/agent-marketplace/)
Discovery service for finding and connecting to agents
- **Tech**: Rails with agent registry
- **Features**: Agent discovery, capability matching, load balancing
- **Use Case**: Agent ecosystems, service discovery

### 🔧 **Advanced Examples**

#### [Streaming Chat Agent](samples/streaming-chat-agent/)
Real-time chat agent with Server-Sent Events
- **Tech**: Plain Ruby with SSE
- **Features**: Real-time streaming, WebSocket fallback, chat history
- **Use Case**: Chat applications, real-time communication

#### [File Processing Agent](samples/file-processing-agent/)
Agent that processes uploaded files with progress tracking
- **Tech**: Rails with background jobs
- **Features**: File uploads, progress tracking, artifact management
- **Use Case**: Document processing, file analysis

## 🛠 **Development Setup**

### Prerequisites
- Ruby 2.7.0 or higher
- Bundler gem manager
- Redis (for some examples)
- PostgreSQL (for Rails examples)

### Environment Setup

#### Option 1: Use Local Gem (Recommended for Development)
```bash
# 1. Build and install the A2A Ruby gem locally
cd ../a2a-ruby
gem build a2a-ruby.gemspec
gem install a2a-ruby-1.0.0.gem

# 2. Clone/navigate to samples
cd ../a2a-ruby-samples

# 3. Install dependencies for all samples
./setup.sh

# Or install individually
cd samples/helloworld-agent
bundle install
```

#### Option 2: Use Gem Path (Alternative)
```bash
# The Gemfiles are configured to use local path if available
# This allows development without installing the gem
cd samples/helloworld-agent
bundle install  # Will use local gem via path
```

#### Cross-Stack Testing Setup
```bash
# Set up Python samples for cross-testing
cd ../a2a-samples/samples/python
uv sync

# Set up Ruby samples
cd ../../../a2a-ruby-samples
./setup.sh
```

### Running Examples

Each sample includes:
- `README.md` - Specific setup instructions
- `Gemfile` - Dependencies
- `server.rb` - Agent server
- `client.rb` - Test client
- `docker-compose.yml` - Container setup (where applicable)

## 📚 **Learning Path**

### 1. **Start with Basics**
```bash
cd samples/helloworld-agent
bundle install && ruby server.rb
# In another terminal:
ruby client.rb
```

### 2. **Try Interactive Features**
```bash
cd samples/dice-agent
bundle install && ruby server.rb
# Test with: ruby client.rb
```

### 3. **Explore Web Integration**
```bash
cd samples/sinatra-dice-service
bundle install && ruby app.rb
# Visit: http://localhost:4567
```

### 4. **Build Production Apps**
```bash
cd samples/rails-weather-service
bundle install
rails db:setup
rails server
# Visit: http://localhost:3000
```

## 🧪 **Testing**

### Unit Tests
Run tests for all samples:
```bash
./test_all.sh
```

Run tests for specific sample:
```bash
cd samples/helloworld-agent
bundle exec rspec
```

### Cross-Stack Testing

Test Ruby agents with Python clients and vice versa to ensure protocol compatibility.

#### Ruby Agent ↔ Python Client
```bash
# 1. Start Ruby Hello World agent
cd samples/helloworld-agent
ruby server.rb &
RUBY_PID=$!

# 2. Test with Python client
cd ../../../a2a-samples/samples/python/agents/helloworld
uv run test_client.py --agent-url http://localhost:9999

# 3. Cleanup
kill $RUBY_PID
```

#### Python Agent ↔ Ruby Client  
```bash
# 1. Start Python Hello World agent
cd ../../../a2a-samples/samples/python/agents/helloworld
uv run . &
PYTHON_PID=$!

# 2. Test with Ruby client
cd ../../../../a2a-ruby-samples/samples/helloworld-agent
AGENT_URL=http://localhost:9999 ruby client.rb

# 3. Cleanup
kill $PYTHON_PID
```

#### Multi-Language Agent Communication
```bash
# Start multiple agents on different ports
cd samples/helloworld-agent
PORT=9001 ruby server.rb &

cd ../dice-agent  
PORT=9002 ruby server.rb &

cd ../../../a2a-samples/samples/python/agents/helloworld
PORT=9003 uv run . &

# Test multi-agent orchestration
cd ../../../a2a-ruby-samples/samples/multi-agent-client
ruby orchestrator.rb
```

### Protocol Compliance Testing
```bash
# Test JSON-RPC 2.0 compliance
cd samples/helloworld-agent
bundle exec rspec spec/protocol_compliance_spec.rb

# Test A2A protocol compliance  
bundle exec rspec spec/a2a_compliance_spec.rb
```

## 🐳 **Docker Support**

Most samples include Docker support:
```bash
cd samples/weather-agent
docker-compose up
```

## 📖 **Documentation**

- **[A2A Ruby SDK Documentation](https://github.com/a2aproject/a2a-ruby/docs)**
- **[A2A Protocol Specification](https://a2a-protocol.org)**
- **[Getting Started Guide](https://github.com/a2aproject/a2a-ruby/docs/getting_started.md)**

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Add your sample application
4. Include comprehensive README and tests
5. Submit a pull request

### Sample Structure
```
samples/your-sample/
├── README.md           # Setup and usage instructions
├── Gemfile            # Dependencies
├── server.rb          # Agent server implementation
├── client.rb          # Test client
├── spec/              # Tests
├── docker-compose.yml # Container setup (optional)
└── .env.example       # Environment variables
```

## 🌐 **Cross-Stack Compatibility**

These Ruby samples are designed to be fully compatible with the Python A2A implementation, enabling seamless cross-language agent communication.

### Compatibility Matrix

| Ruby Agent | Python Client | Status |
|------------|---------------|--------|
| Hello World | ✅ Compatible | Tested |
| Dice Agent | ✅ Compatible | Tested |
| Weather Agent | ✅ Compatible | Tested |

| Python Agent | Ruby Client | Status |
|---------------|-------------|--------|
| Hello World | ✅ Compatible | Tested |
| Dice Agent | ✅ Compatible | Tested |
| Weather Agent | ✅ Compatible | Tested |

### Quick Cross-Stack Test

```bash
# Run automated cross-stack tests
./test_cross_stack.sh

# Or test manually:

# 1. Start Ruby agent
cd samples/helloworld-agent
ruby server.rb &

# 2. Test with Python client  
cd ../../../a2a-samples/samples/python/agents/helloworld
uv run test_client.py --base-url http://localhost:9999

# 3. Vice versa - Python agent, Ruby client
cd ../../../a2a-samples/samples/python/agents/helloworld  
uv run . &
cd ../../../../a2a-ruby-samples/samples/helloworld-agent
AGENT_URL=http://localhost:9999/a2a ruby client.rb
```

### Protocol Compliance

All samples implement:
- ✅ **JSON-RPC 2.0** specification compliance
- ✅ **A2A Protocol v0.3.0** compliance  
- ✅ **Agent Card** schema compatibility
- ✅ **Message format** standardization
- ✅ **Task lifecycle** compatibility
- ✅ **Error handling** standardization

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 **Support**

- **Issues**: [GitHub Issues](https://github.com/a2aproject/a2a-ruby-samples/issues)
- **Discussions**: [GitHub Discussions](https://github.com/a2aproject/a2a-ruby-samples/discussions)
- **Documentation**: [A2A Ruby SDK Docs](https://github.com/a2aproject/a2a-ruby/docs)
- **Cross-Stack Testing**: Run `./test_cross_stack.sh` for compatibility verification

---

**Happy coding with A2A Ruby! 🎉**