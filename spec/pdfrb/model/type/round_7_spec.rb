# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Transition and CryptFilter types" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::Transition do
    it "decodes page transition style" do
      t = doc.add({ S: :Blinds, D: 2.5, Dm: :H, M: :I },
                  type: described_class)
      expect(t.style).to eq(:Blinds)
      expect(t.blinds?).to be true
      expect(t.dissolve?).to be false
      expect(t.horizontal?).to be true
      expect(t.vertical?).to be false
      expect(t.inward?).to be true
      expect(t.outward?).to be false
      expect(t.duration).to eq(2.5)
    end

    it "recognises other styles" do
      %i[Split Box Wipe Dissolve Glitter Fly Push Cover Uncover Fade].each do |style|
        t = doc.add({ S: style }, type: described_class)
        expect(t.send("#{style.to_s.downcase}?")).to be true
      end
    end
  end

  describe Pdfrb::Model::Type::CryptFilter do
    it "classifies cipher methods" do
      method_predicates = {
        None: :none?,
        V2: :v2?,
        AESV2: :aes_v2?,
        AESV3: :aes_v3?,
        AESV4: :aes_v4?,
      }
      method_predicates.each do |cfm, method_name|
        f = doc.add({ CFM: cfm }, type: described_class)
        expect(f.send(method_name)).to be true
      end
    end

    it "decodes auth events" do
      e = doc.add({ AuthEvent: :EFOpen }, type: described_class)
      expect(e.open_event?).to be true
      expect(e.doc_open_event?).to be false
    end
  end

  describe Pdfrb::Model::Type::CryptFilterMap do
    it "resolves stream name to filter" do
      m = doc.add({ IdentityFilter: { CFM: :AESV3 } },
                  type: described_class)
      filter = m.filter_for("IdentityFilter")
      expect(filter[:CFM]).to eq(:AESV3)
    end
  end

  describe Pdfrb::Model::Type::FontMultipleMaster do
    it "identifies MM Type 1 fonts" do
      font = doc.add({ Type: :Font, Subtype: :MMType1,
                       FirstChar: 32, LastChar: 127 },
                     type: described_class)
      expect(font.mm_type1?).to be true
      expect(font.char_range).to eq([32, 127])
    end
  end

  describe Pdfrb::Model::Type::CharProcMap do
    it "looks up procedures by glyph name" do
      doc.add({ A: "q 1 0 0 1 0 0 cm Q" }, type: described_class)
      map = doc.add({ x: "q 0 1 -1 0 0 100 cm Q" },
                    type: described_class)
      new_stream = doc.add({}, type: Pdfrb::Model::Cos::Stream)
      map.value[:A] = Pdfrb::Model::Reference.new(new_stream.oid, new_stream.gen)
      expect(map.has_glyph?(:A)).to be true
      expect(map.has_glyph?(:B)).to be false
    end
  end

  describe Pdfrb::Model::Type::FontFile3 do
    it "classifies OpenType variant" do
      stream = doc.add({ Subtype: :OpenType }, type: described_class)
      expect(stream.open_type?).to be true
    end
  end

  describe Pdfrb::Model::Type::MediaPlayers do
    it "counts must_use and never_use lists" do
      m = doc.add({ MU: [{}, {}, {}], NU: [{}, {}] },
                  type: described_class)
      expect(m.must_use_count).to eq(3)
      expect(m.never_use_count).to eq(2)
    end
  end

  describe Pdfrb::Model::Type::ExData3DMarkup do
    it "detects 3D markup" do
      d = doc.add({ Type: :Markup3D, V3D: { Vw: 100 } },
                  type: described_class)
      expect(d.has_3d?).to be true
    end
  end

  describe Pdfrb::Model::Type::OptContentUsageApplication do
    it "categorises by event type" do
      a = doc.add({ Event: :Print, OCGs: [{}] }, type: described_class)
      expect(a.print_event?).to be true
      expect(a.view_event?).to be false
    end
  end

  describe Pdfrb::Model::Type::BorderStyling do
    it "recognises solid vs dashed" do
      s = doc.add({ W: 2.5, S: :S }, type: described_class)
      expect(s.solid?).to be true
      expect(s.dashed?).to be false
      expect(s.width).to eq(2.5)
    end
  end

  describe Pdfrb::Model::Type::FunctionSampled do
    it "computes bit depth" do
      f = doc.add({ Size: [2, 2], BitsPerSample: 16 },
                  type: described_class)
      expect(f.bit_depth_16?).to be true
      expect(f.bit_depth_8?).to be false
    end
  end
end
