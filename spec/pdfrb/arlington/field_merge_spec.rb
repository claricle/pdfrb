# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Arlington field merge" do
  let(:doc) { Pdfrb::Document.new }

  # Build a test type with hand-coded define_field for /Type and
  # arlington_object for the same TSV. The hand-coded /Type must win.
  let(:test_class) do
    Class.new(Pdfrb::Model::Cos::Dictionary) do
      define_field :Type, type: Symbol, default: :Widget
      define_field :FT, type: Symbol, required: true
      arlington_object "AnnotWidget"
    end
  end

  it "preserves hand-coded field type when Arlington also defines it" do
    field = test_class.field(:Type)
    expect(field).not_to be_nil
    expect(field.type).to eq([Symbol])
    expect(field.default).to eq(:Widget)
  end

  it "attaches the Arlington FieldDefinition for reference" do
    field = test_class.field(:Type)
    expect(field.arlington).not_to be_nil
    expect(field.arlington.key).to eq("Type")
  end

  it "adds Arlington-only fields that weren't hand-coded" do
    field = test_class.field(:Subtype)
    expect(field).not_to be_nil
    expect(field.arlington).not_to be_nil
  end

  it "hand-coded required flag is preserved" do
    field = test_class.field(:FT)
    expect(field.required).to be_truthy
  end

  it "typed access still works through the merged field" do
    obj = doc.add({ Type: :Widget, FT: :Tx, Subtype: :Widget },
                  type: test_class)
    expect(obj[:Type]).to eq(:Widget)
    expect(obj[:FT]).to eq(:Tx)
  end
end
