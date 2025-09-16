#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "a2a"
require "puma"
require "rack"
require "json"
require "securerandom"
require "dotenv/load"
require_relative "weather_agent"

# Weather Agent A2A Implementation
class WeatherAgentA2A
  include A2A::Server::Agent

  def initialize
    @weather_agent = WeatherAgent.new
  end

  # Define agent capabilities
  a2a_capability "weather_current" do
    method "get_current_weather"
    description "Get current weather conditions for any city or location worldwide"
    tags ["weather", "current", "temperature", "conditions"]
    input_schema type: "object", properties: {
      location: { type: "string", description: "City name or 'City, Country'" },
      units: { type: "string", enum: ["metric", "imperial", "kelvin"], default: "metric" }
    }, required: ["location"]
    output_schema type: "object", properties: {
      success: { type: "boolean" },
      location: { type: "object" },
      weather: { type: "object" },
      units: { type: "object" }
    }
  end

  a2a_capability "weather_forecast" do
    method "get_forecast"
    description "Get weather forecast for up to 5 days for any location"
    tags ["weather", "forecast", "prediction", "future"]
    input_schema type: "object", properties: {
      location: { type: "string", description: "City name or 'City, Country'" },
      days: { type: "integer", minimum: 1, maximum: 5, default: 5 },
      units: { type: "string", enum: ["metric", "imperial", "kelvin"], default: "metric" }
    }, required: ["location"]
    output_schema type: "object", properties: {
      success: { type: "boolean" },
      location: { type: "object" },
      forecast: { type: "array" },
      days: { type: "integer" }
    }
  end

  a2a_capability "location_search" do
    method "search_cities"
    description "Search for cities and locations worldwide"
    tags ["search", "cities", "locations", "geography"]
    input_schema type: "object", properties: {
      query: { type: "string", description: "City name to search for" }
    }, required: ["query"]
    output_schema type: "object", properties: {
      success: { type: "boolean" },
      cities: { type: "array" },
      count: { type: "integer" }
    }
  end

  # Define A2A methods
  a2a_method "get_current_weather" do |params|
    # Handle case where params might be nil or not a hash
    params = {} unless params.is_a?(Hash)
    
    location = params[:location] || params["location"] || params[:city] || params["city"]
    units = params[:units] || params["units"] || "metric"
    
    next { error: "Location is required" } unless location && !location.to_s.strip.empty?
    
    begin
      result = @weather_agent.get_current_weather(location, units)
      
      if result[:success]
        # Return a simple, serializable response
        {
          success: true,
          location: result[:location][:name],
          country: result[:location][:country],
          temperature: result[:weather][:temperature],
          feels_like: result[:weather][:feels_like],
          condition: result[:weather][:condition],
          humidity: result[:weather][:humidity],
          wind_speed: result[:weather][:wind_speed],
          units: result[:units][:temperature],
          timestamp: result[:timestamp]
        }
      else
        { error: result[:error] || "Weather data unavailable" }
      end
    rescue => e
      { error: "Error: #{e.message}" }
    end
  end

  a2a_method "get_forecast" do |params|
    # Handle case where params might be nil or not a hash
    params = {} unless params.is_a?(Hash)
    
    location = params[:location] || params["location"] || params[:city] || params["city"]
    days = params[:days] || params["days"] || 5
    units = params[:units] || params["units"] || "metric"
    
    next { error: "Location is required" } unless location && !location.to_s.strip.empty?
    
    begin
      result = @weather_agent.get_forecast(location, days, units)
      
      if result[:success]
        # Return a simple, serializable response
        forecast_data = result[:forecast].map do |day|
          {
            date: day[:date],
            min_temp: day[:temperature][:min],
            max_temp: day[:temperature][:max],
            avg_temp: day[:temperature][:avg],
            condition: day[:condition],
            humidity: day[:humidity],
            precipitation: day[:precipitation]
          }
        end
        
        {
          success: true,
          location: result[:location][:name],
          country: result[:location][:country],
          forecast: forecast_data,
          days: result[:days],
          units: result[:units][:temperature],
          timestamp: result[:timestamp]
        }
      else
        { error: result[:error] || "Forecast data unavailable" }
      end
    rescue => e
      { error: "Error: #{e.message}" }
    end
  end

  a2a_method "get_weather_by_coordinates" do |params|
    # Handle case where params might be nil or not a hash
    params = {} unless params.is_a?(Hash)
    
    lat = params[:latitude] || params["latitude"] || params[:lat] || params["lat"]
    lon = params[:longitude] || params["longitude"] || params[:lon] || params["lon"]
    units = params[:units] || "metric"
    
    next { error: "Latitude and longitude are required" } unless lat && lon
    
    begin
      result = @weather_agent.get_weather_by_coordinates(lat, lon, units)
      
      if result[:success]
        # Return a simple, serializable response
        {
          success: true,
          location: result[:location],
          weather: result[:weather],
          units: result[:units],
          timestamp: result[:timestamp]
        }
      else
        {
          error: result[:error] || "Failed to get weather data",
          success: false,
          coordinates: { lat: lat, lon: lon }
        }
      end
    rescue => e
      {
        error: "Internal error: #{e.message}",
        success: false,
        coordinates: { lat: lat, lon: lon }
      }
    end
  end

  a2a_method "search_cities" do |params|
    # Handle case where params might be nil or not a hash
    params = {} unless params.is_a?(Hash)
    
    query = params[:query] || params["query"] || params[:city] || params["city"] || params[:location] || params["location"]
    limit = params[:limit] || 5
    
    next { error: "Search query is required" } unless query && !query.to_s.strip.empty?
    
    begin
      result = @weather_agent.search_cities(query)
      
      if result[:success]
        # Return a simple, serializable response
        {
          success: true,
          cities: result[:cities],
          query: result[:query],
          timestamp: result[:timestamp]
        }
      else
        {
          error: result[:error] || "Failed to search cities",
          success: false,
          query: query
        }
      end
    rescue => e
      {
        error: "Internal error: #{e.message}",
        success: false,
        query: query
      }
    end
  end

  # Handle generic message sending
  a2a_method "message/send" do |params|
    # Safely extract message with proper nil handling
    message = params[:message] || params["message"] || {}
    
    # Extract user text with safe navigation and proper defaults
    user_text = extract_message_text(message)

    # Process the natural language input
    result = @weather_agent.process_natural_language(user_text)

    # Create simple response hash (A2A gem will handle message formatting)
    {
      message_id: SecureRandom.uuid,
      role: "agent", 
      parts: [
        {
          kind: "text",
          text: result[:message] || "I can help you with weather information!"
        }
      ]
    }
  end

  # Generate agent card
  def generate_agent_card(_context = nil)
    A2A::Types::AgentCard.new(
      name: "Weather Agent",
      description: "A comprehensive weather information agent with OpenWeatherMap integration",
      version: "1.0.0",
      url: "http://localhost:9999",
      preferred_transport: "JSONRPC",
      default_input_modes: ["text"],
      default_output_modes: ["text"],
      capabilities: A2A::Types::AgentCapabilities.new(streaming: false),
      skills: generate_skills_from_capabilities
    )
  end

  private

  # Safely extract text from message structure with proper nil handling
  def extract_message_text(message)
    return "Hello" unless message.is_a?(Hash)
    
    # Try different possible message structures
    parts = message[:parts] || message["parts"]
    return "Hello" unless parts.is_a?(Array) && !parts.empty?
    
    first_part = parts.first
    return "Hello" unless first_part.is_a?(Hash)
    
    # Extract text with safe navigation
    text = first_part[:text] || first_part["text"]
    return text.to_s if text && !text.to_s.strip.empty?
    
    # Default fallback
    "Hello"
  end

  def generate_skills_from_capabilities
    self.class._a2a_capabilities.all.map do |capability|
      A2A::Types::AgentSkill.new(
        id: capability.name,
        name: capability.name.split('_').map(&:capitalize).join(' '),
        description: capability.description,
        tags: capability.tags || [],
        examples: []
      )
    end
  end
end

# Rack application that handles A2A requests
class WeatherAgentApp
  def initialize
    @agent = WeatherAgentA2A.new
    @handler = A2A::Server::Handler.new(@agent)
  end

  def call(env)
    request = Rack::Request.new(env)

    case request.path_info
    when "/a2a/agent-card"
      handle_agent_card(request)
    when "/a2a/rpc"
      handle_rpc(request)
    when "/health"
      handle_health(request)
    when "/"
      handle_root(request)
    else
      [404, { "Content-Type" => "application/json" }, ['{"error": "Not found"}']]
    end
  end

  private

  def handle_agent_card(_request)
    agent_card = @agent.generate_agent_card
    [
      200,
      {
        "Content-Type" => "application/json",
        "Access-Control-Allow-Origin" => "*"
      },
      [agent_card.to_json]
    ]
  rescue StandardError => e
    error_response(500, "Failed to generate agent card: #{e.message}")
  end

  def handle_rpc(request)
    return method_not_allowed unless request.post?

    begin
      body = request.body.read
      
      response = @handler.handle_request(body)

      [
        200,
        {
          "Content-Type" => "application/json",
          "Access-Control-Allow-Origin" => "*"
        },
        [response]
      ]
    rescue A2A::Errors::A2AError => e
      error_response(400, e.message, e.to_json_rpc_error)
    rescue StandardError => e
      error_response(500, "Internal server error: #{e.message}")
    end
  end

  def handle_health(_request)
    # Check if weather service is configured
    api_key_configured = !ENV["WEATHER_API_KEY"].nil? && !ENV["WEATHER_API_KEY"].empty?
    
    status = {
      status: "healthy",
      timestamp: Time.now.utc.iso8601,
      services: {
        weather_api: api_key_configured ? "configured" : "not_configured"
      }
    }

    [
      200,
      { "Content-Type" => "application/json" },
      [status.to_json]
    ]
  end

  def handle_root(_request)
    api_key_status = ENV["WEATHER_API_KEY"] ? "✅ Configured" : "❌ Not configured"
    
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Weather Agent - A2A Ruby Sample</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; }
          .endpoint { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 5px; }
          .example { background: #e8f4f8; padding: 10px; margin: 10px 0; border-radius: 5px; }
          .status { background: #f0f8f0; padding: 10px; margin: 10px 0; border-radius: 5px; }
          code { background: #e8e8e8; padding: 2px 4px; border-radius: 3px; }
        </style>
      </head>
      <body>
        <h1>🌤️ Weather Agent - A2A Ruby Sample</h1>
        <p>A comprehensive weather information agent built with the A2A Ruby SDK and OpenWeatherMap API.</p>

        <div class="status">
          <h3>Service Status</h3>
          <p><strong>Weather API:</strong> #{api_key_status}</p>
          #{ENV["WEATHER_API_KEY"] ? "" : "<p><em>Set WEATHER_API_KEY environment variable to enable weather data</em></p>"}
        </div>

        <h2>Features:</h2>
        <ul>
          <li>🌡️ Current weather conditions for any city worldwide</li>
          <li>📅 5-day weather forecasts</li>
          <li>🗺️ Weather by coordinates (latitude/longitude)</li>
          <li>🔍 City search and location discovery</li>
          <li>💬 Natural language processing</li>
          <li>🌍 Multiple unit systems (metric, imperial)</li>
        </ul>

        <h2>Available Endpoints:</h2>
        <div class="endpoint">
          <strong>GET /a2a/agent-card</strong><br>
          Get the agent's capability card
        </div>
        <div class="endpoint">
          <strong>POST /a2a/rpc</strong><br>
          Send JSON-RPC 2.0 requests to the agent
        </div>
        <div class="endpoint">
          <strong>GET /health</strong><br>
          Health check endpoint with service status
        </div>

        <h2>Test the Agent:</h2>
        <p>Run the client: <code>ruby client.rb</code></p>

        <h2>Example Requests:</h2>
        <div class="example">
          <strong>Get current weather:</strong>
          <pre>curl -X POST http://localhost:9999/a2a/rpc \\
  -H "Content-Type: application/json" \\
  -d '{
    "jsonrpc": "2.0",
    "method": "get_current_weather",
    "params": {"location": "London, UK", "units": "metric"},
    "id": 1
  }'</pre>
        </div>

        <div class="example">
          <strong>Get weather forecast:</strong>
          <pre>curl -X POST http://localhost:9999/a2a/rpc \\
  -H "Content-Type: application/json" \\
  -d '{
    "jsonrpc": "2.0",
    "method": "get_forecast",
    "params": {"location": "New York", "days": 3},
    "id": 2
  }'</pre>
        </div>

        <div class="example">
          <strong>Search cities:</strong>
          <pre>curl -X POST http://localhost:9999/a2a/rpc \\
  -H "Content-Type: application/json" \\
  -d '{
    "jsonrpc": "2.0",
    "method": "search_cities",
    "params": {"query": "Paris"},
    "id": 3
  }'</pre>
        </div>

        <div class="example">
          <strong>Natural language message:</strong>
          <pre>curl -X POST http://localhost:9999/a2a/rpc \\
  -H "Content-Type: application/json" \\
  -d '{
    "jsonrpc": "2.0",
    "method": "message/send",
    "params": {
      "message": {
        "messageId": "test-123",
        "role": "user",
        "parts": [{"kind": "text", "text": "What\\'s the weather like in Tokyo?"}]
      }
    },
    "id": 4
  }'</pre>
        </div>

        <h2>Setup Instructions:</h2>
        <ol>
          <li>Get a free API key from <a href="https://openweathermap.org/api" target="_blank">OpenWeatherMap</a></li>
          <li>Copy <code>.env.example</code> to <code>.env</code></li>
          <li>Set your API key: <code>WEATHER_API_KEY=your_api_key_here</code></li>
          <li>Run: <code>bundle install && ruby server.rb</code></li>
        </ol>
      </body>
      </html>
    HTML

    [200, { "Content-Type" => "text/html" }, [html]]
  end

  def method_not_allowed
    [405, { "Content-Type" => "application/json" }, ['{"error": "Method not allowed"}']]
  end

  def error_response(status, message, json_rpc_error = nil)
    body = json_rpc_error || { error: message }
    [
      status,
      { "Content-Type" => "application/json" },
      [body.to_json]
    ]
  end
end

# Start the server
if __FILE__ == $PROGRAM_NAME
  port = ENV.fetch("PORT", 9999).to_i
  host = ENV.fetch("HOST", "0.0.0.0")

  puts "🌤️ Starting Weather Agent A2A Server..."
  puts "📡 Server running on http://#{host}:#{port}"
  puts "🤖 Agent card: http://#{host}:#{port}/a2a/agent-card"
  puts "🔧 JSON-RPC endpoint: http://#{host}:#{port}/a2a/rpc"
  puts "❤️  Health check: http://#{host}:#{port}/health"
  puts "🌐 Web interface: http://#{host}:#{port}/"
  
  # Check API key
  if ENV["WEATHER_API_KEY"]
    puts "✅ Weather API key configured"
  else
    puts "⚠️  Weather API key not configured - set WEATHER_API_KEY environment variable"
  end
  
  puts
  puts "Press Ctrl+C to stop the server"

  app = WeatherAgentApp.new

  # Configure Puma
  server = Puma::Server.new(app)
  server.add_tcp_listener(host, port)

  # Handle graceful shutdown
  trap("INT") do
    puts "\n🛑 Shutting down gracefully..."
    server.stop
    exit
  end

  server.run.join
end