# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Layout::Frame do
  let(:frame) { described_class.new(left: 0, bottom: 0, width: 100, height: 200) }

  describe "#find_available_area" do
    it "returns the top-left area when empty" do
      result = frame.find_available_area(50, 30)
      expect(result).to eq([0.0, 170.0, 50.0, 30.0])
    end

    it "returns nil when the requested area is too large" do
      expect(frame.find_available_area(150, 30)).to be_nil
      expect(frame.find_available_area(50, 250)).to be_nil
    end
  end

  describe "#remove_area" do
    it "advances the cursor downward" do
      frame.find_available_area(100, 50) # consumes top 50 pts
      frame.remove_area(0, 150, 100, 50)
      expect(frame.cursor_y).to eq(150.0)
    end

    it "subsequent find_available_area returns a position below the removed area" do
      frame.find_available_area(100, 50)
      frame.remove_area(0, 150, 100, 50)
      result = frame.find_available_area(100, 50)
      expect(result).not_to be_nil
      expect(result[1]).to be < 150.0
    end

    it "returns nil when all space is consumed" do
      frame.find_available_area(100, 200)
      frame.remove_area(0, 0, 100, 200)
      expect(frame.full?).to be true
      expect(frame.find_available_area(100, 10)).to be_nil
    end
  end

  describe "#reset!" do
    it "resets the cursor to top and clears removed areas" do
      frame.find_available_area(100, 50)
      frame.remove_area(0, 150, 100, 50)
      expect(frame.empty?).to be false
      frame.reset!
      expect(frame.empty?).to be true
      expect(frame.cursor_y).to eq(200.0)
    end
  end

  describe "#available_height" do
    it "returns the full height when empty" do
      expect(frame.available_height).to eq(200.0)
    end

    it "decreases after remove_area" do
      frame.remove_area(0, 150, 100, 50)
      expect(frame.available_height).to be <= 150.0
    end
  end

  describe "predicates" do
    it "starts empty" do
      expect(frame.empty?).to be true
      expect(frame.full?).to be false
    end

    it "becomes full when cursor reaches bottom" do
      frame.remove_area(0, 0, 100, 200)
      expect(frame.full?).to be true
      expect(frame.empty?).to be false
    end
  end
end
