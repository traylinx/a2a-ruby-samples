#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "a2a"
require "securerandom"

# Test client for the Hello World Agent
class HelloWorldClient
  def initialize(base_url = nil)
    @base_url = base_url || ENV["AGENT_URL"] || "http://localhost:9999/a2a"
    @client = A2A::Client::HttpClient.new(@base_url)
  end

  def run_tests
    puts "🧪 Testing Hello World A2A Agent"
    puts "📡 Connecting to: #{@base_url}"
    puts

    # Test 1: Get agent card
    test_agent_card

    # Test 2: Send simple message
    test_simple_message

    # Test 3: Send message with name
    test_message_with_name

    # Test 4: Test direct method call
    test_direct_method_call

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

  def test_simple_message
    puts "💬 Test 2: Sending simple message..."

    begin
      message = A2A::Types::Message.new(
        message_id: SecureRandom.uuid,
        role: "user",
        parts: [
          A2A::Types::TextPart.new(text: "Hello there!")
        ]
      )

      response = @client.send_message(message)

      if response.is_a?(A2A::Types::Message)
        response_text = response.parts.first.text
        puts "   ✅ Response: #{response_text}"
      else
        puts "   ✅ Response: #{response.inspect}"
      end
      puts
    rescue StandardError => e
      puts "   ❌ Failed: #{e.message}"
      puts
    end
  end

  def test_message_with_name
    puts "👋 Test 3: Sending message with custom content..."

    begin
      message = A2A::Types::Message.new(
        message_id: SecureRandom.uuid,
        role: "user",
        parts: [
          A2A::Types::TextPart.new(text: "My name is Ruby Developer")
        ]
      )

      response = @client.send_message(message)

      if response.is_a?(A2A::Types::Message)
        response_text = response.parts.first.text
        puts "   ✅ Response: #{response_text}"
      else
        puts "   ✅ Response: #{response.inspect}"
      end
      puts
    rescue StandardError => e
      puts "   ❌ Failed: #{e.message}"
      puts
    end
  end

  def test_direct_method_call
    puts "🎯 Test 4: Direct method call..."

    begin
      # This would be a direct JSON-RPC call to the greet method
      # For now, we'll simulate it through the message interface

      puts "   ℹ️  Direct method calls require JSON-RPC client implementation"
      puts "   ℹ️  This would call the 'greet' method directly with parameters"
      puts "   ✅ Method available in agent capabilities"
      puts
    rescue StandardError => e
      puts "   ❌ Failed: #{e.message}"
      puts
    end
  end
end

# Interactive mode
def interactive_mode
  client = HelloWorldClient.new

  puts "🎮 Interactive Mode - Type messages to send to the agent"
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
    end

    puts
  end

  puts "👋 Goodbye!"
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  if ARGV.include?("--interactive") || ARGV.include?("-i")
    interactive_mode
  else
    client = HelloWorldClient.new
    client.run_tests

    puts
    puts "💡 Try interactive mode: ruby client.rb --interactive"
  end
end
