# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfrb::Destination::Fit do
  let(:page_ref) { Pdfrb::Model::Reference.new(3, 0) }

  describe "registry" do
    it "registers all standard fit types" do
      expect(described_class.types).to include(
        :Fit, :FitH, :FitV, :FitR, :XYZ, :FitB, :FitBH, :FitBV
      )
    end
  end

  describe Pdfrb::Destination::FullPage do
    it "serializes to [page_ref /Fit]" do
      dest = described_class.new(page_ref)
      pdf = dest.to_pdf
      expect(pdf[0]).to eq(page_ref)
      expect(pdf[1]).to eq(:Fit)
    end
  end

  describe Pdfrb::Destination::FitHorizontal do
    it "serializes to [page_ref /FitH top]" do
      dest = described_class.new(page_ref, top: 500)
      pdf = dest.to_pdf
      expect(pdf[1]).to eq(:FitH)
      expect(pdf[2]).to eq(500)
    end
  end

  describe Pdfrb::Destination::XYZ do
    it "serializes to [page_ref /XYZ left top zoom]" do
      dest = described_class.new(page_ref, left: 72, top: 720, zoom: 1.5)
      pdf = dest.to_pdf
      expect(pdf[1]).to eq(:XYZ)
      expect(pdf[2]).to eq(72)
      expect(pdf[3]).to eq(720)
      expect(pdf[4]).to eq(1.5)
    end

    it "omits nil parameters" do
      dest = described_class.new(page_ref)
      pdf = dest.to_pdf
      expect(pdf.length).to eq(2) # [page_ref, :XYZ] with no params
    end
  end

  describe Pdfrb::Destination::FitRectangle do
    it "serializes to [page_ref /FitR l b r t]" do
      dest = described_class.new(page_ref, left: 0, bottom: 0, right: 612, top: 792)
      pdf = dest.to_pdf
      expect(pdf[1]).to eq(:FitR)
      expect(pdf[2..5]).to eq([0, 0, 612, 792])
    end
  end

  it "allows custom fit types (OCP)" do
    custom = Class.new(Pdfrb::Destination::Fit) do
      class << self
        def fit_keyword; :MyFit; end
      end
      register_as
    end
    expect(described_class[:MyFit]).to be(custom)
  end
end

RSpec.describe Pdfrb::Action do
  describe "registry" do
    it "registers all standard action types" do
      expect(described_class.types).to include(
        :GoTo, :URI, :Launch, :Named, :GoToR, :SubmitForm, :ResetForm, :JavaScript, :Hide
      )
    end
  end

  describe Pdfrb::Action::GoTo do
    it "builds a GoTo action dict" do
      pdf = described_class.to_pdf(dest: Pdfrb::Model::Reference.new(5, 0))
      expect(pdf[:S]).to eq(:GoTo)
      expect(pdf[:D]).to be_a(Pdfrb::Model::Reference)
    end
  end

  describe Pdfrb::Action::URI do
    it "builds a URI action dict" do
      pdf = described_class.to_pdf(uri: "https://example.com")
      expect(pdf[:S]).to eq(:URI)
      expect(pdf[:URI]).to eq("https://example.com")
    end

    it "includes IsMap when set" do
      pdf = described_class.to_pdf(uri: "https://example.com", is_map: true)
      expect(pdf[:IsMap]).to be true
    end
  end

  describe Pdfrb::Action::Launch do
    it "builds a Launch action dict" do
      pdf = described_class.to_pdf(file_spec: "/path/to/app")
      expect(pdf[:S]).to eq(:Launch)
      expect(pdf[:F]).to eq("/path/to/app")
    end
  end

  describe Pdfrb::Action::Named do
    it "builds a Named action dict" do
      pdf = described_class.to_pdf(name: :NextPage)
      expect(pdf[:S]).to eq(:Named)
      expect(pdf[:N]).to eq(:NextPage)
    end
  end

  describe Pdfrb::Action::GoToR do
    it "builds a GoToR action dict" do
      pdf = described_class.to_pdf(file_spec: "doc.pdf", dest: [1, :Fit])
      expect(pdf[:S]).to eq(:GoToR)
      expect(pdf[:F]).to eq("doc.pdf")
    end
  end

  describe Pdfrb::Action::SubmitForm do
    it "builds a SubmitForm action dict" do
      pdf = described_class.to_pdf(url: "https://example.com/submit", flags: 0)
      expect(pdf[:S]).to eq(:SubmitForm)
      expect(pdf[:F]).to eq("https://example.com/submit")
    end
  end

  describe Pdfrb::Action::JavaScript do
    it "builds a JavaScript action dict" do
      pdf = described_class.to_pdf(script: "app.alert('hi')")
      expect(pdf[:S]).to eq(:JavaScript)
      expect(pdf[:JS]).to eq("app.alert('hi')")
    end
  end

  it "allows custom action types (OCP)" do
    custom = Class.new(Pdfrb::Action::Base) do
      class << self
        def action_type; :CustomAction; end
      end
      register_as
    end
    expect(described_class[:CustomAction]).to be(custom)
  end
end
