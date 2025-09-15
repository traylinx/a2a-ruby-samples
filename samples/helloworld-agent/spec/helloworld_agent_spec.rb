# frozen_string_literal: true

require "spec_helper"
require_relative "../server"

RSpec.describe HelloWorldAgent do
  let(:agent) { HelloWorldAgent.new }

  describe "#generate_agent_card" do
    it "generates a valid agent card" do
      card = agent.generate_agent_card

      expect(card).to be_a(A2A::Types::AgentCard)
      expect(card.name).to eq("HelloWorldAgent")
      expect(card.description).to include("Hello World")
      expect(card.skills).not_to be_empty
      expect(card.capabilities).not_to be_empty
    end

    it "includes greeting skill" do
      card = agent.generate_agent_card
      greeting_skill = card.skills.find { |skill| skill.name == "greeting" }

      expect(greeting_skill).not_to be_nil
      expect(greeting_skill.description).to include("greeting")
      expect(greeting_skill.tags).to include("greeting")
    end
  end

  describe "A2A methods" do
    describe "greet method" do
      it "returns hello message with default name" do
        result = agent.handle_a2a_method("greet", {})

        expect(result).to be_a(Hash)
        expect(result[:message]).to eq("Hello World!")
        expect(result[:agent]).to eq("HelloWorldAgent")
      end

      it "returns hello message with custom name" do
        result = agent.handle_a2a_method("greet", { name: "Ruby" })

        expect(result).to be_a(Hash)
        expect(result[:message]).to eq("Hello Ruby!")
        expect(result[:agent]).to eq("HelloWorldAgent")
      end
    end

    describe "message/send method" do
      it "handles message with text part" do
        message_params = {
          message: {
            messageId: "test-123",
            role: "user",
            parts: [{ kind: "text", text: "Hello agent!" }]
          }
        }

        result = agent.handle_a2a_method("message/send", message_params)

        expect(result).to be_a(A2A::Types::Message)
        expect(result.role).to eq("agent")
        expect(result.parts.first.text).to include("Hello World!")
        expect(result.parts.first.text).to include("Hello agent!")
      end

      it "handles message without text" do
        message_params = {
          message: {
            messageId: "test-456",
            role: "user",
            parts: []
          }
        }

        result = agent.handle_a2a_method("message/send", message_params)

        expect(result).to be_a(A2A::Types::Message)
        expect(result.parts.first.text).to include("Hello World!")
        expect(result.parts.first.text).to include("there")
      end
    end
  end
end

RSpec.describe HelloWorldApp do
  let(:app) { HelloWorldApp.new }

  def make_request(method, path, body = nil, headers = {})
    env = Rack::MockRequest.env_for(path, {
      method: method,
      input: body,
      "CONTENT_TYPE" => headers["Content-Type"] || "application/json"
    }.merge(headers))

    app.call(env)
  end

  describe "GET /a2a/agent-card" do
    it "returns agent card" do
      status, headers, body = make_request("GET", "/a2a/agent-card")

      expect(status).to eq(200)
      expect(headers["Content-Type"]).to eq("application/json")

      card_data = JSON.parse(body.first)
      expect(card_data["name"]).to eq("HelloWorldAgent")
      expect(card_data["skills"]).not_to be_empty
    end
  end

  describe "POST /a2a/rpc" do
    it "handles valid JSON-RPC request" do
      request_body = {
        jsonrpc: "2.0",
        method: "greet",
        params: { name: "Test" },
        id: 1
      }.to_json

      status, headers, body = make_request("POST", "/a2a/rpc", request_body)

      expect(status).to eq(200)
      expect(headers["Content-Type"]).to eq("application/json")

      response = JSON.parse(body.first)
      expect(response["jsonrpc"]).to eq("2.0")
      expect(response["id"]).to eq(1)
      expect(response["result"]["message"]).to eq("Hello Test!")
    end

    it "handles message/send request" do
      request_body = {
        jsonrpc: "2.0",
        method: "message/send",
        params: {
          message: {
            messageId: "test-789",
            role: "user",
            parts: [{ kind: "text", text: "Hi there!" }]
          }
        },
        id: 2
      }.to_json

      status, _, body = make_request("POST", "/a2a/rpc", request_body)

      expect(status).to eq(200)

      response = JSON.parse(body.first)
      expect(response["jsonrpc"]).to eq("2.0")
      expect(response["result"]["parts"].first["text"]).to include("Hello World!")
    end

    it "returns error for invalid JSON" do
      status, _, body = make_request("POST", "/a2a/rpc", "invalid json")

      expect(status).to eq(400)

      response = JSON.parse(body.first)
      expect(response["error"]).to include("Invalid JSON")
    end
  end

  describe "GET /health" do
    it "returns health status" do
      status, headers, body = make_request("GET", "/health")

      expect(status).to eq(200)
      expect(headers["Content-Type"]).to eq("application/json")

      health = JSON.parse(body.first)
      expect(health["status"]).to eq("healthy")
      expect(health["timestamp"]).not_to be_nil
    end
  end

  describe "GET /" do
    it "returns HTML interface" do
      status, headers, body = make_request("GET", "/")

      expect(status).to eq(200)
      expect(headers["Content-Type"]).to eq("text/html")
      expect(body.first).to include("Hello World A2A Agent")
    end
  end

  describe "unknown routes" do
    it "returns 404 for unknown paths" do
      status, headers, = make_request("GET", "/unknown")

      expect(status).to eq(404)
      expect(headers["Content-Type"]).to eq("application/json")
    end
  end
end
