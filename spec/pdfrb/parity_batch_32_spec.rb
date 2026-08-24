# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 32 media/rendition types" do
  let(:doc) { Pdfrb::Document.new }

  it "registers all media classes under their TSVs" do
    klasses = {
      Pdfrb::Model::Type::RenditionMedia => "RenditionMedia",
      Pdfrb::Model::Type::RenditionSelector => "RenditionSelector",
      Pdfrb::Model::Type::RenditionMH => "RenditionMH",
      Pdfrb::Model::Type::RenditionBE => "RenditionBE",
      Pdfrb::Model::Type::MediaClip => "MediaClipData",
      Pdfrb::Model::Type::MediaClipDataMHBE => "MediaClipDataMHBE",
      Pdfrb::Model::Type::MediaClipSection => "MediaClipSection",
      Pdfrb::Model::Type::MediaClipSectionMHBE => "MediaClipSectionMHBE",
      Pdfrb::Model::Type::MediaDuration => "MediaDuration",
      Pdfrb::Model::Type::MediaPermissions => "MediaPermissions",
      Pdfrb::Model::Type::MediaPlayParameters => "MediaPlayParameters",
      Pdfrb::Model::Type::MediaPlayParametersMH => "MediaPlayParametersMH",
      Pdfrb::Model::Type::MediaPlayParametersBE => "MediaPlayParametersBE",
      Pdfrb::Model::Type::MediaScreenParametersMHBE => "MediaScreenParametersMHBE",
    }
    registry = Pdfrb::Model::Type.arlington_registry
    klasses.each do |klass, tsv|
      expect(registry[tsv]).to eq(klass), tsv
    end
  end

  describe Pdfrb::Model::Type::RenditionMedia do
    it "exposes media rendition keys" do
      rend = doc.add(
        { Type: :Rendition, S: :MR, C: { Type: :MediaClip },
          P: { TF: 1 }, SP: true },
        type: described_class
      )
      expect(rend).to be_media
      expect(rend).not_to be_selector
      expect(rend.media_clip).not_to be_nil
      expect(rend).to be_visible_on_page
      expect(rend.class.field(:SP).arlington).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::RenditionSelector do
    it "exposes the rendition list" do
      rend = doc.add({ Type: :Rendition, S: :SR, R: [{ S: :MR }] },
                     type: described_class)
      expect(rend).to be_selector
      expect(rend.renditions).not_to be_nil
    end
  end

  describe "MH/BE wrappers" do
    it "unwraps the parameters" do
      mh = doc.add({ C: { V: 0.5 } }, type: Pdfrb::Model::Type::RenditionMH)
      expect(mh.parameters[:V]).to eq(0.5)
      be = doc.add({ C: { V: 1.0 } }, type: Pdfrb::Model::Type::RenditionBE)
      expect(be.parameters[:V]).to eq(1.0)
    end

    it "exposes clip-section begin/end times" do
      sec = doc.add({ B: 10, E: 20 },
                    type: Pdfrb::Model::Type::MediaClipSectionMHBE)
      expect(sec.begin).to eq(10)
      expect(sec.ends).to eq(20)
    end
  end

  describe Pdfrb::Model::Type::MediaClipSection do
    it "exposes duration and alternates" do
      section = doc.add({ S: :Section, D: { T: 30 }, Alt: [] },
                        type: described_class)
      expect(section.duration).not_to be_nil
      expect(section.class.field(:Alt).arlington).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::MediaDuration do
    it "reads seconds" do
      duration = doc.add({ T: 42.5 }, type: described_class)
      expect(duration.seconds).to eq(42.5)
    end
  end

  describe Pdfrb::Model::Type::MediaPermissions do
    it "reads temp-file flags" do
      perms = doc.add({ TF: 3 }, type: described_class)
      expect(perms.temp_file_flags).to eq(3)
      expect(perms).not_to be_invalid_after_save
      expect(perms).not_to be_invalid_after_print
    end
  end

  describe "play parameters" do
    it "exposes volume, fit, duration, repeat" do
      play = doc.add({ V: 0.8, F: :Fit, D: { T: 10 }, A: 2 },
                     type: Pdfrb::Model::Type::MediaPlayParametersMH)
      expect(play.volume).to eq(0.8)
      expect(play.fit).to eq(:Fit)
      expect(play.repeat_count).to eq(2)
      expect(play.class.field(:RC).arlington).not_to be_nil
    end

    it "wraps players via MH/BE" do
      play = doc.add({ PL: { FFMPEG: {} } },
                     type: Pdfrb::Model::Type::MediaPlayParameters)
      expect(play.players).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::MediaScreenParametersMHBE do
    it "exposes window, color, opacity" do
      screen = doc.add({ W: { W: 320, H: 240 }, B: [0, 0, 0], O: 0.9 },
                       type: described_class)
      expect(screen.window).not_to be_nil
      expect(screen.opacity).to eq(0.9)
    end
  end
end
