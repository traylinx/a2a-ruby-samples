# frozen_string_literal: true

require "spec_helper"
require_relative "../weather_agent"

RSpec.describe WeatherAgent do
  let(:agent) { described_class.new("test_api_key") }

  before do
    # Mock the weather service to avoid real API calls
    allow_any_instance_of(WeatherService).to receive(:get_current_weather).and_return({
      success: true,
      location: { name: "London", country: "GB", coordinates: { lat: 51.5074, lon: -0.1278 } },
      current: {
        temperature: 15.2,
        feels_like: 14.8,
        condition: { description: "Partly cloudy" },
        humidity: 72,
        pressure: 1013,
        wind: { speed: 3.5 },
        visibility: 10.0,
        sunrise: "06:45 UTC",
        sunset: "19:30 UTC"
      },
      units: { temperature: "°C", wind_speed: "m/s" },
      timestamp: "2024-01-15T10:30:00Z"
    })

    allow_any_instance_of(WeatherService).to receive(:get_forecast).and_return({
      success: true,
      location: { name: "London", country: "GB" },
      forecast: [
        {
          date: "2024-01-15",
          temperature: { min: 8.1, max: 15.2, avg: 11.7 },
          condition: "Light rain",
          humidity: 75,
          pressure: 1015,
          wind_speed: 4.2,
          precipitation: 2.5
        }
      ],
      units: { temperature: "°C", wind_speed: "m/s" },
      days_requested: 1
    })

    allow_any_instance_of(WeatherService).to receive(:search_cities).and_return({
      success: true,
      cities: [
        {
          name: "London",
          country: "GB",
          state: nil,
          lat: 51.5074,
          lon: -0.1278,
          display_name: "London, GB"
        }
      ],
      count: 1
    })
  end

  describe "#get_current_weather" do
    it "returns formatted current weather data" do
      result = agent.get_current_weather("London")

      expect(result[:success]).to be true
      expect(result[:location][:name]).to eq("London")
      expect(result[:weather][:temperature]).to eq(15.2)
      expect(result[:weather][:condition]).to eq("Partly cloudy")
    end

    it "handles location with country code" do
      result = agent.get_current_weather("London, UK")

      expect(result[:success]).to be true
      expect(result[:location][:name]).to eq("London")
    end

    it "uses default units when not specified" do
      result = agent.get_current_weather("London")

      expect(result[:units][:temperature]).to eq("°C")
    end

    it "handles service errors" do
      allow_any_instance_of(WeatherService).to receive(:get_current_weather).and_return({
        success: false,
        error: "Location not found"
      })

      result = agent.get_current_weather("InvalidCity")

      expect(result[:success]).to be false
      expect(result[:error]).to eq("Location not found")
    end
  end

  describe "#get_forecast" do
    it "returns formatted forecast data" do
      result = agent.get_forecast("London", 1)

      expect(result[:success]).to be true
      expect(result[:location][:name]).to eq("London")
      expect(result[:forecast]).to be_an(Array)
      expect(result[:forecast].first[:date]).to eq("2024-01-15")
    end

    it "limits days to maximum of 5" do
      result = agent.get_forecast("London", 10)

      # Should be limited to 5 days max
      expect(result[:days]).to eq(5)
    end
  end

  describe "#get_weather_by_coordinates" do
    it "returns weather for coordinates" do
      result = agent.get_weather_by_coordinates(51.5074, -0.1278)

      expect(result[:success]).to be true
      expect(result[:location][:coordinates][:lat]).to eq(51.5074)
      expect(result[:location][:coordinates][:lon]).to eq(-0.1278)
    end
  end

  describe "#search_cities" do
    it "returns formatted city search results" do
      result = agent.search_cities("London")

      expect(result[:success]).to be true
      expect(result[:cities]).to be_an(Array)
      expect(result[:count]).to eq(1)
      expect(result[:message]).to include("Found 1 cities")
    end

    it "handles no results" do
      allow_any_instance_of(WeatherService).to receive(:search_cities).and_return({
        success: true,
        cities: [],
        count: 0
      })

      result = agent.search_cities("NonexistentCity")

      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
      expect(result[:message]).to include("No cities found")
    end
  end

  describe "#process_natural_language" do
    it "handles current weather requests" do
      result = agent.process_natural_language("What's the weather in London?")

      expect(result[:action]).to eq("current_weather")
      expect(result[:message]).to include("Current weather in London")
    end

    it "handles forecast requests" do
      result = agent.process_natural_language("Show me the forecast for London")

      expect(result[:action]).to eq("forecast")
      expect(result[:message]).to include("forecast for London")
    end

    it "handles city search requests" do
      result = agent.process_natural_language("Search for cities like London")

      expect(result[:action]).to eq("city_search")
      expect(result[:message]).to include("Found 1 cities")
    end

    it "provides help for unknown requests" do
      result = agent.process_natural_language("hello there")

      expect(result[:action]).to eq("help")
      expect(result[:message]).to include("I can help you with weather information")
      expect(result[:suggestions]).to be_an(Array)
    end

    it "extracts location from natural language" do
      test_cases = [
        { input: "weather in Paris", expected_location: "Paris" },
        { input: "What's the temperature for Tokyo", expected_location: "Tokyo" },
        { input: "forecast for New York, USA", expected_location: "New York, USA" }
      ]

      test_cases.each do |test_case|
        result = agent.process_natural_language(test_case[:input])
        expect(result[:location]).to eq(test_case[:expected_location])
      end
    end

    it "extracts forecast days from text" do
      result = agent.process_natural_language("3 day forecast for London")

      expect(result[:days]).to eq(3)
    end
  end

  describe "private methods" do
    describe "#extract_location_from_text" do
      it "extracts location from various text patterns" do
        agent_instance = agent
        
        # Test various patterns
        expect(agent_instance.send(:extract_location_from_text, "weather in London")).to eq("London")
        expect(agent_instance.send(:extract_location_from_text, "forecast for Paris, France")).to eq("Paris, France")
        expect(agent_instance.send(:extract_location_from_text, "temperature at Tokyo")).to eq("Tokyo")
      end
    end

    describe "#extract_days_from_text" do
      it "extracts number of days from text" do
        agent_instance = agent
        
        expect(agent_instance.send(:extract_days_from_text, "5 day forecast")).to eq(5)
        expect(agent_instance.send(:extract_days_from_text, "tomorrow")).to eq(1)
        expect(agent_instance.send(:extract_days_from_text, "next week")).to eq(5)
        expect(agent_instance.send(:extract_days_from_text, "forecast")).to eq(3) # default
      end
    end
  end
end