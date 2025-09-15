# A2A Ruby Sample Applications

This repository contains sample applications demonstrating how to use the [A2A Ruby SDK](https://github.com/traylinx/a2a-ruby) to build agent-to-agent communication systems.

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

### Quick Tests
```bash
# Test all samples
./test_samples.sh

# Test cross-stack compatibility
./test_cross_stack.sh

# Run all tests
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

Test Ruby agents with Python clients and vice versa:

#### Ruby Agent ↔ Python Client
```bash
# 1. Start Ruby Hello World agent
cd samples/helloworld-agent
ruby server.rb &

# 2. Test with Python client (requires a2a-samples repo)
cd ../../../a2a-samples/samples/python/agents/helloworld
uv run test_client.py

# 3. Cleanup
kill %1
```

#### Python Agent ↔ Ruby Client  
```bash
# 1. Start Python Hello World agent
cd ../../../a2a-samples/samples/python/agents/helloworld
uv run . &

# 2. Test with Ruby client
cd ../../../../a2a-ruby-samples/samples/helloworld-agent
AGENT_URL=http://localhost:9999/a2a ruby client.rb

# 3. Cleanup
kill %1
```

## 🐳 **Docker Support**

Most samples include Docker support:
```bash
cd samples/helloworld-agent
docker-compose up
```

## 📖 **Documentation**

- **[A2A Ruby SDK Documentation](https://github.com/traylinx/a2a-ruby/docs)**
- **[A2A Protocol Specification](https://a2a-protocol.org)**
- **[Quick Start Guide](QUICK_START.md)**

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

- **Issues**: [GitHub Issues](https://github.com/traylinx/a2a-ruby-samples/issues)
- **Discussions**: [GitHub Discussions](https://github.com/traylinx/a2a-ruby-samples/discussions)
- **Documentation**: [A2A Ruby SDK Docs](https://github.com/traylinx/a2a-ruby/docs)

---

**Happy coding with A2A Ruby! 🎉**