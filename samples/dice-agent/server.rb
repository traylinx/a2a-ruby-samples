#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "a2a"
require "puma"
require "rack"
require "json"
require_relative "dice_agent"

# Dice Agent A2A Implementation
class DiceAgentA2A
  include A2A::Server::Agent

  def initialize
    @dice_agent = DiceAgent.new
  end

  # Define agent capabilities
  a2a_capability "dice_rolling" do
    method "roll_dice"
    description "Rolls an N sided dice and returns the result. By default uses a 6 sided dice."
    tags ["dice", "rolling", "random", "games"]
    input_schema type: "object", properties: { 
      sides: { type: "integer", minimum: 1, maximum: 100, default: 6 },
      count: { type: "integer", minimum: 1, maximum: 10, default: 1 }
    }
    output_schema type: "object", properties: {
      rolls: { type: "array", items: { type: "integer" } },
      sides: { type: "integer" },
      count: { type: "integer" },
      sum: { type: "integer" }
    }
  end

  a2a_capability "prime_detection" do
    method "check_prime"
    description "Determines which numbers from a list are prime numbers."
    tags ["prime", "numbers", "mathematics"]
    input_schema type: "object", properties: {
      numbers: { type: "array", items: { type: "integer" } }
    }
    output_schema type: "object", properties: {
      results: { type: "array" },
      prime_count: { type: "integer" },
      total_checked: { type: "integer" }
    }
  end

  # Define A2A methods
  a2a_method "roll_dice" do |params|
    sides = params[:sides] || params[:N] || 6
    count = params[:count] || 1
    @dice_agent.roll_dice(sides, count)
  end

  a2a_method "check_prime" do |params|
    numbers = params[:numbers] || params[:nums] || []
    @dice_agent.check_prime(numbers)
  end

  a2a_method "get_statistics" do |_params|
    @dice_agent.get_statistics
  end

  a2a_method "reset_stats" do |_params|
    @dice_agent.reset_stats
  end

  # Handle generic message sending
  a2a_method "message/send" do |params|
    message = params[:message]
    user_text = message[:parts]&.first&.dig(:text) || ""

    # Process the natural language input
    result = @dice_agent.process_natural_language(user_text)

    # Create response message
    A2A::Types::Message.new(
      message_id: SecureRandom.uuid,
      role: "agent",
      parts: [
        A2A::Types::TextPart.new(
          text: result[:message]
        )
      ]
    )
  end

  # Generate agent card
  def generate_agent_card(_context = nil)
    A2A::Types::AgentCard.new(
      name: "Dice Agent",
      description: "An interactive dice rolling and prime number checking agent",
      version: "1.0.0",
      url: "http://localhost:10101",
      preferred_transport: "JSONRPC",
      default_input_modes: ["text"],
      default_output_modes: ["text"],
      capabilities: A2A::Types::AgentCapabilities.new(streaming: false),
      skills: generate_skills_from_capabilities
    )
  end

  private

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
class DiceAgentApp
  def initialize
    @agent = DiceAgentA2A.new
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
      json_request = A2A::Protocol::JsonRpc.parse_request(body)

      response = @handler.handle_request(json_request)

      [
        200,
        {
          "Content-Type" => "application/json",
          "Access-Control-Allow-Origin" => "*"
        },
        [response.to_json]
      ]
    rescue A2A::Errors::A2AError => e
      error_response(400, e.message, e.to_json_rpc_error)
    rescue StandardError => e
      error_response(500, "Internal server error: #{e.message}")
    end
  end

  def handle_health(_request)
    [
      200,
      { "Content-Type" => "application/json" },
      [{ status: "healthy", timestamp: Time.now.utc.iso8601 }.to_json]
    ]
  end

  def handle_root(_request)
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Dice Agent - A2A Ruby Sample</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; }
          .endpoint { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 5px; }
          .example { background: #e8f4f8; padding: 10px; margin: 10px 0; border-radius: 5px; }
          code { background: #e8e8e8; padding: 2px 4px; border-radius: 3px; }
        </style>
      </head>
      <body>
        <h1>🎲 Dice Agent - A2A Ruby Sample</h1>
        <p>An interactive dice rolling and prime number checking agent built with the A2A Ruby SDK.</p>

        <h2>Features:</h2>
        <ul>
          <li>🎲 Roll N-sided dice (1-100 sides, up to 10 dice)</li>
          <li>🔢 Check if numbers are prime</li>
          <li>📊 Track rolling statistics</li>
          <li>💬 Natural language processing</li>
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
          Health check endpoint
        </div>

        <h2>Test the Agent:</h2>
        <p>Run the client: <code>ruby client.rb</code></p>

        <h2>Example Requests:</h2>
        <div class="example">
          <strong>Roll a 20-sided dice:</strong>
          <pre>curl -X POST http://localhost:10101/a2a/rpc \\
  -H "Content-Type: application/json" \\
  -d '{
    "jsonrpc": "2.0",
    "method": "roll_dice",
    "params": {"sides": 20},
    "id": 1
  }'</pre>
        </div>

        <div class="example">
          <strong>Check if numbers are prime:</strong>
          <pre>curl -X POST http://localhost:10101/a2a/rpc \\
  -H "Content-Type: application/json" \\
  -d '{
    "jsonrpc": "2.0",
    "method": "check_prime",
    "params": {"numbers": [7, 8, 9, 11]},
    "id": 2
  }'</pre>
        </div>

        <div class="example">
          <strong>Natural language message:</strong>
          <pre>curl -X POST http://localhost:10101/a2a/rpc \\
  -H "Content-Type: application/json" \\
  -d '{
    "jsonrpc": "2.0",
    "method": "message/send",
    "params": {
      "message": {
        "messageId": "test-123",
        "role": "user",
        "parts": [{"kind": "text", "text": "Roll two 12-sided dice"}]
      }
    },
    "id": 3
  }'</pre>
        </div>
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
  port = ENV.fetch("PORT", 10101).to_i
  host = ENV.fetch("HOST", "0.0.0.0")

  puts "🎲 Starting Dice Agent A2A Server..."
  puts "📡 Server running on http://#{host}:#{port}"
  puts "🤖 Agent card: http://#{host}:#{port}/a2a/agent-card"
  puts "🔧 JSON-RPC endpoint: http://#{host}:#{port}/a2a/rpc"
  puts "❤️  Health check: http://#{host}:#{port}/health"
  puts "🌐 Web interface: http://#{host}:#{port}/"
  puts
  puts "Press Ctrl+C to stop the server"

  app = DiceAgentApp.new

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