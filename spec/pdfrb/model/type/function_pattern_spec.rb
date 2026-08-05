# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Function and pattern types" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::FunctionExponential do
    let(:func) do
      doc.add({ FunctionType: 2, Domain: [0.0, 1.0],
                Range: [0.0, 1.0, 0.0, 1.0, 0.0, 1.0],
                C0: [0.0, 0.0, 0.0], C1: [1.0, 1.0, 1.0], N: 1 },
              type: described_class)
    end

    it "exposes function parameters" do
      expect(func.function_type).to eq(2)
      expect(func.exponential?).to be true
      expect(func.linear?).to be true
      expect(func.input_dimension).to eq(1)
      expect(func.output_dimension).to eq(3)
    end

    it "computes interpolated values" do
      expect(func.evaluate(0.0)).to eq([0.0, 0.0, 0.0])
      expect(func.evaluate(0.5)).to eq([0.5, 0.5, 0.5])
      expect(func.evaluate(1.0)).to eq([1.0, 1.0, 1.0])
    end
  end

  describe Pdfrb::Model::Type::FunctionStitching do
    it "counts subfunctions" do
      func = doc.add({ FunctionType: 3, Domain: [0.0, 1.0],
                       Functions: [{}, {}, {}], Bounds: [0.3, 0.7],
                       Encode: [0, 1, 0, 1, 0, 1] },
                     type: described_class)
      expect(func.stitching?).to be true
      expect(func.subfunction_count).to eq(3)
    end
  end

  describe Pdfrb::Model::Type::FunctionSampled do
    it "computes sample count from size vector" do
      func = doc.add({ FunctionType: 0, Domain: [0, 1, 0, 1],
                       Range: [0, 255], Size: [4, 4], BitsPerSample: 8 },
                     type: described_class)
      expect(func.sampled?).to be true
      expect(func.sample_count).to eq(16)
      expect(func.bit_depth_8?).to be true
      expect(func.input_dimension).to eq(2)
      expect(func.output_dimension).to eq(1)
    end
  end

  describe Pdfrb::Model::Type::FunctionPostScript do
    it "exposes type" do
      stream = doc.add({ FunctionType: 4, Domain: [0, 1], Range: [0, 1] },
                       type: described_class)
      stream.stream = "{ dup }"
      expect(stream.postscript?).to be true
      expect(stream.program).to eq("{ dup }")
    end
  end

  describe Pdfrb::Model::Type::PatternTiling do
    it "decodes paint and tiling types" do
      pat = doc.add({ PatternType: 1, PaintType: 1, TilingType: 1,
                      BBox: [0, 0, 100, 100], XStep: 100, YStep: 100 },
                    type: described_class)
      expect(pat.tiling?).to be true
      expect(pat.colored?).to be true
      expect(pat.constant_spacing?).to be true
    end

    it "detects uncolored pattern" do
      pat = doc.add({ PatternType: 1, PaintType: 2, TilingType: 2 },
                    type: described_class)
      expect(pat.uncolored?).to be true
      expect(pat.no_distortion?).to be true
    end
  end

  describe Pdfrb::Model::Type::PatternShading do
    it "exposes shading reference" do
      pat = doc.add({ PatternType: 2, Shading: { ShadingType: 2 } },
                    type: described_class)
      expect(pat.shading?).to be true
      expect(pat.shading[:ShadingType]).to eq(2)
    end
  end

  describe Pdfrb::Model::Type::CalGray do
    it "exposes calibration fields" do
      cs = doc.add({ WhitePoint: [0.9505, 1.0, 1.089], Gamma: 2.2 },
                   type: described_class)
      expect(cs.components).to eq(1)
      expect(cs.gamma).to eq(2.2)
      expect(cs.white_point).to eq([0.9505, 1.0, 1.089])
    end
  end

  describe Pdfrb::Model::Type::CalRGB do
    it "exposes RGB calibration" do
      cs = doc.add({ WhitePoint: [0.9505, 1.0, 1.089],
                     Gamma: [2.2, 2.2, 2.2] },
                   type: described_class)
      expect(cs.components).to eq(3)
      expect(cs.gamma).to eq([2.2, 2.2, 2.2])
    end
  end

  describe Pdfrb::Model::Type::Lab do
    it "uses default a/b range when Range absent" do
      cs = doc.add({ WhitePoint: [0.9505, 1.0, 1.089] },
                   type: described_class)
      expect(cs.components).to eq(3)
      expect(cs.a_range).to eq([-100, 100])
      expect(cs.b_range).to eq([-100, 100])
    end
  end

  describe Pdfrb::Model::Type::HalftoneType1 do
    it "exposes screen parameters" do
      ht = doc.add({ HalftoneType: 1, Frequency: 60.0, Angle: 45.0 },
                   type: described_class)
      expect(ht.type1?).to be true
      expect(ht.frequency).to eq(60.0)
      expect(ht.angle).to eq(45.0)
    end
  end

  describe Pdfrb::Model::Type::CIDSystemInfo do
    it "detects Adobe-Identity" do
      info = doc.add({ Registry: "Adobe", Ordering: "Identity", Supplement: 0 },
                     type: described_class)
      expect(info.identity?).to be true
      expect(info.complete?).to be true
      expect(info.to_s).to eq("Adobe-Identity-0")
    end

    it "detects incomplete info" do
      info = doc.add({ Registry: "Adobe" }, type: described_class)
      expect(info.complete?).to be false
    end
  end

  describe Pdfrb::Model::Type::Sound do
    it "computes audio properties" do
      sound = doc.add({ R: 8000, C: 1, B: 8, E: :Raw },
                      type: described_class)
      sound.stream = "\x00\x80\x00\x80"
      expect(sound.sampling_rate).to eq(8000)
      expect(sound.channels).to eq(1)
      expect(sound.bits_per_sample).to eq(8)
      expect(sound.raw_encoding?).to be true
      expect(sound.sample_bytes).to eq(1.0)
      expect(sound.duration_seconds).to eq(0.0005)
    end
  end
end
