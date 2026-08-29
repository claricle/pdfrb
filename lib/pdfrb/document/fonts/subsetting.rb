# frozen_string_literal: true

module Pdfrb
  class Document
    class Fonts
      # Font-program subsetting (s9.6.4). Mixed into the Fonts
      # facade; the seam it owns is "replace every embedded font
      # program with a subset covering only the used codepoints",
      # dispatching on the outline format (TrueType vs CFF-in-OTF).
      module Subsetting
        # Entry point, invoked by Document#write. Fonts that were
        # never drawn with (no recorded codepoints) keep their full
        # program; failures fall back to the full font.
        def subset_fonts!
          @font_streams.each do |resource, data|
            next unless valid_font_data?(data)

            codepoints = @used_codepoints[resource]
            next if codepoints.empty?

            begin
              subset_font(resource, data, codepoints)
            rescue StandardError
              next
            end
          end
        end

        protected

        # Build the subsetted font bytes for +resource+ and replace the
        # descriptor's font-file stream (FontFile2 for TrueType
        # outlines, FontFile3/OpenType for CFF).
        def subset_font(resource, data, codepoints)
          subset, font_file_key =
            if data.byteslice(0, 4) == "OTTO".b
              # CFF outlines: map codepoints to glyph IDs via the OTF
              # cmap (it addresses CFF glyphs too), subset the 'CFF '
              # table, and rebuild the OTF container.
              cmap = Pdfrb::Font::TrueType::File.new(data).cmap
              gids = codepoints.filter_map { |cp| cmap.glyph_id_for(cp) }.uniq
              [Pdfrb::Font::CFF::Subsetter.subset_otf(data, gids), :FontFile3]
            else
              ttf = Pdfrb::Font::TrueType::File.new(data)
              subsetter = Pdfrb::Font::TrueType::Subsetter.new(ttf, codepoints.to_a)
              [subsetter.subset, :FontFile2]
            end
          dict = @font_dicts[resource]
          return unless dict

          desc_ref = dict.value[:FontDescriptor]
          return unless desc_ref

          desc = document.resolve(desc_ref)
          return unless desc

          # Reuse the add-time stream object in place rather than
          # allocating a replacement — a second stream would leave the
          # full original orphaned in the file (doubling output size).
          fd_stream = desc.value[font_file_key]
          fd_stream = document.resolve(fd_stream)
          if fd_stream.is_a?(Pdfrb::Model::Cos::Stream)
            fd_stream.stream = subset
            fd_stream.value[:Length] = subset.bytesize
            fd_stream.value.delete(:Filter)
            if font_file_key == :FontFile3
              fd_stream.value[:Subtype] = :OpenType
              fd_stream.value[:Length1] = subset.bytesize
            end
          end
        end

        # Generate a deterministic 6-letter subset tag from the font bytes
        # so re-embedding the same font produces the same prefix. Format
        # is six uppercase ASCII letters derived from the SHA-1 of the
        # first 1 KB of the font file (per PDF spec s9.6.4).
        def subset_tag_for(font_bytes)
          require "digest"
          digest = Digest::SHA1.digest(font_bytes.byteslice(0, 1024) || "")
          digest.byteslice(0, 6).bytes.each_with_object(+"") do |b, s|
            s << ((b % 26) + 65).chr
          end
        end
      end
    end
  end
end
