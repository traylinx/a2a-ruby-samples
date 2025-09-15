# 🌤️ Weather Agent

A comprehensive weather information agent that integrates with the OpenWeatherMap API. This sample demonstrates external API integration, error handling, caching, and natural language processing with the A2A Ruby SDK.

## What This Example Demonstrates

- External API integration
- Error handling and resilience
- Response caching
- Data transformation
- Location parsing
- Production-ready patterns

## Quick Start

1. **Get a weather API key:**
   - Sign up at [OpenWeatherMap](https://openweathermap.org/api) (free tier available)
   - Copy your API key

2. **Set up environment:**
   ```bash
   cp .env.example .env
   # Edit .env and add your API key
   ```

3. **Install dependencies:**
   ```bash
   bundle install
   ```

4. **Start the agent server:**
   ```bash
   ruby server.rb
   ```

5. **Test with the client:**
   ```bash
   ruby client.rb
   ```

## Agent Capabilities

The Weather Agent provides:

- **get_current_weather(location)** - Current weather conditions
- **get_forecast(location, days)** - Multi-day weather forecast  
- **get_weather_alerts(location)** - Weather warnings and alerts
- **search_locations(query)** - Find locations by name

### Example Interactions

```
User: "What's the weather in San Francisco?"
Agent: "🌤️ Current weather in San Francisco, CA:
        Temperature: 68°F (20°C)
        Conditions: Partly cloudy
        Humidity: 65%
        Wind: 12 mph W"

User: "Will it rain in London tomorrow?"
Agent: "🌧️ Tomorrow's forecast for London, UK:
        High: 15°C, Low: 8°C
        Conditions: Light rain
        Chance of rain: 80%
        Bring an umbrella! ☂️"
```

## Features

### Weather Data
- Current conditions (temperature, humidity, wind, pressure)
- Multi-day forecasts (up to 7 days)
- Weather alerts and warnings
- Location search and geocoding

### Smart Responses
- Natural language processing for location queries
- Contextual responses with appropriate emojis
- Unit conversion (Celsius/Fahrenheit)
- Helpful suggestions and tips

### Production Features
- Response caching (5-minute TTL)
- Rate limiting protection
- Error handling with fallbacks
- Request logging and monitoring

## Files

- `server.rb` - The weather agent server
- `weather_agent.rb` - Core weather logic
- `weather_service.rb` - External API integration
- `client.rb` - Interactive test client
- `.env.example` - Environment variables template

## Configuration

Create a `.env` file:
```bash
WEATHER_API_KEY=your_openweathermap_api_key
WEATHER_CACHE_TTL=300
WEATHER_DEFAULT_UNITS=metric
```

## Testing

Run the test suite:
```bash
bundle exec rspec
```

Test with mock data (no API key needed):
```bash
WEATHER_MOCK_MODE=true ruby server.rb
```

## API Examples

### Get current weather
```bash
curl -X POST http://localhost:9999/a2a/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "get_current_weather",
    "params": {"location": "New York"},
    "id": 1
  }'
```

### Get forecast
```bash
curl -X POST http://localhost:9999/a2a/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0", 
    "method": "get_forecast",
    "params": {"location": "Tokyo", "days": 3},
    "id": 2
  }'
```

### Natural language query
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
        "parts": [{"kind": "text", "text": "Is it going to be sunny in Miami this weekend?"}]
      }
    },
    "id": 3
  }'
```

## Architecture

### WeatherService
Handles external API integration:
```ruby
class WeatherService
  def current_weather(location)
    # API call with caching and error handling
  end
  
  def forecast(location, days)
    # Multi-day forecast with data transformation
  end
end
```

### WeatherAgent  
Core business logic:
```ruby
class WeatherAgent
  def process_weather_query(text)
    # Parse natural language and extract intent
  end
  
  def format_weather_response(data)
    # Transform API data into user-friendly format
  end
end
```

## Error Handling

The agent handles various error scenarios:
- Invalid API keys
- Network timeouts
- Location not found
- API rate limits
- Service unavailable

## Next Steps

- Try the [Multi-Agent Client](../multi-agent-client/) to orchestrate multiple agents
- Explore [Rails Weather Service](../rails-weather-service/) for web application integration
- Check out [Streaming Chat Agent](../streaming-chat-agent/) for real-time features