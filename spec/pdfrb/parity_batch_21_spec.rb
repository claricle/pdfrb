# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 21 type specs" do
  let(:doc) { Pdfrb::Document.new }

  describe Pdfrb::Model::Type::ActionGoToE do
    it "exposes target file, destination, and window behaviour" do
      action = doc.add(
        { Type: :Action, S: :GoToE, F: "embed.pdf", D: [3, :XYZ, 0, 792, nil],
          NewWindow: true },
        type: described_class
      )
      expect(action.target_file).to eq("embed.pdf")
      expect(action.destination).not_to be_nil
      expect(action).to be_new_window
      expect(action).to be_targets_embedded_file
      expect(action).not_to be_named_destination
    end

    it "supports target dict and named destinations" do
      action = doc.add(
        { Type: :Action, S: :GoToE, D: :MyDest, T: { R: :C } },
        type: described_class
      )
      expect(action.target[:R]).to eq(:C)
      expect(action).to be_named_destination
      expect(action).not_to be_targets_embedded_file
    end
  end

  describe Pdfrb::Model::Type::AddActionFormField do
    it "exposes the four JavaScript triggers" do
      keystroke = doc.add({ Type: :Action, S: :JavaScript },
                          type: Pdfrb::Model::Type::Action)
      aa = doc.add(
        { K: Pdfrb::Model::Reference.new(keystroke.oid, 0),
          F: { Type: :Action, S: :JavaScript } },
        type: described_class
      )
      expect(aa.on_keystroke(doc)).not_to be_nil
      expect(aa.on_format(doc)).not_to be_nil
      expect(aa.on_validate(doc)).to be_nil
      expect(aa.on_calculate(doc)).to be_nil
    end
  end

  describe Pdfrb::Model::Type::AddActionScreenAnnotation do
    it "exposes all eight media event triggers" do
      aa = doc.add({ E: { S: :URI }, PI: { S: :URI } }, type: described_class)
      expect(aa.on_cursor_enter(doc)).not_to be_nil
      expect(aa.on_cursor_exit(doc)).to be_nil
      expect(aa.on_mouse_down(doc)).to be_nil
      expect(aa.on_mouse_up(doc)).to be_nil
      expect(aa.on_page_open(doc)).to be_nil
      expect(aa.on_page_close(doc)).to be_nil
      expect(aa.on_visible(doc)).to be_nil
      expect(aa.on_invisible(doc)).not_to be_nil
    end
  end

  describe Pdfrb::Model::Type::AddActionWidgetAnnotation do
    it "exposes all nine widget event triggers" do
      aa = doc.add({ Fo: { S: :URI }, Bl: { S: :URI } }, type: described_class)
      expect(aa.on_focus(doc)).not_to be_nil
      expect(aa.on_blur(doc)).not_to be_nil
      expect(aa.on_cursor_enter(doc)).to be_nil
      expect(aa.on_page_open(doc)).to be_nil
      expect(aa.on_invisible(doc)).to be_nil
    end
  end

  describe Pdfrb::Model::Type::ThreeDAnnotation do
    it "exposes 3D artwork, view state, and activation" do
      annot = doc.add(
        { Type: :Annot, Subtype: :"3D", Rect: [0, 0, 200, 200],
          "3DD": { Type: :"3D" }, "3DV": :DefaultView,
          "3DI": true, GEO: { Type: :"3DMeasure" } },
        type: described_class
      )
      expect(annot.artwork).not_to be_nil
      expect(annot.default_view).to eq(:DefaultView)
      expect(annot).to be_interactive
      expect(annot).to be_has_measure
      expect(annot).to be_default_view_name
    end
  end

  describe Pdfrb::Model::Type::MovieAnnotation do
    it "exposes movie, activation action, and title" do
      annot = doc.add(
        { Type: :Annot, Subtype: :Movie, Rect: [0, 0, 200, 160],
          Movie: { F: "movie.mp4" }, T: "Trailer" },
        type: described_class
      )
      expect(annot).to be_has_movie
      expect(annot.title).to eq("Trailer")
      expect(annot).not_to be_uses_action
    end
  end

  describe Pdfrb::Model::Type::ProjectionAnnotation do
    it "exposes markup and projection data keys" do
      annot = doc.add(
        { Type: :Annot, Subtype: :Projection, Rect: [0, 0, 100, 100],
          Subj: "Duplicate", ExData: { Type: :ExData } },
        type: described_class
      )
      expect(annot.subject).to eq("Duplicate")
      expect(annot).to be_has_projection_data
      expect(annot.reply_type).to eq(:R) # Arlington default for /RT
    end
  end

  describe Pdfrb::Model::Type::TrapNetworkAnnotation do
    it "exposes trap network state and fauxed fonts" do
      annot = doc.add(
        { Type: :Annot, Subtype: :TrapNet, Rect: [0, 0, 612, 792],
          Version: "1.0", AnnotStates: [:on, :off],
          FontFauxing: Pdfrb::Model::PdfArray.new(%i[F1 F2]) },
        type: described_class
      )
      expect(annot.version).to eq("1.0")
      expect(annot).to be_annot_states
      expect(annot.fauxed_font_names).to eq(%i[F1 F2])
    end
  end

  describe "appearance trap-net mappings" do
    it "maps AppearanceTrapNetSubDict to its own TSV" do
      klass = Pdfrb::Model::Type::AppearanceTrapNetSubDict
      expect(klass.field(:*)).not_to be_nil
      sub = doc.add({ PosH: 100, FontInfo: { F: :F1 } }, type: klass)
      expect(sub.pos_h).to eq(100)
    end

    it "maps AppearanceTrapNet to the N/R/D TSV" do
      tn = doc.add({ N: { Version: "1" }, D: { Version: "2" } },
                   type: Pdfrb::Model::Type::AppearanceTrapNet)
      %i[N R D].each do |key|
        expect(tn.class.field(key)).not_to be_nil
        expect(tn.class.field(key).arlington).not_to be_nil
      end
      expect(tn.normal).not_to be_nil
      expect(tn.down).not_to be_nil
    end

    it "maps AppearanceSubDict to its TSV" do
      sub = doc.add({ Yes: :On, Off: :Off },
                    type: Pdfrb::Model::Type::AppearanceSubDict)
      expect(sub.states).to include(:Yes, :Off)
    end
  end

  describe "projection dicts relocated" do
    it "keeps ExDataProjection reachable" do
      ex = doc.add({ Type: :ProjectedPDL },
                   type: Pdfrb::Model::Type::ExDataProjection)
      expect(ex).to be_project
    end
  end

  describe Pdfrb::Model::Type::ActionRichMediaExecute do
    it "aligns accessors with the TSV keys TA/TI/CMD" do
      action = doc.add(
        { Type: :Action, S: :RichMediaExecute, TA: { A: 1 }, TI: { B: 2 },
          CMD: { Type: :RichMediaCommand } },
        type: described_class
      )
      expect(action.target[:A]).to eq(1)
      expect(action.instance[:B]).to eq(2)
      expect(action.command[:Type]).to eq(:RichMediaCommand)
    end
  end

  describe Pdfrb::Model::Type::ActionThread do
    it "gains Arlington field metadata" do
      action = doc.add({ Type: :Action, S: :Thread, D: 0 },
                       type: described_class)
      expect(action.class.field(:F)).not_to be_nil
      expect(action.class.field(:F).arlington).not_to be_nil
      expect(action.class.field(:B)).not_to be_nil
    end
  end
end
