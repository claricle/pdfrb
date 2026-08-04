# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe "Arlington conformance" do
  fixtures_dir = File.join(__dir__, "..", "fixtures", "pdf-core-examples",
                           "AnnexH-Examples")

  before(:all) do
    skip "fixture corpus not pulled" unless Dir.exist?(fixtures_dir)
  end

  it "walks every fixture through the predicate evaluator" do
    skip "needs Arlington predicate evaluator full implementation"
  end
end

RSpec.describe "Content stream corpus round-trip" do
  fixtures_dir = File.join(__dir__, "..", "fixtures", "pdf-core-examples",
                           "AnnexH-Examples")

  before(:all) do
    skip "fixture corpus not pulled" unless Dir.exist?(fixtures_dir)
  end

  Dir.glob(File.join(fixtures_dir, "*.pdf")).each do |path|
    name = File.basename(path, ".pdf")

    it "#{name} round-trips content streams through Processor" do
      bytes = File.binread(path)
      doc = Pdfrb::Document.new(io: StringIO.new(bytes))

      doc.pages.each do |page|
        contents = page.value[:Contents]
        next unless contents

        ref = contents.is_a?(Pdfrb::Model::Reference) ? contents : nil
        next unless ref

        stream = doc.object(ref)
        next unless stream.is_a?(Pdfrb::Model::Cos::Stream)

        data = stream.stream
        next unless data && !data.empty?

        processor = Pdfrb::Content::Processor.new
        expect { processor.process(data) }.not_to raise_error
      end
    end
  end
end
