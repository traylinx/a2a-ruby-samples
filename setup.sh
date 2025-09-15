#!/bin/bash
# Setup script for A2A Ruby samples

set -e

echo "🚀 Setting up A2A Ruby Samples..."

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
    echo "❌ Ruby is not installed. Please install Ruby 2.7+ first."
    exit 1
fi

# Check if Bundler is installed
if ! command -v bundle &> /dev/null; then
    echo "📦 Installing Bundler..."
    gem install bundler
fi

# Check if A2A Ruby gem is available
if ! gem list a2a-ruby | grep -q a2a-ruby; then
    echo "📦 A2A Ruby gem not found. Building from local source..."
    
    if [ -d "../a2a-ruby" ]; then
        cd ../a2a-ruby
        echo "🔨 Building gem..."
        gem build a2a-ruby.gemspec
        
        echo "💎 Installing gem locally..."
        gem install a2a-ruby-*.gem
        
        cd ../a2a-ruby-samples
        echo "✅ A2A Ruby gem installed successfully"
    else
        echo "❌ A2A Ruby source not found at ../a2a-ruby"
        echo "Please ensure the a2a-ruby directory is at the same level as a2a-ruby-samples"
        exit 1
    fi
else
    echo "✅ A2A Ruby gem already installed"
fi

# Install dependencies for all samples
echo "📚 Installing dependencies for all samples..."

samples=(
    "samples/helloworld-agent"
    "samples/dice-agent" 
    "samples/weather-agent"
)

for sample in "${samples[@]}"; do
    if [ -d "$sample" ]; then
        echo "📦 Installing dependencies for $sample..."
        cd "$sample"
        
        # Check if .env.example exists and .env doesn't
        if [ -f ".env.example" ] && [ ! -f ".env" ]; then
            echo "   📝 Creating .env file from .env.example"
            cp .env.example .env
            echo "   ⚠️  Please edit .env and configure your API keys"
        fi
        
        bundle install
        cd - > /dev/null
        echo "✅ $sample ready"
    fi
done

echo ""
echo "🎉 Setup complete! You can now run the samples:"
echo ""
echo "  🌟 Start with Hello World:"
echo "     cd samples/helloworld-agent && ruby server.rb"
echo ""
echo "  🎲 Try the Dice Agent:"
echo "     cd samples/dice-agent && ruby server.rb"
echo ""
echo "  🌤️ Weather Agent (requires API key):"
echo "     cd samples/weather-agent"
echo "     # Edit .env and add WEATHER_API_KEY"
echo "     ruby server.rb"
echo ""
echo "  🧪 Test any agent:"
echo "     ruby client.rb"
echo "     ruby client.rb --interactive"
echo ""
echo "🔗 Get weather API key: https://openweathermap.org/api"
echo "💡 For cross-stack testing, see README.md"