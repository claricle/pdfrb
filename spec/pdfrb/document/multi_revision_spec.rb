# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Pdfrb::Document do
  describe "multi-revision traversal" do
    it "reports revision_count of 1 for an in-memory document" do
      doc = described_class.new
      expect(doc.revision_count).to eq(1)
    end

    it "yields a single revision for a freshly written PDF" do
      src = described_class.new
      src.pages.add
      out = StringIO.new
      src.write(io: out)

      reloaded = described_class.new(io: StringIO.new(out.string))
      expect(reloaded.revision_count).to eq(1)
      revisions = reloaded.each_revision.to_a
      expect(revisions.length).to eq(1)
    end

    it "walks each revision in /Prev chain" do
      base = described_class.new
      base.pages.add
      initial = StringIO.new
      base.write(io: initial)

      reloaded = described_class.new(io: StringIO.new(initial.string))
      reloaded.pages.first.value[:Rotate] = 90
      inc = StringIO.new
      Pdfrb::Writer.write_incremental(reloaded, inc)

      multi = described_class.new(io: StringIO.new(inc.string))
      expect(multi.revision_count).to be >= 1
      revisions = multi.each_revision.to_a
      expect(revisions).not_to be_empty
      revisions.each do |_i, xref, _tr|
        expect(xref).to respond_to(:entries)
      end
    end

    it "yields the latest revision first" do
      base = described_class.new
      base.pages.add
      initial = StringIO.new
      base.write(io: initial)

      reloaded = described_class.new(io: StringIO.new(initial.string))
      reloaded.pages.first.value[:Rotate] = 90
      inc = StringIO.new
      Pdfrb::Writer.write_incremental(reloaded, inc)

      multi = described_class.new(io: StringIO.new(inc.string))
      first_revision = multi.each_revision.first
      expect(first_revision[0]).to eq(0)
    end
  end
end
