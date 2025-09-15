# frozen_string_literal: true

require 'securerandom'

# Core dice rolling and mathematical operations agent
class DiceAgent
  def initialize
    @roll_history = []
    @stats = {
      total_rolls: 0,
      total_sum: 0,
      highest_roll: 0,
      lowest_roll: Float::INFINITY
    }
  end
  
  # Roll an N-sided dice
  def roll_dice(sides = 6, count = 1)
    # Validate input
    sides = sides.to_i
    count = count.to_i
    
    raise ArgumentError, "Dice must have at least 1 side" if sides < 1
    raise ArgumentError, "Dice must have at most 100 sides" if sides > 100
    raise ArgumentError, "Must roll at least 1 dice" if count < 1
    raise ArgumentError, "Cannot roll more than 10 dice at once" if count > 10
    
    rolls = []
    count.times do
      roll = rand(1..sides)
      rolls << roll
      record_roll(roll, sides)
    end
    
    {
      rolls: rolls,
      sides: sides,
      count: count,
      sum: rolls.sum,
      timestamp: Time.now.utc.iso8601,
      roll_id: SecureRandom.hex(4)
    }
  end
  
  # Check if numbers are prime
  def check_prime(numbers)
    numbers = Array(numbers).map(&:to_i)
    
    results = numbers.map do |num|
      {
        number: num,
        is_prime: prime?(num),
        explanation: prime_explanation(num)
      }
    end
    
    {
      results: results,
      prime_count: results.count { |r| r[:is_prime] },
      total_checked: results.length
    }
  end
  
  # Get rolling statistics
  def get_statistics
    return { message: "No rolls recorded yet" } if @roll_history.empty?
    
    {
      total_rolls: @stats[:total_rolls],
      average_roll: (@stats[:total_sum].to_f / @stats[:total_rolls]).round(2),
      highest_roll: @stats[:highest_roll],
      lowest_roll: @stats[:lowest_roll] == Float::INFINITY ? 0 : @stats[:lowest_roll],
      recent_rolls: @roll_history.last(10),
      total_sum: @stats[:total_sum]
    }
  end
  
  # Reset statistics
  def reset_stats
    @roll_history.clear
    @stats = {
      total_rolls: 0,
      total_sum: 0,
      highest_roll: 0,
      lowest_roll: Float::INFINITY
    }
    
    { message: "Statistics reset successfully" }
  end
  
  # Process natural language input
  def process_natural_language(text)
    text = text.downcase.strip
    
    # Parse dice rolling requests
    if text.match?(/roll|dice|die/)
      return handle_dice_request(text)
    end
    
    # Parse prime checking requests
    if text.match?(/prime|check/)
      return handle_prime_request(text)
    end
    
    # Parse statistics requests
    if text.match?(/stat|history|average/)
      return handle_stats_request(text)
    end
    
    # Default response with suggestions
    {
      message: "I can help you with dice rolling and prime number checking!",
      suggestions: [
        "Roll a 6-sided dice",
        "Roll two 20-sided dice", 
        "Check if 17 is prime",
        "Show my rolling statistics",
        "Reset my statistics"
      ]
    }
  end
  
  private
  
  def record_roll(roll, sides)
    @roll_history << { roll: roll, sides: sides, timestamp: Time.now }
    @stats[:total_rolls] += 1
    @stats[:total_sum] += roll
    @stats[:highest_roll] = [@stats[:highest_roll], roll].max
    @stats[:lowest_roll] = [@stats[:lowest_roll], roll].min
    
    # Keep only last 100 rolls
    @roll_history = @roll_history.last(100) if @roll_history.length > 100
  end
  
  def prime?(num)
    return false if num < 2
    return true if num == 2
    return false if num.even?
    
    (3..Math.sqrt(num)).step(2) do |i|
      return false if num % i == 0
    end
    
    true
  end
  
  def prime_explanation(num)
    return "Numbers less than 2 are not prime" if num < 2
    return "2 is the only even prime number" if num == 2
    return "Even numbers greater than 2 are not prime" if num > 2 && num.even?
    
    if prime?(num)
      "#{num} is prime (only divisible by 1 and #{num})"
    else
      # Find smallest factor
      factor = (3..Math.sqrt(num)).step(2).find { |i| num % i == 0 }
      if factor
        "#{num} is not prime (divisible by #{factor})"
      else
        "#{num} is not prime"
      end
    end
  end
  
  def handle_dice_request(text)
    # Extract number of sides
    sides_match = text.match(/(\d+)[- ]?sided?|d(\d+)/)
    sides = sides_match ? (sides_match[1] || sides_match[2]).to_i : 6
    
    # Extract number of dice
    count_match = text.match(/(\d+)\s+dice|roll\s+(\d+)|(\d+)\s+d\d+/)
    count = count_match ? (count_match[1] || count_match[2] || count_match[3]).to_i : 1
    
    # Limit reasonable values
    sides = [[sides, 1].max, 100].min
    count = [[count, 1].max, 10].min
    
    result = roll_dice(sides, count)
    
    # Generate friendly response
    dice_text = count == 1 ? "dice" : "#{count} dice"
    rolls_text = result[:rolls].length == 1 ? 
      "You rolled: #{result[:rolls].first}!" :
      "You rolled: #{result[:rolls].join(', ')} (sum: #{result[:sum]})"
    
    {
      message: "🎲 Rolling #{dice_text} with #{sides} sides... #{rolls_text}",
      result: result,
      action: "roll_dice"
    }
  end
  
  def handle_prime_request(text)
    # Extract numbers from text
    numbers = text.scan(/\d+/).map(&:to_i)
    
    if numbers.empty?
      # Check recent rolls if no numbers specified
      if @roll_history.any?
        recent_rolls = @roll_history.last(5).map { |h| h[:roll] }
        numbers = recent_rolls.uniq
      else
        return {
          message: "Please specify numbers to check, or roll some dice first!",
          action: "check_prime"
        }
      end
    end
    
    result = check_prime(numbers)
    
    # Generate friendly response
    prime_numbers = result[:results].select { |r| r[:is_prime] }.map { |r| r[:number] }
    non_prime_numbers = result[:results].reject { |r| r[:is_prime] }.map { |r| r[:number] }
    
    message_parts = []
    message_parts << "🔢 Checking #{numbers.join(', ')} for prime numbers..."
    
    if prime_numbers.any?
      message_parts << "✨ Prime: #{prime_numbers.join(', ')}"
    end
    
    if non_prime_numbers.any?
      message_parts << "❌ Not prime: #{non_prime_numbers.join(', ')}"
    end
    
    {
      message: message_parts.join("\n"),
      result: result,
      action: "check_prime"
    }
  end
  
  def handle_stats_request(text)
    if text.match?(/reset|clear/)
      result = reset_stats
      return {
        message: "📊 #{result[:message]}",
        action: "reset_stats"
      }
    end
    
    stats = get_statistics
    
    if stats[:message]
      return {
        message: "📊 #{stats[:message]}",
        action: "get_statistics"
      }
    end
    
    message = "📊 Your Rolling Statistics:\n" \
              "• Total rolls: #{stats[:total_rolls]}\n" \
              "• Average roll: #{stats[:average_roll]}\n" \
              "• Highest roll: #{stats[:highest_roll]}\n" \
              "• Lowest roll: #{stats[:lowest_roll]}\n" \
              "• Total sum: #{stats[:total_sum]}"
    
    {
      message: message,
      result: stats,
      action: "get_statistics"
    }
  end
end