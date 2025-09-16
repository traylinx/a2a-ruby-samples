# Changelog

All notable changes to the A2A Ruby Samples project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-09-15

### Changed
- **Updated gem source**: Now uses A2A Ruby gem directly from GitHub repository (`https://github.com/traylinx/a2a-ruby.git`)
- **Simplified setup**: No need for separate gem installation, Bundler handles everything
- **Updated documentation**: Reflects new GitHub-based installation process

### Technical Details
- All Gemfiles now reference `git: "https://github.com/traylinx/a2a-ruby.git"`
- Setup script simplified to work with GitHub gem source
- Documentation updated to reflect new installation process

## [1.0.0] - 2025-09-15

### Added
- **Hello World Agent**: Basic A2A agent implementation with simple greeting functionality
- **Dice Agent**: Interactive agent with tool calling capabilities for dice rolling and prime number checking
- **Weather Agent**: Real-world agent with external API integration using OpenWeatherMap
- **Comprehensive Documentation**: Complete README, Quick Start guide, and individual sample documentation
- **Testing Suite**: Full test coverage with unit tests and cross-stack compatibility testing
- **Setup Automation**: One-command setup script for easy installation and configuration
- **Cross-Stack Compatibility**: Verified compatibility between Ruby and Python A2A implementations
- **Docker Support**: Container configurations for easy deployment and testing

### Features
- ✅ **Global Installation Support**: Works with `gem install a2a-ruby`
- ✅ **JSON-RPC Method Calls**: All method calls working correctly
- ✅ **Agent Card Generation**: Proper agent metadata and capability discovery
- ✅ **Cross-Language Communication**: Ruby ↔ Python agent interoperability
- ✅ **Production Ready**: Clean dependencies and stable operation
- ✅ **Comprehensive Testing**: Unit tests, integration tests, and cross-stack validation

### Technical Details
- **Ruby Version**: 2.7+ compatibility
- **A2A Protocol**: v0.3.0 compliance
- **JSON-RPC**: 2.0 specification compliance
- **Testing Framework**: RSpec with comprehensive test coverage
- **Documentation**: Complete setup and usage guides

### Repository Structure
```
samples/
├── helloworld-agent/    # Basic A2A functionality
├── dice-agent/          # Interactive tools and state management
└── weather-agent/       # External API integration
```

### Cross-Stack Compatibility Matrix
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

---

**Ready for production use and community contributions! 🎉**