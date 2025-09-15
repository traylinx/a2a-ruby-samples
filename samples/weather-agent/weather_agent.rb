# frozen_string_literal: true

require_relative "weather_service"

# Weather agent that processes natural language requests and provides weather information
class WeatherAgent
  def initialize(api_key = nil)
    @weather_service = WeatherService.new(api_key)
    @default_units = ENV.fetch("WEATHER_DEFAULT_UNITS", "metric")
  end

  # Get current weather for a location
  def get_current_weather(location, units = nil)
    units ||= @default_units
    
    # Parse location (could be "City" or "City, Country")
    city, country = parse_location(location)
    
    result = @weather_service.get_current_weather(city, country, units)
    
    if result[:success]
      format_current_weather_response(result)
    else
      {
        error: result[:error],
        success: false,
        location: location
      }
    end
  end

  # Get weather forecast for a location
  def get_forecast(location, days = 5, units = nil)
    units ||= @default_units
    days = [days.to_i, 5].min # Limit to 5 days max
    
    city, country = parse_location(location)
    
    result = @weather_service.get_forecast(city, country, days, units)
    
    if result[:success]
      format_forecast_response(result)
    else
      {
        error: result[:error],
        success: false,
        location: location
      }
    end
  end

  # Get weather by coordinates
  def get_weather_by_coordinates(lat, lon, units = nil)
    units ||= @default_units
    
    result = @weather_service.get_weather_by_coordinates(lat, lon, units)
    
    if result[:success]
      format_current_weather_response(result)
    else
      {
        error: result[:error],
        success: false,
        coordinates: { lat: lat, lon: lon }
      }
    end
  end

  # Search for cities
  def search_cities(query)
    result = @weather_service.search_cities(query)
    
    if result[:success]
      {
        success: true,
        query: query,
        cities: result[:cities],
        count: result[:count],
        message: result[:count] > 0 ? "Found #{result[:count]} cities matching '#{query}'" : "No cities found matching '#{query}'"
      }
    else
      {
        error: result[:error],
        success: false,
        query: query
      }
    end
  end

  # Process natural language weather requests
  def process_natural_language(text)
    text = text.downcase.strip

    # Extract location from text
    location = extract_location_from_text(text)
    
    # Determine request type
    if text.match?(/forecast|tomorrow|next.*days?|week/)
      days = extract_days_from_text(text)
      return handle_forecast_request(location, days, text)
    elsif text.match?(/search|find.*city|cities.*like/)
      return handle_city_search(text)
    elsif text.match?(/weather|temperature|temp|condition/)
      return handle_current_weather_request(location, text)
    else
      return handle_general_request(text)
    end
  end

  private

  def parse_location(location)
    parts = location.split(",").map(&:strip)
    if parts.length >= 2
      [parts[0], parts[1]]
    else
      [parts[0], nil]
    end
  end

  def extract_location_from_text(text)
    # Simple location extraction - look for "in LOCATION" or "for LOCATION"
    if match = text.match(/(?:in|for|at)\s+([a-zA-Z\s,]+?)(?:\s|$|[.?!])/)
      match[1].strip
    elsif match = text.match(/weather\s+([a-zA-Z\s,]+?)(?:\s|$|[.?!])/)
      match[1].strip
    else
      # Default to common cities if no location found
      "London" # You might want to make this configurable
    end
  end

  def extract_days_from_text(text)
    if match = text.match(/(\d+)\s*days?/)
      [match[1].to_i, 5].min
    elsif text.match?(/tomorrow/)
      1
    elsif text.match?(/week/)
      5
    else
      3 # Default forecast days
    end
  end

  def handle_current_weather_request(location, original_text)
    result = get_current_weather(location)
    
    if result[:success]
      {
        message: format_current_weather_message(result),
        result: result,
        action: "current_weather",
        location: location,
        original_query: original_text
      }
    else
      {
        message: "❌ Sorry, I couldn't get the current weather for #{location}. #{result[:error]}",
        error: result[:error],
        action: "current_weather",
        location: location
      }
    end
  end

  def handle_forecast_request(location, days, original_text)
    result = get_forecast(location, days)
    
    if result[:success]
      {
        message: format_forecast_message(result, days),
        result: result,
        action: "forecast",
        location: location,
        days: days,
        original_query: original_text
      }
    else
      {
        message: "❌ Sorry, I couldn't get the forecast for #{location}. #{result[:error]}",
        error: result[:error],
        action: "forecast",
        location: location
      }
    end
  end

  def handle_city_search(text)
    # Extract search query
    query = if match = text.match(/(?:search|find).*?(?:city|cities).*?(?:like|for)\s+([a-zA-Z\s]+)/)
              match[1].strip
            elsif match = text.match(/cities.*?([a-zA-Z\s]+)/)
              match[1].strip
            else
              text.gsub(/search|find|city|cities|like|for/, "").strip
            end

    result = search_cities(query)
    
    if result[:success] && result[:count] > 0
      cities_list = result[:cities].map { |city| "• #{city[:display_name]}" }.join("\n")
      {
        message: "🏙️ Found #{result[:count]} cities matching '#{query}':\n#{cities_list}",
        result: result,
        action: "city_search",
        query: query
      }
    else
      {
        message: "🔍 No cities found matching '#{query}'. Try a different search term.",
        result: result,
        action: "city_search",
        query: query
      }
    end
  end

  def handle_general_request(text)
    {
      message: "🌤️ I can help you with weather information! Try asking:\n" \
               "• 'What's the weather in London?'\n" \
               "• 'Show me the forecast for New York'\n" \
               "• 'Weather for Paris, France'\n" \
               "• 'Search for cities like Tokyo'",
      suggestions: [
        "Current weather in London",
        "5-day forecast for New York",
        "Weather in Tokyo, Japan",
        "Search cities like Paris"
      ],
      action: "help"
    }
  end

  def format_current_weather_response(result)
    current = result[:current]
    location = result[:location]
    
    {
      success: true,
      location: {
        name: location[:name],
        country: location[:country],
        coordinates: location[:coordinates]
      },
      weather: {
        temperature: current[:temperature],
        feels_like: current[:feels_like],
        condition: current[:condition][:description],
        humidity: current[:humidity],
        pressure: current[:pressure],
        wind_speed: current[:wind][:speed],
        visibility: current[:visibility],
        sunrise: current[:sunrise],
        sunset: current[:sunset]
      },
      units: result[:units],
      timestamp: result[:timestamp]
    }
  end

  def format_forecast_response(result)
    {
      success: true,
      location: result[:location],
      forecast: result[:forecast],
      units: result[:units],
      days: result[:days_requested],
      timestamp: result[:timestamp]
    }
  end

  def format_current_weather_message(result)
    weather = result[:weather]
    location = result[:location]
    
    "🌤️ Current weather in #{location[:name]}, #{location[:country]}:\n" \
    "🌡️ Temperature: #{weather[:temperature]}#{result[:units][:temperature]} (feels like #{weather[:feels_like]}#{result[:units][:temperature]})\n" \
    "☁️ Condition: #{weather[:condition]}\n" \
    "💧 Humidity: #{weather[:humidity]}%\n" \
    "🌬️ Wind: #{weather[:wind_speed]} #{result[:units][:wind_speed]}\n" \
    "🌅 Sunrise: #{weather[:sunrise]} | 🌇 Sunset: #{weather[:sunset]}"
  end

  def format_forecast_message(result, days)
    location = result[:location]
    forecast = result[:forecast]
    
    message = "📅 #{days}-day forecast for #{location[:name]}, #{location[:country]}:\n\n"
    
    forecast.each do |day|
      message += "📆 #{day[:date]}:\n"
      message += "  🌡️ #{day[:temperature][:min]}-#{day[:temperature][:max]}#{result[:units][:temperature]} (avg: #{day[:temperature][:avg]}#{result[:units][:temperature]})\n"
      message += "  ☁️ #{day[:condition]}\n"
      message += "  💧 Humidity: #{day[:humidity]}%\n"
      if day[:precipitation] > 0
        message += "  🌧️ Precipitation: #{day[:precipitation]}mm\n"
      end
      message += "\n"
    end
    
    message.strip
  end
end