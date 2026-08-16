# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 16 type specs" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::AddActionCatalog do
    it "exposes document event actions" do
      close_action = doc.add({ Type: :Action, S: :ECMAScript },
                             type: Pdfrb::Model::Cos::Dictionary)
      aa = doc.add(
        { DC: Pdfrb::Model::Reference.new(close_action.oid, 0) },
        type: described_class
      )
      expect(aa.document_close(doc)).not_to be_nil
      expect(aa.will_save(doc)).to be_nil
      expect(aa.did_save(doc)).to be_nil
      expect(aa.will_print(doc)).to be_nil
      expect(aa.did_print(doc)).to be_nil
    end
  end

  describe Pdfrb::Model::Type::AlternateImage do
    it "exposes image, default_for_printing, optional_content" do
      image = doc.add({ Type: :XObject, Subtype: :Image, Width: 1, Height: 1 },
                      type: Pdfrb::Model::Type::XObjectImage)
      alt = doc.add(
        { Image: Pdfrb::Model::Reference.new(image.oid, 0),
          DefaultForPrinting: true },
        type: described_class
      )
      expect(alt.image(doc)).not_to be_nil
      expect(alt.default_for_printing?).to be true
      expect(alt.optional_content(doc)).to be_nil
    end

    it "defaults DefaultForPrinting to false" do
      alt = doc.add({}, type: described_class)
      expect(alt.default_for_printing?).to be false
    end
  end

  describe Pdfrb::Model::Type::ActionSound do
    it "exposes sound, volume, flags" do
      sound = doc.add({ Type: :Sound }, type: Pdfrb::Model::Cos::Stream)
      action = doc.add(
        {
          Type: :Action, S: :Sound,
          Sound: Pdfrb::Model::Reference.new(sound.oid, 0),
          Volume: 0.5, Synchronous: true, Repeat: true, Mix: true
        },
        type: described_class
      )
      expect(action.type).to eq(:Action)
      expect(action.action_type).to eq(:Sound)
      expect(action.sound(doc)).not_to be_nil
      expect(action.volume).to eq(0.5)
      expect(action.synchronous?).to be true
      expect(action.repeat?).to be true
      expect(action.mix?).to be true
    end

    it "defaults volume to 1.0 and flags to false" do
      action = doc.add({ S: :Sound }, type: described_class)
      expect(action.volume).to eq(1.0)
      expect(action.synchronous?).to be false
      expect(action.repeat?).to be false
      expect(action.mix?).to be false
    end
  end
end
