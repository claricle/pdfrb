# frozen_string_literal: true

require "spec_helper"

# Conformance specs. These use the fixture corpus from
# claricle/pdf-core-examples when available (via `rake fixtures:pull`).
# When the corpus isn't present, specs skip gracefully.

RSpec.describe "Arlington conformance" do
  fixtures_dir = File.join(__dir__, "..", "fixtures", "pdf-core-examples")

  before(:all) do
    skip "fixture corpus not pulled (run rake fixtures:pull)" unless Dir.exist?(fixtures_dir)
  end

  it "walks every fixture through the predicate evaluator" do
    skip "needs TODO 149 full implementation + fixture corpus"
    raise "not yet implemented"
  end
end

RSpec.describe "Content stream corpus round-trip" do
  fixtures_dir = File.join(__dir__, "..", "fixtures", "pdf-core-examples")

  before(:all) do
    skip "fixture corpus not pulled" unless Dir.exist?(fixtures_dir)
  end

  it "round-trips content streams through Processor" do
    skip "needs fixture corpus"
    raise "not yet implemented"
  end
end

  before(:all) do

  end

  it "parses the same Catalog and Page count" do

    raise "not yet implemented"
  end
end
