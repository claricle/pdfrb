# frozen_string_literal: true

module Pdfrb
  module FontLoader
    # TrueType font loader. Reads a .ttf file, builds the PDF font
    # dict + descriptor, and embeds the font file (optionally
    # subsetted).
    module TrueType
      module_function

      def call(document, name_or_io, embedded: true, **_opts)
        return nil unless name_or_io.is_a?(::String) && File.exist?(name_or_io)
        return nil unless name_or_io.end_with?(".ttf", ".otf")

        font_data = File.binread(name_or_io)
        ttf = Pdfrb::Font::TrueType::File.new(font_data)

        base_font = File.basename(name_or_io, ".*")
        font_dict = document.add(
          {
            Type: :Font,
            Subtype: :TrueType,
            BaseFont: base_font.to_sym,
            FirstChar: 0,
            LastChar: 255
          },
          type: Pdfrb::Model::Type::FontTrueType
        )

        if embedded
          font_stream = document.add(
            { Length1: font_data.bytesize },
            type: Pdfrb::Model::Cos::Stream
          )
          font_stream.stream = font_data

          descriptor = document.add(
            {
              Type: :FontDescriptor,
              FontName: base_font.to_sym,
              Flags: 32,
              FontBBox: [0, 0, 1000, 1000],
              ItalicAngle: 0,
              Ascent: 800,
              Descent: -200,
              CapHeight: 700,
              StemV: 80,
              FontFile2: Pdfrb::Model::Reference.new(font_stream.oid, 0)
            },
            type: Pdfrb::Model::Type::FontDescriptor
          )
          font_dict.value[:FontDescriptor] =
            Pdfrb::Model::Reference.new(descriptor.oid, 0)
        end

        font_dict
      end
    end
  end
end

Pdfrb::Document::Fonts.register_loader(Pdfrb::FontLoader::TrueType)
