# frozen_string_literal: true

require "spec_helper"
require_relative "../dice_agent"

RSpec.describe DiceAgent do
  let(:agent) { described_class.new }

  describe "#roll_dice" do
    it "rolls a 6-sided dice by default" do
      result = agent.roll_dice
      
      expect(result).to include(:rolls, :sides, :count, :sum, :timestamp, :roll_id)
      expect(result[:sides]).to eq(6)
      expect(result[:count]).to eq(1)
      expect(result[:rolls]).to be_an(Array)
      expect(result[:rolls].first).to be_between(1, 6)
    end

    it "rolls dice with specified sides" do
      result = agent.roll_dice(20)
      
      expect(result[:sides]).to eq(20)
      expect(result[:rolls].first).to be_between(1, 20)
    end

    it "rolls multiple dice" do
      result = agent.roll_dice(6, 3)
      
      expect(result[:count]).to eq(3)
      expect(result[:rolls].length).to eq(3)
      expect(result[:sum]).to eq(result[:rolls].sum)
    end

    it "validates input parameters" do
      expect { agent.roll_dice(0) }.to raise_error(ArgumentError, "Dice must have at least 1 side")
      expect { agent.roll_dice(101) }.to raise_error(ArgumentError, "Dice must have at most 100 sides")
      expect { agent.roll_dice(6, 0) }.to raise_error(ArgumentError, "Must roll at least 1 dice")
      expect { agent.roll_dice(6, 11) }.to raise_error(ArgumentError, "Cannot roll more than 10 dice at once")
    end
  end

  describe "#check_prime" do
    it "correctly identifies prime numbers" do
      result = agent.check_prime([2, 3, 5, 7, 11])
      
      expect(result).to include(:results, :prime_count, :total_checked)
      expect(result[:prime_count]).to eq(5)
      expect(result[:total_checked]).to eq(5)
      
      result[:results].each do |r|
        expect(r[:is_prime]).to be true
      end
    end

    it "correctly identifies non-prime numbers" do
      result = agent.check_prime([4, 6, 8, 9, 10])
      
      expect(result[:prime_count]).to eq(0)
      expect(result[:total_checked]).to eq(5)
      
      result[:results].each do |r|
        expect(r[:is_prime]).to be false
      end
    end

    it "handles mixed prime and non-prime numbers" do
      result = agent.check_prime([2, 4, 7, 8, 11])
      
      expect(result[:prime_count]).to eq(3) # 2, 7, 11 are prime
      expect(result[:total_checked]).to eq(5)
    end

    it "handles edge cases" do
      result = agent.check_prime([0, 1, 2])
      
      expect(result[:prime_count]).to eq(1) # Only 2 is prime
      
      prime_results = result[:results].select { |r| r[:is_prime] }
      expect(prime_results.map { |r| r[:number] }).to eq([2])
    end

    it "accepts single numbers" do
      result = agent.check_prime(17)
      
      expect(result[:prime_count]).to eq(1)
      expect(result[:results].first[:number]).to eq(17)
      expect(result[:results].first[:is_prime]).to be true
    end
  end

  describe "#get_statistics" do
    it "returns empty message when no rolls recorded" do
      result = agent.get_statistics
      
      expect(result).to include(:message)
      expect(result[:message]).to eq("No rolls recorded yet")
    end

    it "returns statistics after rolling dice" do
      agent.roll_dice(6, 2)
      agent.roll_dice(20, 1)
      
      result = agent.get_statistics
      
      expect(result).to include(:total_rolls, :average_roll, :highest_roll, :lowest_roll, :recent_rolls, :total_sum)
      expect(result[:total_rolls]).to eq(3)
      expect(result[:recent_rolls].length).to eq(3)
    end
  end

  describe "#reset_stats" do
    it "resets all statistics" do
      agent.roll_dice(6, 3)
      
      # Verify stats exist
      stats_before = agent.get_statistics
      expect(stats_before[:total_rolls]).to eq(3)
      
      # Reset
      result = agent.reset_stats
      expect(result[:message]).to eq("Statistics reset successfully")
      
      # Verify stats are reset
      stats_after = agent.get_statistics
      expect(stats_after[:message]).to eq("No rolls recorded yet")
    end
  end

  describe "#process_natural_language" do
    it "handles dice rolling requests" do
      result = agent.process_natural_language("roll a 20-sided dice")
      
      expect(result).to include(:message, :result, :action)
      expect(result[:action]).to eq("roll_dice")
      expect(result[:result][:sides]).to eq(20)
    end

    it "handles prime checking requests" do
      result = agent.process_natural_language("check if 17 is prime")
      
      expect(result[:action]).to eq("check_prime")
      expect(result[:result][:results].first[:number]).to eq(17)
    end

    it "handles statistics requests" do
      result = agent.process_natural_language("show my stats")
      
      expect(result[:action]).to eq("get_statistics")
    end

    it "handles reset requests" do
      result = agent.process_natural_language("reset my statistics")
      
      expect(result[:action]).to eq("reset_stats")
    end

    it "provides suggestions for unknown requests" do
      result = agent.process_natural_language("hello there")
      
      expect(result).to include(:message, :suggestions)
      expect(result[:suggestions]).to be_an(Array)
    end
  end
end