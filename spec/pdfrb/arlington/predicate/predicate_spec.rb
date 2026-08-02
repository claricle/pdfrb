# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Arlington::Predicate::Lexer do
  def lex(src)
    described_class.tokenize(src).map(&:first)
  end

  it "tokenises a simple fn: call" do
    tokens = lex("fn:IsPresent(Type)")
    expect(tokens).to eq([:fn_call, :lparen, :name, :rparen])
  end

  it "tokenises @key" do
    tokens = described_class.tokenize("@Foo")
    expect(tokens).to eq([[:at_key, "Foo"]])
  end

  it "tokenises a path expression" do
    tokens = described_class.tokenize("trailer::Catalog::Pages")
    expect(tokens).to eq([[:path, "trailer::Catalog::Pages"]])
  end

  it "tokenises && and ||" do
    tokens = lex("a && b || c")
    expect(tokens).to eq([:name, :logic_and, :name, :logic_or, :name])
  end

  it "tokenises comparison operators" do
    tokens = lex("@Foo==Bar")
    expect(tokens).to eq([:at_key, :op, :name])
  end

  it "tokenises numbers" do
    tokens = described_class.tokenize("1.7")
    expect(tokens).to eq([[:number, "1.7"]])
  end

  it "tokenises quoted strings" do
    tokens = described_class.tokenize("'hello'")
    expect(tokens).to eq([[:string, "hello"]])
  end
end

RSpec.describe Pdfrb::Arlington::Predicate::Parser do
  def parse(src)
    described_class.parse(src)
  end

  it "parses a simple function call" do
    ast = parse("fn:IsPresent(Type)")
    expect(ast).to be_a(Pdfrb::Arlington::Predicate::AST::FunctionCall)
    expect(ast.name).to eq("fn:IsPresent")
    expect(ast.args.length).to eq(1)
  end

  it "parses a comparison" do
    ast = parse("@Type==Catalog")
    expect(ast).to be_a(Pdfrb::Arlington::Predicate::AST::BinOp)
    expect(ast.op).to eq(:==)
  end

  it "parses a parenthesised logical" do
    ast = parse("(@A==1 && @B==2)")
    expect(ast).to be_a(Pdfrb::Arlington::Predicate::AST::LogicalOp)
    expect(ast.op).to eq(:"&&")
  end

  it "parses nested function calls" do
    ast = parse("fn:IsRequired(fn:SinceVersion(2.0))")
    expect(ast).to be_a(Pdfrb::Arlington::Predicate::AST::FunctionCall)
    expect(ast.args.first).to be_a(Pdfrb::Arlington::Predicate::AST::FunctionCall)
  end
end

RSpec.describe Pdfrb::Arlington::Predicate::Evaluator do
  let(:dict) { { Type: :Catalog, Pages: nil } }
  let(:ctx) do
    Pdfrb::Arlington::Predicate::Context.new(
      current: dict,
      version: Pdfrb::Arlington::PdfVersion.new("2.0"),
      file_size: 1234
    )
  end

  def evaluate(src)
    ast = Pdfrb::Arlington::Predicate::Parser.parse(src)
    described_class.call(ast, ctx)
  end

  it "evaluates fn:IsPresent positively" do
    expect(evaluate("fn:IsPresent(Type)")).to be(true)
  end

  it "evaluates fn:IsPresent negatively" do
    expect(evaluate("fn:IsPresent(Missing)")).to be(false)
  end

  it "evaluates fn:NotPresent positively when absent" do
    expect(evaluate("fn:NotPresent(Missing)")).to be(true)
  end

  it "evaluates fn:SinceVersion correctly" do
    expect(evaluate("fn:SinceVersion(1.7)")).to be(true)  # 2.0 >= 1.7
    expect(evaluate("fn:BeforeVersion(1.7)")).to be(false) # 2.0 not < 1.7
  end

  it "evaluates comparison with @key" do
    expect(evaluate("@Type==Catalog")).to be(true)
    expect(evaluate("@Type==Page")).to be(false)
  end

  it "evaluates logical composition" do
    expect(evaluate("(fn:IsPresent(Type) && fn:IsPresent(Missing))")).to be(false)
    expect(evaluate("(fn:IsPresent(Type) || fn:IsPresent(Missing))")).to be(true)
  end

  it "evaluates fn:FileSize" do
    expect(evaluate("fn:FileSize()")).to eq(1234)
  end

  it "raises on unknown fn:" do
    expect { evaluate("fn:Bogus()") }.to raise_error(Pdfrb::ValidationError)
  end
end
