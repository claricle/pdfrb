# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Type::PagePieceInfo do
  let(:now) { Time.utc(2026, 8, 8, 12, 0, 0) }

  it "round-trips /LastModified through Time" do
    piece = described_class.new({})
    piece.last_modified = now
    expect(piece.last_modified).to eq(now)
  end

  it "stores and reads /Private as a Hash" do
    piece = described_class.new({})
    piece.merge_private!(Job: "build-42", Batch: 7)
    expect(piece.private_data).to include(Job: "build-42", Batch: 7)
  end

  it "merges additional keys without losing existing ones" do
    piece = described_class.new({ Private: { Job: "build-1" } })
    piece.merge_private!(Run: "alpha")
    expect(piece.private_data[:Job]).to eq("build-1")
    expect(piece.private_data[:Run]).to eq("alpha")
  end

  it "preserves private data through serialization" do
    doc = Pdfrb::Document.new
    page = doc.pages.add
    piece = doc.add({ Application: :Pdfrb, Private: { Job: "x" } },
                    type: described_class)
    page.value[:PieceInfo] = { Pdfrb: Pdfrb::Model::Reference.new(piece.oid, 0) }

    io = StringIO.new
    doc.write(io: io)

    reloaded = Pdfrb::Document.new(io: StringIO.new(io.string))
    reloaded_page = reloaded.pages.first
    piece_ref = reloaded_page.value[:PieceInfo][:Pdfrb]
    reloaded_piece = reloaded.object(piece_ref)
    expect(reloaded_piece.value[:Application]).to eq(:Pdfrb)
  end
end
