# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Source::Tokenizer do
  def tokenize(src)
    described_class.new(StringIO.new(src.b)).tap { |t| yield t }
  end

  it "tokenises an integer" do
    tokenize("42") do |t|
      tok = t.next_token
      expect(tok.type).to eq(:integer)
      expect(tok.value).to eq(42)
    end
  end

  it "tokenises a real" do
    tokenize("3.14") do |t|
      expect(t.next_token.value).to eq(3.14)
    end
  end

  it "tokenises a name" do
    tokenize("/Type") do |t|
      tok = t.next_token
      expect(tok.type).to eq(:name)
      expect(tok.value).to eq("Type".b)
    end
  end

  it "tokenises a name with #-escapes (decoded inline)" do
    tokenize("/A#42B") do |t|
      # Tokenizer decodes #xx; the value is the post-decode byte string.
      expect(t.next_token.value).to eq("ABB".b)
    end
  end

  it "tokenises a literal string with balanced parens" do
    tokenize("(Hello (world))") do |t|
      tok = t.next_token
      expect(tok.type).to eq(:string)
      expect(tok.value).to eq("Hello (world)".b)
    end
  end

  it "decodes string escapes" do
    tokenize("(a\\nb\\tc\\(d\\))") do |t|
      v = t.next_token.value
      expect(v).to eq("a\nb\tc(d)".b)
    end
  end

  it "tokenises a hex string" do
    tokenize("<48656c6c6f>") do |t|
      tok = t.next_token
      expect(tok.type).to eq(:hex_string)
      expect(tok.value).to eq("Hello".b)
    end
  end

  it "tokenises dict delimiters" do
    tokenize("<<>>") do |t|
      expect(t.next_token.type).to eq(:dict_open)
      expect(t.next_token.type).to eq(:dict_close)
    end
  end

  it "tokenises array delimiters" do
    tokenize("[]") do |t|
      expect(t.next_token.type).to eq(:array_open)
      expect(t.next_token.type).to eq(:array_close)
    end
  end

  it "tokenises booleans and null" do
    tokenize("true false null") do |t|
      expect(t.next_token).to have_attributes(type: :true, value: true)
      expect(t.next_token).to have_attributes(type: :false, value: false)
      expect(t.next_token).to have_attributes(type: :null, value: nil)
    end
  end

  it "tokenises keywords" do
    tokenize("obj endobj R") do |t|
      expect(t.next_token.value).to eq("obj")
      expect(t.next_token.value).to eq("endobj")
      expect(t.next_token.value).to eq("R")
    end
  end

  it "ignores comments" do
    tokenize("% a comment\n42") do |t|
      expect(t.next_token.value).to eq(42)
    end
  end

  it "supports peek without consuming" do
    tokenize("1 2") do |t|
      expect(t.peek.value).to eq(1)
      expect(t.peek.value).to eq(1)
      expect(t.next_token.value).to eq(1)
    end
  end

  it "supports pushback" do
    tokenize("1") do |t|
      tok = t.next_token
      t.pushback(tok)
      expect(t.next_token.value).to eq(1)
    end
  end
end
