# frozen_string_literal: true

require "faraday"
require "json"
require "time"

# Weather service that integrates with OpenWeatherMap API
class WeatherService
  API_BASE_URL = "https://api.openweathermap.org/data/2.5"
  GEOCODING_URL = "https://api.openweathermap.org/geo/1.0"

  def initialize(api_key = nil)
    @api_key = api_key || ENV["WEATHER_API_KEY"]
    @cache = {}
    @cache_ttl = ENV.fetch("WEATHER_CACHE_TTL", 300).to_i
    @mock_mode = ENV["WEATHER_MOCK_MODE"] == "true"

    # In mock mode, we don't need a real API key
    unless @mock_mode
      raise ArgumentError, "Weather API key is required" unless @api_key
    end

    @client = Faraday.new do |conn|
      conn.request :json
      conn.response :json
      conn.adapter Faraday.default_adapter
    end
  end

  # Get current weather for a city
  def get_current_weather(city, country_code = nil, units = "metric")
    location_query = country_code ? "#{city},#{country_code}" : city
    cache_key = "current_#{location_query}_#{units}"

    # Return mock data if in mock mode
    if @mock_mode
      return mock_current_weather(city, country_code, units)
    end

    # Check cache first
    if cached_data = get_cached_data(cache_key)
      return cached_data
    end

    begin
      response = @client.get("#{API_BASE_URL}/weather") do |req|
        req.params["q"] = location_query
        req.params["appid"] = @api_key
        req.params["units"] = units
      end

      if response.success?
        weather_data = parse_current_weather(response.body, units)
        cache_data(cache_key, weather_data)
        weather_data
      else
        handle_api_error(response)
      end
    rescue Faraday::Error => e
      {
        error: "Network error: #{e.message}",
        success: false
      }
    end
  end

  # Get weather forecast for a city
  def get_forecast(city, country_code = nil, days = 5, units = "metric")
    location_query = country_code ? "#{city},#{country_code}" : city
    cache_key = "forecast_#{location_query}_#{days}_#{units}"

    # Return mock data if in mock mode
    if @mock_mode
      return mock_forecast(city, country_code, days, units)
    end

    # Check cache first
    if cached_data = get_cached_data(cache_key)
      return cached_data
    end

    begin
      response = @client.get("#{API_BASE_URL}/forecast") do |req|
        req.params["q"] = location_query
        req.params["appid"] = @api_key
        req.params["units"] = units
        req.params["cnt"] = days * 8 # API returns 3-hour intervals, so 8 per day
      end

      if response.success?
        forecast_data = parse_forecast(response.body, units, days)
        cache_data(cache_key, forecast_data)
        forecast_data
      else
        handle_api_error(response)
      end
    rescue Faraday::Error => e
      {
        error: "Network error: #{e.message}",
        success: false
      }
    end
  end

  # Get weather by coordinates
  def get_weather_by_coordinates(lat, lon, units = "metric")
    cache_key = "coords_#{lat}_#{lon}_#{units}"

    # Return mock data if in mock mode
    if @mock_mode
      return mock_current_weather_by_coordinates(lat, lon, units)
    end

    # Check cache first
    if cached_data = get_cached_data(cache_key)
      return cached_data
    end

    begin
      response = @client.get("#{API_BASE_URL}/weather") do |req|
        req.params["lat"] = lat
        req.params["lon"] = lon
        req.params["appid"] = @api_key
        req.params["units"] = units
      end

      if response.success?
        weather_data = parse_current_weather(response.body, units)
        cache_data(cache_key, weather_data)
        weather_data
      else
        handle_api_error(response)
      end
    rescue Faraday::Error => e
      {
        error: "Network error: #{e.message}",
        success: false
      }
    end
  end

  # Search for cities (geocoding)
  def search_cities(query, limit = 5)
    # Return mock data if in mock mode
    if @mock_mode
      return mock_search_cities(query, limit)
    end

    begin
      response = @client.get("#{GEOCODING_URL}/direct") do |req|
        req.params["q"] = query
        req.params["limit"] = limit
        req.params["appid"] = @api_key
      end

      if response.success?
        cities = response.body.map do |city|
          {
            name: city["name"],
            country: city["country"],
            state: city["state"],
            lat: city["lat"],
            lon: city["lon"],
            display_name: format_city_name(city)
          }
        end

        {
          success: true,
          cities: cities,
          count: cities.length
        }
      else
        handle_api_error(response)
      end
    rescue Faraday::Error => e
      {
        error: "Network error: #{e.message}",
        success: false
      }
    end
  end

  # Get weather alerts (mock implementation - OpenWeatherMap requires paid plan)
  def get_weather_alerts(lat, lon)
    {
      success: true,
      alerts: [],
      message: "Weather alerts require a premium API subscription",
      coordinates: { lat: lat, lon: lon }
    }
  end

  private

  # Mock methods for testing
  def mock_current_weather(city, country_code = nil, units = "metric")
    temp_unit = units == "metric" ? "°C" : (units == "imperial" ? "°F" : "K")
    speed_unit = units == "metric" ? "m/s" : "mph"
    
    # Mock temperature based on city name for variety
    base_temp = case city.downcase
                when "london" then 15
                when "new york", "newyork" then 20
                when "tokyo" then 18
                when "paris" then 16
                when "sydney" then 22
                else 19
                end
    
    # Adjust for units
    temperature = case units
                  when "imperial" then (base_temp * 9.0/5.0 + 32).round(1)
                  when "kelvin" then (base_temp + 273.15).round(1)
                  else base_temp.to_f
                  end

    {
      success: true,
      location: {
        name: city.capitalize,
        country: country_code&.upcase || "XX",
        coordinates: {
          lat: 51.5074,
          lon: -0.1278
        }
      },
      current: {
        temperature: temperature,
        feels_like: temperature + 2,
        humidity: 65,
        pressure: 1013,
        visibility: 10.0,
        uv_index: 3,
        condition: {
          main: "Clouds",
          description: "Partly cloudy",
          icon: "02d"
        },
        wind: {
          speed: 3.5,
          direction: 230,
          gust: 5.2
        },
        clouds: 40,
        sunrise: "06:30 UTC",
        sunset: "19:45 UTC"
      },
      units: {
        temperature: temp_unit,
        wind_speed: speed_unit,
        pressure: "hPa",
        visibility: "km"
      },
      timestamp: Time.now.utc.iso8601,
      source: "Mock Weather Service"
    }
  end

  def mock_forecast(city, country_code = nil, days = 5, units = "metric")
    temp_unit = units == "metric" ? "°C" : (units == "imperial" ? "°F" : "K")
    
    forecasts = (1..days).map do |day|
      base_temp = 18 + (day * 2) # Gradually increasing temperature
      
      temperature = case units
                    when "imperial" then (base_temp * 9.0/5.0 + 32).round(1)
                    when "kelvin" then (base_temp + 273.15).round(1)
                    else base_temp.to_f
                    end

      {
        date: (Date.today + day).strftime("%Y-%m-%d"),
        temperature: {
          min: temperature - 5,
          max: temperature + 5,
          avg: temperature
        },
        condition: ["Sunny", "Partly cloudy", "Cloudy", "Light rain"][day % 4],
        humidity: 60 + (day * 5),
        pressure: 1010 + day,
        wind_speed: 2.5 + (day * 0.5),
        precipitation: day.even? ? 0.0 : 1.2
      }
    end

    {
      success: true,
      location: {
        name: city.capitalize,
        country: country_code&.upcase || "XX",
        coordinates: {
          lat: 51.5074,
          lon: -0.1278
        }
      },
      forecast: forecasts,
      units: {
        temperature: temp_unit,
        wind_speed: units == "metric" ? "m/s" : "mph",
        precipitation: "mm"
      },
      days_requested: days,
      timestamp: Time.now.utc.iso8601,
      source: "Mock Weather Service"
    }
  end

  def mock_current_weather_by_coordinates(lat, lon, units = "metric")
    temp_unit = units == "metric" ? "°C" : (units == "imperial" ? "°F" : "K")
    speed_unit = units == "metric" ? "m/s" : "mph"
    
    base_temp = 15.0
    temperature = case units
                  when "imperial" then (base_temp * 9.0/5.0 + 32).round(1)
                  when "kelvin" then (base_temp + 273.15).round(1)
                  else base_temp
                  end

    {
      success: true,
      location: {
        name: "Location at #{lat}, #{lon}",
        country: "XX",
        coordinates: {
          lat: lat.to_f,
          lon: lon.to_f
        }
      },
      current: {
        temperature: temperature,
        feels_like: temperature + 2.0,
        humidity: 65,
        pressure: 1013,
        visibility: 10.0,
        uv_index: 3,
        condition: {
          main: "Clear",
          description: "Clear sky",
          icon: "01d"
        },
        wind: {
          speed: 3.5,
          direction: 230,
          gust: 5.2
        },
        clouds: 20,
        sunrise: "06:30 UTC",
        sunset: "19:45 UTC"
      },
      units: {
        temperature: temp_unit,
        wind_speed: speed_unit,
        pressure: "hPa",
        visibility: "km"
      },
      timestamp: Time.now.utc.iso8601,
      source: "Mock Weather Service"
    }
  end

  def mock_search_cities(query, limit = 5)
    # Mock city search results
    mock_cities = [
      { name: "#{query} City", country: "US", state: "CA", lat: 37.7749, lon: -122.4194 },
      { name: "#{query} Town", country: "UK", state: nil, lat: 51.5074, lon: -0.1278 },
      { name: "#{query} Village", country: "FR", state: nil, lat: 48.8566, lon: 2.3522 }
    ]

    cities_result = mock_cities.take(limit)
    
    {
      success: true,
      cities: cities_result,
      count: cities_result.length,
      query: query,
      limit: limit,
      timestamp: Time.now.utc.iso8601,
      source: "Mock Weather Service"
    }
  end

  def parse_current_weather(data, units)
    temp_unit = units == "metric" ? "°C" : (units == "imperial" ? "°F" : "K")
    speed_unit = units == "metric" ? "m/s" : "mph"

    {
      success: true,
      location: {
        name: data["name"],
        country: data["sys"]["country"],
        coordinates: {
          lat: data["coord"]["lat"],
          lon: data["coord"]["lon"]
        }
      },
      current: {
        temperature: data["main"]["temp"].round(1),
        feels_like: data["main"]["feels_like"].round(1),
        humidity: data["main"]["humidity"],
        pressure: data["main"]["pressure"],
        visibility: data["visibility"] ? (data["visibility"] / 1000.0).round(1) : nil,
        uv_index: nil, # Not available in current weather endpoint
        condition: {
          main: data["weather"][0]["main"],
          description: data["weather"][0]["description"].capitalize,
          icon: data["weather"][0]["icon"]
        },
        wind: {
          speed: data["wind"]["speed"],
          direction: data["wind"]["deg"],
          gust: data["wind"]["gust"]
        },
        clouds: data["clouds"]["all"],
        sunrise: Time.at(data["sys"]["sunrise"]).utc.strftime("%H:%M UTC"),
        sunset: Time.at(data["sys"]["sunset"]).utc.strftime("%H:%M UTC")
      },
      units: {
        temperature: temp_unit,
        wind_speed: speed_unit,
        pressure: "hPa",
        visibility: "km"
      },
      timestamp: Time.now.utc.iso8601,
      source: "OpenWeatherMap"
    }
  end

  def parse_forecast(data, units, days)
    temp_unit = units == "metric" ? "°C" : (units == "imperial" ? "°F" : "K")
    
    # Group forecasts by date
    daily_forecasts = {}
    
    data["list"].each do |item|
      date = Time.at(item["dt"]).strftime("%Y-%m-%d")
      
      daily_forecasts[date] ||= {
        date: date,
        temperatures: [],
        conditions: [],
        humidity: [],
        pressure: [],
        wind_speeds: [],
        precipitation: 0
      }
      
      daily_forecasts[date][:temperatures] << item["main"]["temp"]
      daily_forecasts[date][:conditions] << item["weather"][0]["description"]
      daily_forecasts[date][:humidity] << item["main"]["humidity"]
      daily_forecasts[date][:pressure] << item["main"]["pressure"]
      daily_forecasts[date][:wind_speeds] << item["wind"]["speed"]
      
      # Add precipitation if present
      if item["rain"] && item["rain"]["3h"]
        daily_forecasts[date][:precipitation] += item["rain"]["3h"]
      end
    end

    # Convert to daily summaries
    forecasts = daily_forecasts.values.first(days).map do |day|
      temps = day[:temperatures]
      {
        date: day[:date],
        temperature: {
          min: temps.min.round(1),
          max: temps.max.round(1),
          avg: (temps.sum / temps.length).round(1)
        },
        condition: day[:conditions].first.capitalize,
        humidity: (day[:humidity].sum / day[:humidity].length).round,
        pressure: (day[:pressure].sum / day[:pressure].length).round,
        wind_speed: (day[:wind_speeds].sum / day[:wind_speeds].length).round(1),
        precipitation: day[:precipitation].round(1)
      }
    end

    {
      success: true,
      location: {
        name: data["city"]["name"],
        country: data["city"]["country"],
        coordinates: {
          lat: data["city"]["coord"]["lat"],
          lon: data["city"]["coord"]["lon"]
        }
      },
      forecast: forecasts,
      units: {
        temperature: temp_unit,
        wind_speed: units == "metric" ? "m/s" : "mph",
        precipitation: "mm"
      },
      days_requested: days,
      timestamp: Time.now.utc.iso8601,
      source: "OpenWeatherMap"
    }
  end

  def format_city_name(city)
    parts = [city["name"]]
    parts << city["state"] if city["state"]
    parts << city["country"]
    parts.join(", ")
  end

  def handle_api_error(response)
    error_message = case response.status
                   when 401
                     "Invalid API key"
                   when 404
                     "Location not found"
                   when 429
                     "API rate limit exceeded"
                   else
                     "API error: #{response.status}"
                   end

    {
      error: error_message,
      success: false,
      status_code: response.status
    }
  end

  def get_cached_data(key)
    return nil unless @cache[key]

    cached_item = @cache[key]
    if Time.now - cached_item[:timestamp] < @cache_ttl
      cached_item[:data]
    else
      @cache.delete(key)
      nil
    end
  end

  def cache_data(key, data)
    @cache[key] = {
      data: data,
      timestamp: Time.now
    }
  end
end