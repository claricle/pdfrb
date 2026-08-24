# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Parity batch 36 final tail types" do
  let(:doc) { Pdfrb::Document.new }

  let(:registry) { Pdfrb::Model::Type.arlington_registry }

  it "registers every class from the final tail" do
    klasses = {
      Pdfrb::Model::Type::EncryptedPayload => "EncryptedPayload",
      Pdfrb::Model::Type::Permissions => "Permissions",
      Pdfrb::Model::Type::FDDict => "FDDict",
      Pdfrb::Model::Type::StreamDict => "Stream",
      Pdfrb::Model::Type::DictionaryOfDictionaries => "DictionaryOfDictionaries",
      Pdfrb::Model::Type::DictionaryOfFunctions => "DictionaryOfFunctions",
      Pdfrb::Model::Type::LinearizationParameterDict => "LinearizationParameterDict",
      Pdfrb::Model::Type::FixedPrint => "FixedPrint",
      Pdfrb::Model::Type::FloatingWindowParameters => "FloatingWindowParameters",
      Pdfrb::Model::Type::FontFileType1 => "FontFileType1",
    }
    klasses.each do |klass, tsv|
      expect(registry[tsv]).to eq(klass), tsv
    end
  end

  it "registers the remaining misc tail" do
    klasses = {
      Pdfrb::Model::Type::Mac => "Mac",
      Pdfrb::Model::Type::MicrosoftWindowsLaunchParam => "MicrosoftWindowsLaunchParam",
      Pdfrb::Model::Type::MinimumBitDepth => "MinimumBitDepth",
      Pdfrb::Model::Type::MinimumScreenSize => "MinimumScreenSize",
      Pdfrb::Model::Type::NavNode => "NavNode",
      Pdfrb::Model::Type::Navigator => "Navigator",
      Pdfrb::Model::Type::PaperMetaData => "PaperMetaData",
      Pdfrb::Model::Type::SlideShow => "SlideShow",
      Pdfrb::Model::Type::Solidities => "Solidities",
      Pdfrb::Model::Type::SourceInformation => "SourceInformation",
      Pdfrb::Model::Type::SpectralData => "SpectralData",
      Pdfrb::Model::Type::ViewParams => "ViewParams",
      Pdfrb::Model::Type::DPMMetadataStream => "DPM",
      Pdfrb::Model::Type::Data => "Data",
      Pdfrb::Model::Type::BeadFirst => "BeadFirst",
      Pdfrb::Model::Type::ThreeDViewAddEntries => "3DViewAddEntries",
      Pdfrb::Model::Type::MovieActivation => "MovieActivation",
      Pdfrb::Model::Type::AppearancePrinterMarkDict => "AppearancePrinterMark",
      Pdfrb::Model::Type::OptContentUsage => "OptContentUsage",
      Pdfrb::Model::Type::CMapStream => "CMapStream",
      Pdfrb::Model::Type::ExDataProjection => "ExDataProjection",
    }
    klasses.each do |klass, tsv|
      expect(registry[tsv]).to eq(klass), tsv
    end
  end

  it "exposes linearization and stream-base parameters" do
    lin = doc.add({ Linearized: 1.0, L: 4096, H: [120, 240], O: 360,
                    E: 3600, N: 8, T: 3800 },
                  type: Pdfrb::Model::Type::LinearizationParameterDict)
    expect(lin.file_length).to eq(4096)
    expect(lin.page_count).to eq(8)
    expect(lin.first_page_offset).to eq([120, 240])

    stream = doc.add({ Length: 128, Filter: :FlateDecode },
                     type: Pdfrb::Model::Type::StreamDict)
    expect(stream.length).to eq(128)
    expect(stream.filter).to eq(:FlateDecode)
    expect(stream.class.field(:FDecodeParms).arlington).not_to be_nil
  end

  it "exposes media criteria and floating windows" do
    bits = doc.add({ V: 16 }, type: Pdfrb::Model::Type::MinimumBitDepth)
    expect(bits.value).to eq(16)

    screen = doc.add({ V: [640, 480] }, type: Pdfrb::Model::Type::MinimumScreenSize)
    expect(screen.value).to eq([640, 480])

    win = doc.add({ D: true, RT: :Fixed, O: true, UC: true },
                  type: Pdfrb::Model::Type::FloatingWindowParameters)
    expect(win).to be_has_close_button
    expect(win).to be_ui_constrained
    expect(win).not_to be_resizable
  end

  it "exposes launch, navigator, and slideshow parameters" do
    win = doc.add({ F: "report.docx", O: "open", P: "/print" },
                  type: Pdfrb::Model::Type::MicrosoftWindowsLaunchParam)
    expect(win.file).to eq("report.docx")
    expect(win.operation).to eq("open")

    nav = doc.add({ Type: :NavNode, NA: :NextInThread, Next: {} },
                  type: Pdfrb::Model::Type::NavNode)
    expect(nav.next_action).to eq(:NextInThread)

    slide = doc.add({ Type: :SlideShow, StartResource: :S1 },
                    type: Pdfrb::Model::Type::SlideShow)
    expect(slide.start_resource).to eq(:S1)
  end

  it "exposes device-n and provenance leftovers" do
    solids = doc.add({ Cyan: 0.8, Gold: 0.9 },
                     type: Pdfrb::Model::Type::Solidities)
    expect(solids[:Gold]).to eq(0.9)
    expect(solids.colorant_names).to include(:Cyan)

    src = doc.add({ AU: "Editor", E: "Pdfrb" },
                  type: Pdfrb::Model::Type::SourceInformation)
    expect(src.author).to eq("Editor")
    expect(src.class.field(:TS).arlington).not_to be_nil

    data = doc.add({ LastModified: "D:20240101000000Z", Private: {} },
                   type: Pdfrb::Model::Type::Data)
    expect(data.private_data).not_to be_nil
  end

  it "exposes movie activation and usage wrappers" do
    activation = doc.add({ Start: 0, Rate: 1.5, ShowControls: false,
                           FWScale: [0.5, 0.5] },
                         type: Pdfrb::Model::Type::MovieActivation)
    expect(activation.rate).to eq(1.5)
    expect(activation.class.field(:Synchronous).arlington).not_to be_nil

    usage = doc.add({ CreatorInfo: { Creator: "Pdfrb", Subtype: :Artwork } },
                    type: Pdfrb::Model::Type::OptContentUsage)
    expect(usage.creator_info).not_to be_nil
    expect(usage.class.field(:PageElement).arlington).not_to be_nil
  end
end
