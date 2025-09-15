#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "a2a"
require "securerandom"
require "dotenv/load"

# Test client for the Weather Agent
class WeatherAgentClient
  def initialize(base_url = nil)
    @base_url = base_url || ENV["AGENT_URL"] || "http://localhost:9999/a2a"
    @client = A2A::Client::HttpClient.new(@base_url)
  end

  def run_tests
    puts "🌤️ Testing Weather Agent A2A Server"
    puts "📡 Connecting to: #{@base_url}"
    puts

    # Test 1: Get agent card
    test_agent_card

    # Test 2: Current weather
    test_current_weather

    # Test 3: Weather forecast
    test_weather_forecast

    # Test 4: Weather by coordinates
    test_weather_by_coordinates

    # Test 5: City search
    test_city_search

    # Test 6: Natural language processing
    test_natural_language

    puts "✅ All tests completed!"
  end

  private

  def test_agent_card
    puts "📋 Test 1: Getting agent card..."

    begin
      agent_card = @client.get_card

      puts "   ✅ Agent Name: #{agent_card.name}"
      puts "   ✅ Description: #{agent_card.description}"
      puts "   ✅ Skills: #{agent_card.skills.map(&:name).join(', ')}"
      puts "   ✅ Capabilities: #{agent_card.capabilities.length} methods"
      puts
    rescue StandardError => e
      puts "   ❌ Failed: #{e.message}"
      puts
    end
  end

  def test_current_weather
    puts "🌡️ Test 2: Getting current weather..."

    test_locations = [
      { location: "London, UK", description: "London, UK" },
      { location: "New York", description: "New York" },
      { location: "Tokyo, Japan", description: "Tokyo, Japan" }
    ]

    test_locations.each do |test_case|
      begin
        response = @client.call_method("get_current_weather", {
          location: test_case[:location],
          units: "metric"
        })

        if response[:success]
          weather = response[:weather]
          location = response[:location]
          puts "   ✅ #{test_case[:description]}:"
          puts "      🌡️ Temperature: #{weather[:temperature]}°C (feels like #{weather[:feels_like]}°C)"
          puts "      ☁️ Condition: #{weather[:condition]}"
          puts "      💧 Humidity: #{weather[:humidity]}%"
        else
          puts "   ❌ #{test_case[:description]}: #{response[:error]}"
        end
      rescue StandardError => e
        puts "   ❌ #{test_case[:description]}: Failed - #{e.message}"
      end
    end
    puts
  end

  def test_weather_forecast
    puts "📅 Test 3: Getting weather forecast..."

    begin
      response = @client.call_method("get_forecast", {
        location: "Paris, France",
        days: 3,
        units: "metric"
      })

      if response[:success]
        location = response[:location]
        forecast = response[:forecast]
        
        puts "   ✅ 3-day forecast for #{location[:name]}, #{location[:country]}:"
        forecast.each do |day|
          puts "      📆 #{day[:date]}: #{day[:temperature][:min]}-#{day[:temperature][:max]}°C, #{day[:condition]}"
        end
      else
        puts "   ❌ Failed: #{response[:error]}"
      end
    rescue StandardError => e
      puts "   ❌ Failed: #{e.message}"
    end
    puts
  end

  def test_weather_by_coordinates
    puts "🗺️ Test 4: Getting weather by coordinates..."

    # Test coordinates for Sydney, Australia
    test_coords = [
      { lat: -33.8688, lon: 151.2093, name: "Sydney, Australia" },
      { lat: 40.7128, lon: -74.0060, name: "New York, USA" }
    ]

    test_coords.each do |coords|
      begin
        response = @client.call_method("get_weather_by_coordinates", {
          latitude: coords[:lat],
          longitude: coords[:lon],
          units: "metric"
        })

        if response[:success]
          weather = response[:weather]
          location = response[:location]
          puts "   ✅ #{coords[:name]} (#{coords[:lat]}, #{coords[:lon]}):"
          puts "      🌡️ #{weather[:temperature]}°C, #{weather[:condition]}"
        else
          puts "   ❌ #{coords[:name]}: #{response[:error]}"
        end
      rescue StandardError => e
        puts "   ❌ #{coords[:name]}: Failed - #{e.message}"
      end
    end
    puts
  end

  def test_city_search
    puts "🔍 Test 5: Searching cities..."

    search_queries = ["Paris", "Springfield", "London"]

    search_queries.each do |query|
      begin
        response = @client.call_method("search_cities", { query: query })

        if response[:success]
          puts "   ✅ Search '#{query}': Found #{response[:count]} cities"
          response[:cities].first(3).each do |city|
            puts "      • #{city[:display_name]}"
          end
        else
          puts "   ❌ Search '#{query}': #{response[:error]}"
        end
      rescue StandardError => e
        puts "   ❌ Search '#{query}': Failed - #{e.message}"
      end
    end
    puts
  end

  def test_natural_language
    puts "💬 Test 6: Natural language processing..."

    test_messages = [
      "What's the weather in Berlin?",
      "Show me the forecast for Rome",
      "Search for cities like Madrid",
      "Temperature in Moscow"
    ]

    test_messages.each_with_index do |text, index|
      begin
        message = A2A::Types::Message.new(
          message_id: SecureRandom.uuid,
          role: "user",
          parts: [A2A::Types::TextPart.new(text: text)]
        )

        response = @client.send_message(message)

        if response.is_a?(A2A::Types::Message)
          response_text = response.parts.first.text
          puts "   #{index + 1}. \"#{text}\""
          puts "      → #{response_text.split("\n").first}..." # Show first line only
        else
          puts "   #{index + 1}. \"#{text}\" → #{response.inspect}"
        end
      rescue StandardError => e
        puts "   #{index + 1}. \"#{text}\" → ❌ Failed: #{e.message}"
      end
    end
    puts
  end
end

# Interactive mode
def interactive_mode
  client = WeatherAgentClient.new

  puts "🎮 Interactive Weather Agent Mode"
  puts "Ask me about weather anywhere in the world!"
  puts "Examples:"
  puts "  - 'What's the weather in London?'"
  puts "  - 'Show me the forecast for Tokyo'"
  puts "  - 'Search for cities like Paris'"
  puts "  - 'Weather in New York, USA'"
  puts "Type 'quit' to exit"
  puts

  loop do
    print "You: "
    input = gets.chomp

    break if input.downcase == "quit"

    begin
      message = A2A::Types::Message.new(
        message_id: SecureRandom.uuid,
        role: "user",
        parts: [A2A::Types::TextPart.new(text: input)]
      )

      response = client.instance_variable_get(:@client).send_message(message)

      if response.is_a?(A2A::Types::Message)
        puts "Agent: #{response.parts.first.text}"
      else
        puts "Agent: #{response.inspect}"
      end
    rescue StandardError => e
      puts "Error: #{e.message}"
      puts "Make sure the weather agent is running and your API key is configured."
    end

    puts
  end

  puts "👋 Goodbye!"
end

# Cross-stack testing mode
def cross_stack_test
  puts "🔄 Cross-Stack Testing Mode"
  puts "Testing Ruby client against Python weather agent..."
  puts

  # Test against Python agent (assuming it's running on port 10001)
  python_client = WeatherAgentClient.new("http://localhost:10001/a2a")

  begin
    puts "📡 Testing connection to Python agent..."
    agent_card = python_client.instance_variable_get(:@client).get_card
    puts "✅ Connected to Python agent: #{agent_card.name}"

    # Test message sending
    message = A2A::Types::Message.new(
      message_id: SecureRandom.uuid,
      role: "user",
      parts: [A2A::Types::TextPart.new(text: "What's the weather in London?")]
    )

    response = python_client.instance_variable_get(:@client).send_message(message)
    puts "✅ Cross-stack message test successful!"
    puts "   Response: #{response.parts.first.text.split("\n").first}..." if response.is_a?(A2A::Types::Message)

  rescue StandardError => e
    puts "❌ Cross-stack test failed: #{e.message}"
    puts "   Make sure the Python weather agent is running on port 10001"
  end
end

# API key check
def check_api_key
  if ENV["WEATHER_API_KEY"].nil? || ENV["WEATHER_API_KEY"].empty?
    puts "⚠️  Warning: WEATHER_API_KEY not configured"
    puts "   Get a free API key from: https://openweathermap.org/api"
    puts "   Set it in your .env file or environment variables"
    puts
    return false
  end
  true
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  case ARGV.first
  when "--interactive", "-i"
    check_api_key
    interactive_mode
  when "--cross-stack", "-x"
    cross_stack_test
  when "--check-key"
    if check_api_key
      puts "✅ Weather API key is configured"
    else
      exit 1
    end
  else
    check_api_key
    client = WeatherAgentClient.new
    client.run_tests

    puts
    puts "💡 Try interactive mode: ruby client.rb --interactive"
    puts "💡 Try cross-stack testing: ruby client.rb --cross-stack"
    puts "💡 Check API key: ruby client.rb --check-key"
  end
end