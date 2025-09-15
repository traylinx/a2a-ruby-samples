#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "a2a"
require "securerandom"

# Test client for the Dice Agent
class DiceAgentClient
  def initialize(base_url = nil)
    @base_url = base_url || ENV["AGENT_URL"] || "http://localhost:10101/a2a"
    @client = A2A::Client::HttpClient.new(@base_url)
  end

  def run_tests
    puts "🎲 Testing Dice Agent A2A Server"
    puts "📡 Connecting to: #{@base_url}"
    puts

    # Test 1: Get agent card
    test_agent_card

    # Test 2: Roll a simple dice
    test_simple_dice_roll

    # Test 3: Roll multiple dice
    test_multiple_dice_roll

    # Test 4: Check prime numbers
    test_prime_checking

    # Test 5: Natural language processing
    test_natural_language

    # Test 6: Get statistics
    test_statistics

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

  def test_simple_dice_roll
    puts "🎲 Test 2: Rolling a simple 6-sided dice..."

    begin
      # Direct method call via JSON-RPC
      response = @client.call_method("roll_dice", { sides: 6 })

      puts "   ✅ Roll result: #{response[:rolls].first} (#{response[:sides]}-sided dice)"
      puts "   ✅ Roll ID: #{response[:roll_id]}"
      puts "   ✅ Timestamp: #{response[:timestamp]}"
      puts
    rescue StandardError => e
      puts "   ❌ Failed: #{e.message}"
      puts
    end
  end

  def test_multiple_dice_roll
    puts "🎲 Test 3: Rolling multiple 20-sided dice..."

    begin
      response = @client.call_method("roll_dice", { sides: 20, count: 3 })

      puts "   ✅ Rolls: #{response[:rolls].join(', ')}"
      puts "   ✅ Sum: #{response[:sum]}"
      puts "   ✅ Count: #{response[:count]} dice"
      puts
    rescue StandardError => e
      puts "   ❌ Failed: #{e.message}"
      puts
    end
  end

  def test_prime_checking
    puts "🔢 Test 4: Checking prime numbers..."

    begin
      test_numbers = [2, 3, 4, 5, 17, 25, 29]
      response = @client.call_method("check_prime", { numbers: test_numbers })

      puts "   ✅ Checked numbers: #{test_numbers.join(', ')}"
      puts "   ✅ Prime count: #{response[:prime_count]}/#{response[:total_checked]}"

      response[:results].each do |result|
        status = result[:is_prime] ? "✨ PRIME" : "❌ NOT PRIME"
        puts "   #{status}: #{result[:number]} - #{result[:explanation]}"
      end
      puts
    rescue StandardError => e
      puts "   ❌ Failed: #{e.message}"
      puts
    end
  end

  def test_natural_language
    puts "💬 Test 5: Natural language processing..."

    test_messages = [
      "Roll a 12-sided dice",
      "Check if 13 is prime",
      "Show my statistics"
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
          puts "      → #{response_text}"
        else
          puts "   #{index + 1}. \"#{text}\" → #{response.inspect}"
        end
      rescue StandardError => e
        puts "   #{index + 1}. \"#{text}\" → ❌ Failed: #{e.message}"
      end
    end
    puts
  end

  def test_statistics
    puts "📊 Test 6: Getting statistics..."

    begin
      response = @client.call_method("get_statistics", {})

      if response[:message]
        puts "   ℹ️  #{response[:message]}"
      else
        puts "   ✅ Total rolls: #{response[:total_rolls]}"
        puts "   ✅ Average roll: #{response[:average_roll]}"
        puts "   ✅ Highest roll: #{response[:highest_roll]}"
        puts "   ✅ Lowest roll: #{response[:lowest_roll]}"
        puts "   ✅ Recent rolls: #{response[:recent_rolls].map { |r| r[:roll] }.join(', ')}"
      end
      puts
    rescue StandardError => e
      puts "   ❌ Failed: #{e.message}"
      puts
    end
  end
end

# Interactive mode
def interactive_mode
  client = DiceAgentClient.new

  puts "🎮 Interactive Dice Agent Mode"
  puts "Type messages to interact with the dice agent"
  puts "Examples:"
  puts "  - 'Roll a 20-sided dice'"
  puts "  - 'Check if 17 is prime'"
  puts "  - 'Show my statistics'"
  puts "  - 'Roll two d12'"
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

# Cross-stack testing mode
def cross_stack_test
  puts "🔄 Cross-Stack Testing Mode"
  puts "Testing Ruby client against Python dice agent..."
  puts

  # Test against Python agent (assuming it's running on port 9999)
  python_client = DiceAgentClient.new("http://localhost:9999/a2a")

  begin
    puts "📡 Testing connection to Python agent..."
    agent_card = python_client.instance_variable_get(:@client).get_card
    puts "✅ Connected to Python agent: #{agent_card.name}"

    # Test message sending
    message = A2A::Types::Message.new(
      message_id: SecureRandom.uuid,
      role: "user",
      parts: [A2A::Types::TextPart.new(text: "Roll a 6-sided dice")]
    )

    response = python_client.instance_variable_get(:@client).send_message(message)
    puts "✅ Cross-stack message test successful!"
    puts "   Response: #{response.parts.first.text}" if response.is_a?(A2A::Types::Message)

  rescue StandardError => e
    puts "❌ Cross-stack test failed: #{e.message}"
    puts "   Make sure the Python dice agent is running on port 9999"
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  case ARGV.first
  when "--interactive", "-i"
    interactive_mode
  when "--cross-stack", "-x"
    cross_stack_test
  else
    client = DiceAgentClient.new
    client.run_tests

    puts
    puts "💡 Try interactive mode: ruby client.rb --interactive"
    puts "💡 Try cross-stack testing: ruby client.rb --cross-stack"
  end
end