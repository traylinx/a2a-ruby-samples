# frozen_string_literal: true

require "spec_helper"
require "rack/test"
require "json"
require_relative "../server"

RSpec.describe DiceAgentApp do
  include Rack::Test::Methods

  def app
    DiceAgentApp.new
  end

  describe "GET /" do
    it "returns the web interface" do
      get "/"
      
      expect(last_response).to be_ok
      expect(last_response.content_type).to include("text/html")
      expect(last_response.body).to include("Dice Agent")
    end
  end

  describe "GET /health" do
    it "returns health status" do
      get "/health"
      
      expect(last_response).to be_ok
      expect(last_response.content_type).to include("application/json")
      
      body = JSON.parse(last_response.body)
      expect(body).to include("status", "timestamp")
      expect(body["status"]).to eq("healthy")
    end
  end

  describe "GET /a2a/agent-card" do
    it "returns the agent card" do
      get "/a2a/agent-card"
      
      expect(last_response).to be_ok
      expect(last_response.content_type).to include("application/json")
      
      body = JSON.parse(last_response.body)
      expect(body).to include("name", "description", "skills", "capabilities")
      expect(body["skills"]).to be_an(Array)
    end
  end

  describe "POST /a2a/rpc" do
    it "handles roll_dice method calls" do
      request_body = {
        jsonrpc: "2.0",
        method: "roll_dice",
        params: { sides: 20 },
        id: 1
      }.to_json

      post "/a2a/rpc", request_body, { "CONTENT_TYPE" => "application/json" }
      
      expect(last_response).to be_ok
      expect(last_response.content_type).to include("application/json")
      
      body = JSON.parse(last_response.body)
      expect(body).to include("jsonrpc", "result", "id")
      expect(body["result"]).to include("rolls", "sides")
      expect(body["result"]["sides"]).to eq(20)
    end

    it "handles check_prime method calls" do
      request_body = {
        jsonrpc: "2.0",
        method: "check_prime",
        params: { numbers: [17, 18, 19] },
        id: 2
      }.to_json

      post "/a2a/rpc", request_body, { "CONTENT_TYPE" => "application/json" }
      
      expect(last_response).to be_ok
      
      body = JSON.parse(last_response.body)
      expect(body["result"]).to include("results", "prime_count")
      expect(body["result"]["results"]).to be_an(Array)
      expect(body["result"]["results"].length).to eq(3)
    end

    it "handles message/send method calls" do
      request_body = {
        jsonrpc: "2.0",
        method: "message/send",
        params: {
          message: {
            messageId: "test-123",
            role: "user",
            parts: [{ kind: "text", text: "roll a dice" }]
          }
        },
        id: 3
      }.to_json

      post "/a2a/rpc", request_body, { "CONTENT_TYPE" => "application/json" }
      
      expect(last_response).to be_ok
      
      body = JSON.parse(last_response.body)
      expect(body["result"]).to include("messageId", "role", "parts")
      expect(body["result"]["role"]).to eq("agent")
    end

    it "returns error for invalid JSON-RPC requests" do
      request_body = { invalid: "request" }.to_json

      post "/a2a/rpc", request_body, { "CONTENT_TYPE" => "application/json" }
      
      expect(last_response.status).to eq(400)
      
      body = JSON.parse(last_response.body)
      expect(body).to include("error")
    end

    it "returns method not allowed for GET requests" do
      get "/a2a/rpc"
      
      expect(last_response.status).to eq(405)
    end
  end

  describe "404 handling" do
    it "returns 404 for unknown paths" do
      get "/unknown-path"
      
      expect(last_response.status).to eq(404)
      expect(last_response.content_type).to include("application/json")
      
      body = JSON.parse(last_response.body)
      expect(body["error"]).to eq("Not found")
    end
  end
end