# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Model::Type::DestOutputProfile do
  it "registers under its TSV and exposes ICC metadata" do
    profile = described_class.new(
      { ProfileName: "ISO Coated v2", ProfileCS: "CMYK",
        ICCVersion: 0x02100000, ColorantTable: %w[Cyan Gold] }
    )
    expect(Pdfrb::Model::Type.arlington_registry["DestOutputProfileRef"])
      .to eq(described_class)
    expect(profile.profile_name).to eq("ISO Coated v2")
    expect(profile.profile_color_space).to eq("CMYK")
    expect(profile.colorant_table).to eq(%w[Cyan Gold])
    expect(described_class.field(:CheckSum).arlington).not_to be_nil
    expect(described_class.field(:URLs).arlington).not_to be_nil
  end
end
