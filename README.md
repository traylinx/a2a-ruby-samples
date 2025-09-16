# A2A Ruby Sample Applications

This repository contains sample applications demonstrating how to use the [A2A Ruby SDK](https://github.com/traylinx/a2a-ruby) to build agent-to-agent communication systems.

## 🌐 About Agent2Agent (A2A)

The **Agent2Agent (A2A) Protocol** enables seamless communication between AI agents across different platforms, languages, and frameworks. This Ruby implementation is part of the broader A2A ecosystem.

### 🔗 Related Projects

- **[A2A Protocol Specification](https://github.com/a2aproject/A2A)** - Official A2A specification and documentation
- **[A2A Ruby SDK](https://github.com/traylinx/a2a-ruby)** - Ruby implementation of the A2A protocol (this gem)
- **[A2A Python SDK](https://github.com/a2aproject/a2a-python)** - Official Python implementation
- **[A2A Samples](https://github.com/a2aproject/a2a-samples)** - Multi-language sample repository with Python, JavaScript, Go, and Java examples
- **[A2A Inspector](https://github.com/a2aproject/a2a-inspector)** - UI tool for inspecting A2A-enabled agents

### 🚀 Why A2A Ruby?

The **a2a-ruby gem** provides:
- ✅ **Full A2A Protocol Compliance** - Implements the complete A2A v0.3.0 specification
- ✅ **Cross-Language Compatibility** - Works seamlessly with Python, JavaScript, and other A2A implementations
- ✅ **Production Ready** - Clean, well-tested Ruby implementation
- ✅ **Easy Integration** - Simple API for building A2A-enabled agents
- ✅ **JSON-RPC 2.0 Support** - Standard protocol for method calls and responses

## ✅ **Fully Functional & Production Ready**

All sample applications are working perfectly with the A2A Ruby gem:
- ✅ **GitHub Installation** - Uses latest development version from GitHub
- ✅ **JSON-RPC Method Calls** - All method calls work correctly  
- ✅ **Cross-Stack Compatible** - Works with Python A2A agents
- ✅ **Production Ready** - Clean dependencies and stable operation

## 🚀 Quick Start

### Prerequisites
- Ruby 2.7+ and Bundler
- Git (for cloning repositories)

### Setup
```bash
# Clone and setup samples
git clone https://github.com/traylinx/a2a-ruby-samples.git
cd a2a-ruby-samples
./setup.sh
```

The samples use the A2A Ruby gem directly from GitHub repository, so no separate gem installation is needed. Bundler will handle all dependencies automatically.

### Running Your First Agent

1. **Start the Hello World agent:**
   ```bash
   cd samples/helloworld-agent
   ruby server.rb
   ```

2. **Test with the client:**
   ```bash
   # In another terminal
   ruby client.rb
   ```

3. **Try interactive mode:**
   ```bash
   ruby client.rb --interactive
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

## 🛠 **Development Setup**

### Prerequisites
- Ruby 2.7.0 or higher
- Bundler gem manager
- OpenWeatherMap API key (for weather agent)

### Environment Setup

```bash
# 1. Clone the repository
git clone https://github.com/traylinx/a2a-ruby-samples.git
cd a2a-ruby-samples

# 2. Run setup script
./setup.sh

# 3. Configure weather agent (optional)
cd samples/weather-agent
cp .env.example .env
# Edit .env and add your OpenWeatherMap API key
```

### Running Examples

Each sample includes:
- `README.md` - Specific setup instructions
- `Gemfile` - Dependencies
- `server.rb` - Agent server
- `client.rb` - Test client
- `spec/` - Unit tests

## 📚 **Learning Path**

### 1. **Start with Basics**
```bash
cd samples/helloworld-agent
ruby server.rb
# In another terminal: ruby client.rb
```

### 2. **Try Interactive Features**
```bash
cd samples/dice-agent
ruby server.rb
# Test with: ruby client.rb --interactive
```

### 3. **Explore External APIs**
```bash
cd samples/weather-agent
# Configure API key in .env first
ruby server.rb
# Test with: ruby client.rb --interactive
```

## 🧪 **Testing**

### Comprehensive Test Suite
This repository includes a comprehensive test suite that validates all A2A functionality:

```bash
# Run complete test suite (28 tests covering all functionality)
./test_all_agents.sh
```

**Test Coverage:**
- ✅ **28 Tests Total** - 100% pass rate
- ✅ **HTTP Endpoints** - Health checks, agent cards, web interfaces
- ✅ **JSON-RPC Methods** - All 12 A2A methods across 3 agents
- ✅ **Error Handling** - Invalid methods, parameters, and edge cases
- ✅ **Batch Requests** - Multiple JSON-RPC calls in single request
- ✅ **Mock Mode** - Weather agent works without API keys
- ✅ **Cross-Stack Compatibility** - Verified with Python implementations

### Quick Tests
```bash
# Test all samples individually
./test_samples.sh

# Test cross-stack compatibility
./test_cross_stack.sh

# Run all tests including unit tests
./test_all.sh
```

### Unit Tests
```bash
# Run tests for specific sample
cd samples/dice-agent
bundle exec rspec

# Run tests for all samples
./test_all.sh
```

### Cross-Stack Testing

Test Ruby agents with other language implementations from the [official A2A samples](https://github.com/a2aproject/a2a-samples):

#### Ruby Agent ↔ Python Client
```bash
# 1. Clone the official A2A samples repository
git clone https://github.com/a2aproject/a2a-samples.git

# 2. Start Ruby Hello World agent
cd a2a-ruby-samples/samples/helloworld-agent
ruby server.rb &

# 3. Test with Python client
cd ../../a2a-samples/samples/python/agents/helloworld
uv run test_client.py

# 4. Cleanup
kill %1
```

#### Python Agent ↔ Ruby Client  
```bash
# 1. Start Python Hello World agent
cd a2a-samples/samples/python/agents/helloworld
uv run . &

# 2. Test with Ruby client
cd ../../../a2a-ruby-samples/samples/helloworld-agent
AGENT_URL=http://localhost:9999/a2a ruby client.rb

# 3. Cleanup
kill %1
```

#### Testing with Other Languages
The [A2A samples repository](https://github.com/a2aproject/a2a-samples) includes implementations in:
- **Python** - Full-featured agents with various frameworks (LangGraph, CrewAI, etc.)
- **JavaScript** - Node.js and browser-based agents
- **Go** - High-performance agent implementations
- **Java** - Enterprise-ready agent solutions

All implementations are fully interoperable with these Ruby samples.

## 🐳 **Docker Support**

Most samples include Docker support:
```bash
cd samples/helloworld-agent
docker-compose up
```

## 📖 **Documentation**

### A2A Ruby Specific
- **[A2A Ruby SDK](https://github.com/traylinx/a2a-ruby)** - Main gem repository and documentation
- **[A2A Ruby API Documentation](https://github.com/traylinx/a2a-ruby/docs)** - Detailed API reference

### A2A Protocol & Ecosystem
- **[A2A Protocol Specification](https://github.com/a2aproject/A2A)** - Official protocol documentation
- **[A2A Samples Repository](https://github.com/a2aproject/a2a-samples)** - Multi-language examples and tutorials
- **[A2A Inspector](https://github.com/a2aproject/a2a-inspector)** - Agent debugging and inspection tool

### Getting Started
- **[Quick Start Guide](QUICK_START.md)** - Ruby-specific quick start
- **[Protocol Overview](https://github.com/a2aproject/A2A/blob/main/README.md)** - Understanding A2A fundamentals

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

These Ruby samples are designed to be fully compatible with all A2A implementations, enabling seamless cross-language agent communication. You can test interoperability with the [official A2A samples repository](https://github.com/a2aproject/a2a-samples) which includes Python, JavaScript, Go, and Java implementations.

### Compatibility Matrix

| Ruby Agent | Other Language Clients | Status |
|------------|------------------------|--------|
| Hello World | Python, JavaScript, Go, Java | ✅ Compatible |
| Dice Agent | Python, JavaScript, Go, Java | ✅ Compatible |
| Weather Agent | Python, JavaScript, Go, Java | ✅ Compatible |

| Other Language Agents | Ruby Client | Status |
|----------------------|-------------|--------|
| Python Agents | All samples | ✅ Compatible |
| JavaScript Agents | All samples | ✅ Compatible |
| Go Agents | All samples | ✅ Compatible |
| Java Agents | All samples | ✅ Compatible |

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

### Ruby-Specific Support
- **Issues**: [A2A Ruby SDK Issues](https://github.com/traylinx/a2a-ruby/issues)
- **Discussions**: [A2A Ruby Discussions](https://github.com/traylinx/a2a-ruby/discussions)
- **Documentation**: [A2A Ruby SDK Docs](https://github.com/traylinx/a2a-ruby/docs)

### General A2A Support
- **Protocol Issues**: [A2A Specification Issues](https://github.com/a2aproject/A2A/issues)
- **Multi-Language Examples**: [A2A Samples Issues](https://github.com/a2aproject/a2a-samples/issues)
- **Community**: [A2A Project Discussions](https://github.com/a2aproject/A2A/discussions)

---

**Happy coding with A2A Ruby! 🎉**