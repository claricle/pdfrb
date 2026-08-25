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
    Dir.glob(File.join(fixtures_dir, "*.pdf")).each do |path|
      doc = Pdfrb::Document.new(io: StringIO.new(File.binread(path)))

      raw_root = doc.catalog.value[:Pages]
      root_oid = raw_root.is_a?(Pdfrb::Model::Reference) ? raw_root.oid : nil

      checked = 0
      violations = []
      doc.each_indirect_object do |obj|
        next unless obj.is_a?(Pdfrb::Model::Cos::Dictionary)

        type_sym = obj[:Type]
        type_sym = type_sym.to_sym if type_sym.is_a?(String)
        next unless type_sym.is_a?(Symbol)

        klass = Pdfrb::Model::Cos::Dictionary.lookup_type(type_sym)
        next unless klass

        # The Catalog /Pages target is the root node: /Parent must be
        # absent there (PageTreeNodeRoot), required on interior nodes.
        klass = Pdfrb::Model::Type::PageTreeNodeRoot if root_oid && obj.oid == root_oid

        wrapped = klass.new(obj.value, oid: obj.oid, gen: obj.gen, document: doc)
        checked += 1
        wrapped.validate { |message, _correctable| violations << message }
      end

      expect(checked).to be_positive, File.basename(path)
      # The Annex H corpus is well-formed: the field validator
      # (required keys, typed values) should find no violations.
      expect(violations).to eq([]), "#{File.basename(path)}: #{violations.join('; ')}"
    end
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
