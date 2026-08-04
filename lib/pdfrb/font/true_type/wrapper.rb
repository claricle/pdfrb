# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      module Wrapper
        module_function

        def embed(document, ttf_data, resource_name:)
          ttf = File.new(ttf_data)
          name = ttf.name_table_parsed
          ps_name = name&.ps_name || "EmbeddedFont"

          fd = create_font_descriptor(document, ttf, ps_name)
          widths = build_widths(ttf)
          tu_stream = build_tounicode(document, ttf)
          font_file = embed_font_file(document, ttf_data)

          fd.value[:FontFile2] = Pdfrb::Model::Reference.new(font_file.oid, font_file.gen)

          document.add(
            {
              Type: :Font,
              Subtype: :TrueType,
              BaseFont: ps_name.to_sym,
              FirstChar: 0,
              LastChar: 255,
              Widths: widths,
              FontDescriptor: Pdfrb::Model::Reference.new(fd.oid, fd.gen),
              ToUnicode: Pdfrb::Model::Reference.new(tu_stream.oid, tu_stream.gen),
              Encoding: :WinAnsiEncoding,
            },
            type: Pdfrb::Model::Type::FontTrueType
          )
        end

        def create_font_descriptor(document, ttf, ps_name)
          head = ttf.head
          os2 = ttf.os2
          document.add(
            {
              Type: :FontDescriptor,
              FontName: ps_name.to_sym,
              Flags: 32,
              FontBBox: head&.bbox || [0, 0, 1000, 1000],
              ItalicAngle: 0,
              Ascent: os2&.typo_ascender || ttf.hhea&.ascender || 800,
              Descent: os2&.typo_descender || ttf.hhea&.descender || -200,
              CapHeight: os2&.cap_height || 700,
              StemV: 80,
            },
            type: Pdfrb::Model::Cos::Dictionary
          )
        end

        def build_widths(ttf)
          widths = Array.new(256, 500)
          table = Pdfrb::Font::Encoding::WinAnsiEncoding::TABLE
          Maxp.new(ttf.maxp_table)

          table.each_with_index do |cp, byte|
            next unless cp

            begin
              gid = ttf.cmap.glyph_id_for(cp)
              next unless gid&.positive?

              w = ttf.hmtx.advance_width(gid)
              widths[byte] = w if w&.positive?
            rescue StandardError
              next
            end
          end
          widths
        end

        def build_tounicode(document, _ttf)
          table = Pdfrb::Font::Encoding::WinAnsiEncoding::TABLE
          mapping = {}
          table.each_with_index { |cp, byte| mapping[byte] = cp if cp }

          cmap_data = Pdfrb::Font::CMap::Writer.write(mapping)
          stream = document.add(
            { Length: cmap_data.bytesize },
            type: Pdfrb::Model::Cos::Stream
          )
          stream.stream = cmap_data
          stream
        end

        def embed_font_file(document, ttf_data)
          stream = document.add(
            { Length: ttf_data.bytesize },
            type: Pdfrb::Model::Cos::Stream
          )
          stream.stream = ttf_data
          stream
        end
      end
    end
  end
end
