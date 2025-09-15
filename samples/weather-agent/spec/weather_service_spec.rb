# frozen_string_literal: true

require "spec_helper"
require_relative "../weather_service"

RSpec.describe WeatherService do
  let(:api_key) { "test_api_key" }
  let(:service) { described_class.new(api_key) }

  describe "#initialize" do
    it "requires an API key" do
      expect { described_class.new(nil) }.to raise_error(ArgumentError, "Weather API key is required")
    end

    it "accepts an API key parameter" do
      expect { described_class.new("test_key") }.not_to raise_error
    end

    it "uses environment variable if no key provided" do
      ENV["WEATHER_API_KEY"] = "env_key"
      service = described_class.new
      expect(service.instance_variable_get(:@api_key)).to eq("env_key")
    end
  end

  describe "#get_current_weather", :vcr do
    it "returns current weather for a valid city" do
      stub_request(:get, /api.openweathermap.org/)
        .to_return(
          status: 200,
          body: {
            name: "London",
            sys: { country: "GB", sunrise: 1640000000, sunset: 1640030000 },
            coord: { lat: 51.5074, lon: -0.1278 },
            main: { temp: 15.2, feels_like: 14.8, humidity: 72, pressure: 1013 },
            weather: [{ main: "Clouds", description: "partly cloudy", icon: "02d" }],
            wind: { speed: 3.5, deg: 180 },
            clouds: { all: 40 },
            visibility: 10000
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = service.get_current_weather("London")

      expect(result[:success]).to be true
      expect(result[:location][:name]).to eq("London")
      expect(result[:location][:country]).to eq("GB")
      expect(result[:current][:temperature]).to eq(15.2)
      expect(result[:current][:condition][:description]).to eq("Partly cloudy")
    end

    it "handles API errors gracefully" do
      stub_request(:get, /api.openweathermap.org/)
        .to_return(status: 404, body: { message: "city not found" }.to_json)

      result = service.get_current_weather("InvalidCity")

      expect(result[:success]).to be false
      expect(result[:error]).to eq("Location not found")
    end

    it "handles network errors" do
      stub_request(:get, /api.openweathermap.org/)
        .to_raise(Faraday::ConnectionFailed)

      result = service.get_current_weather("London")

      expect(result[:success]).to be false
      expect(result[:error]).to include("Network error")
    end
  end

  describe "#get_forecast", :vcr do
    it "returns weather forecast for a valid city" do
      stub_request(:get, /api.openweathermap.org.*forecast/)
        .to_return(
          status: 200,
          body: {
            city: { name: "London", country: "GB", coord: { lat: 51.5074, lon: -0.1278 } },
            list: [
              {
                dt: 1640000000,
                main: { temp: 15.0, humidity: 70, pressure: 1015 },
                weather: [{ description: "clear sky" }],
                wind: { speed: 2.5 },
                rain: { "3h" => 0.5 }
              },
              {
                dt: 1640010800,
                main: { temp: 12.0, humidity: 75, pressure: 1012 },
                weather: [{ description: "light rain" }],
                wind: { speed: 3.0 },
                rain: { "3h" => 1.2 }
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = service.get_forecast("London", nil, 1)

      expect(result[:success]).to be true
      expect(result[:location][:name]).to eq("London")
      expect(result[:forecast]).to be_an(Array)
      expect(result[:forecast].first).to include(:date, :temperature, :condition)
    end
  end

  describe "#get_weather_by_coordinates" do
    it "returns weather for valid coordinates" do
      stub_request(:get, /api.openweathermap.org/)
        .with(query: hash_including(lat: "51.5074", lon: "-0.1278"))
        .to_return(
          status: 200,
          body: {
            name: "London",
            sys: { country: "GB", sunrise: 1640000000, sunset: 1640030000 },
            coord: { lat: 51.5074, lon: -0.1278 },
            main: { temp: 15.2, feels_like: 14.8, humidity: 72, pressure: 1013 },
            weather: [{ main: "Clear", description: "clear sky", icon: "01d" }],
            wind: { speed: 2.1, deg: 200 },
            clouds: { all: 0 },
            visibility: 10000
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = service.get_weather_by_coordinates(51.5074, -0.1278)

      expect(result[:success]).to be true
      expect(result[:location][:coordinates][:lat]).to eq(51.5074)
      expect(result[:location][:coordinates][:lon]).to eq(-0.1278)
    end
  end

  describe "#search_cities" do
    it "returns cities matching the search query" do
      stub_request(:get, /api.openweathermap.org.*geo.*direct/)
        .to_return(
          status: 200,
          body: [
            {
              name: "Paris",
              country: "FR",
              state: "Île-de-France",
              lat: 48.8566,
              lon: 2.3522
            },
            {
              name: "Paris",
              country: "US",
              state: "Texas",
              lat: 33.6617,
              lon: -95.5555
            }
          ].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = service.search_cities("Paris")

      expect(result[:success]).to be true
      expect(result[:cities]).to be_an(Array)
      expect(result[:cities].length).to eq(2)
      expect(result[:cities].first[:name]).to eq("Paris")
      expect(result[:cities].first[:display_name]).to include("Paris")
    end
  end

  describe "caching" do
    it "caches responses to avoid duplicate API calls" do
      # Enable caching for this test
      service.instance_variable_set(:@cache_ttl, 300)

      stub_request(:get, /api.openweathermap.org/)
        .to_return(
          status: 200,
          body: {
            name: "London",
            sys: { country: "GB", sunrise: 1640000000, sunset: 1640030000 },
            coord: { lat: 51.5074, lon: -0.1278 },
            main: { temp: 15.2, feels_like: 14.8, humidity: 72, pressure: 1013 },
            weather: [{ main: "Clear", description: "clear sky", icon: "01d" }],
            wind: { speed: 2.1, deg: 200 },
            clouds: { all: 0 }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # First call should make API request
      result1 = service.get_current_weather("London")
      expect(result1[:success]).to be true

      # Second call should use cache (no additional API request)
      result2 = service.get_current_weather("London")
      expect(result2[:success]).to be true

      # Verify only one request was made
      expect(WebMock).to have_requested(:get, /api.openweathermap.org/).once
    end
  end
end