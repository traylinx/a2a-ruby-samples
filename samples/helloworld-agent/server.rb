#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'a2a'
require 'puma'
require 'rack'
require 'json'

# Hello World Agent Implementation
class HelloWorldAgent
  include A2A::Server::Agent
  
  # Define agent skills for the agent card
  a2a_skill "greeting" do |skill|
    skill.description = "Simple greeting functionality that responds with hello messages"
    skill.tags = ["greeting", "hello", "basic", "demo"]
    skill.examples = [
      "Hello there!",
      "Say hello",
      "Greet me"
    ]
  end
  
  # Define the main A2A method
  a2a_method "greet" do |params|
    name = params[:name] || "World"
    {
      message: "Hello #{name}!",
      timestamp: Time.now.utc.iso8601,
      agent: "HelloWorldAgent"
    }
  end
  
  # Handle generic message sending
  a2a_method "message/send" do |params|
    message = params[:message]
    user_text = message[:parts]&.first&.dig(:text) || "there"
    
    # Create response message
    A2A::Types::Message.new(
      message_id: SecureRandom.uuid,
      role: "agent",
      parts: [
        A2A::Types::TextPart.new(
          text: "Hello World! You said: '#{user_text}'"
        )
      ]
    )
  end
end

# Rack application that handles A2A requests
class HelloWorldApp
  def initialize
    @agent = HelloWorldAgent.new
    @handler = A2A::Server::Handler.new(@agent)
  end
  
  def call(env)
    request = Rack::Request.new(env)
    
    case request.path_info
    when '/a2a/agent-card'
      handle_agent_card(request)
    when '/a2a/rpc'
      handle_rpc(request)
    when '/health'
      handle_health(request)
    when '/'
      handle_root(request)
    else
      [404, {'Content-Type' => 'application/json'}, ['{"error": "Not found"}']]
    end
  end
  
  private
  
  def handle_agent_card(request)
    begin
      agent_card = @agent.generate_agent_card
      [
        200,
        {
          'Content-Type' => 'application/json',
          'Access-Control-Allow-Origin' => '*'
        },
        [agent_card.to_json]
      ]
    rescue => e
      error_response(500, "Failed to generate agent card: #{e.message}")
    end
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
          'Content-Type' => 'application/json',
          'Access-Control-Allow-Origin' => '*'
        },
        [response.to_json]
      ]
    rescue A2A::Errors::A2AError => e
      error_response(400, e.message, e.to_json_rpc_error)
    rescue => e
      error_response(500, "Internal server error: #{e.message}")
    end
  end
  
  def handle_health(request)
    [
      200,
      {'Content-Type' => 'application/json'},
      [{ status: 'healthy', timestamp: Time.now.utc.iso8601 }.to_json]
    ]
  end
  
  def handle_root(request)
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Hello World A2A Agent</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; }
          .endpoint { background: #f5f5f5; padding: 10px; margin: 10px 0; border-radius: 5px; }
          code { background: #e8e8e8; padding: 2px 4px; border-radius: 3px; }
        </style>
      </head>
      <body>
        <h1>🤖 Hello World A2A Agent</h1>
        <p>This is a simple A2A agent built with the A2A Ruby SDK.</p>
        
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
        
        <h2>Manual Test:</h2>
        <pre>
curl -X POST http://localhost:9999/a2a/rpc \\
  -H "Content-Type: application/json" \\
  -d '{
    "jsonrpc": "2.0",
    "method": "message/send",
    "params": {
      "message": {
        "messageId": "test-123",
        "role": "user",
        "parts": [{"kind": "text", "text": "Hello!"}]
      }
    },
    "id": 1
  }'
        </pre>
      </body>
      </html>
    HTML
    
    [200, {'Content-Type' => 'text/html'}, [html]]
  end
  
  def method_not_allowed
    [405, {'Content-Type' => 'application/json'}, ['{"error": "Method not allowed"}']]
  end
  
  def error_response(status, message, json_rpc_error = nil)
    body = json_rpc_error || { error: message }
    [
      status,
      {'Content-Type' => 'application/json'},
      [body.to_json]
    ]
  end
end

# Start the server
if __FILE__ == $0
  port = ENV.fetch('PORT', 9999).to_i
  host = ENV.fetch('HOST', '0.0.0.0')
  
  puts "🚀 Starting Hello World A2A Agent..."
  puts "📡 Server running on http://#{host}:#{port}"
  puts "🤖 Agent card: http://#{host}:#{port}/a2a/agent-card"
  puts "🔧 JSON-RPC endpoint: http://#{host}:#{port}/a2a/rpc"
  puts "❤️  Health check: http://#{host}:#{port}/health"
  puts "🌐 Web interface: http://#{host}:#{port}/"
  puts
  puts "Press Ctrl+C to stop the server"
  
  app = HelloWorldApp.new
  
  # Configure Puma
  server = Puma::Server.new(app)
  server.add_tcp_listener(host, port)
  
  # Handle graceful shutdown
  trap('INT') do
    puts "\n🛑 Shutting down gracefully..."
    server.stop
    exit
  end
  
  server.run.join
end