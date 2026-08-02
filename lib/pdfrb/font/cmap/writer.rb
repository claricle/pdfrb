# frozen_string_literal: true

module Pdfrb
  module Font
    module CMap
      # Writes a CMap text file from a +bfchar+ mapping. Used when
      # embedding CID fonts with a subset of glyphs.
      class Writer
        attr_reader :cmap_name, :cid_system_info, :mapping

        def initialize(cmap_name:, cid_system_info:, mapping:)
          @cmap_name = cmap_name
          @cid_system_info = cid_system_info
          @mapping = mapping
        end

        def to_s
          buffer = +""
          buffer << "/CIDInit /ProcSet findresource begin\n"
          buffer << "12 dict begin\n"
          buffer << "begincmap\n"
          buffer << "/CIDSystemInfo <<\n"
          buffer << "  /Registry (Adobe)\n"
          buffer << "  /Ordering (#{@cid_system_info[:ordering]})\n"
          buffer << "  /Supplement #{@cid_system_info[:supplement]}\n"
          buffer << ">> def\n"
          buffer << "/CMapName /#{@cmap_name} def\n"
          buffer << "/CMapType 1 def\n"
          buffer << "1 begincodespacerange\n"
          buffer << "  <0000> <FFFF>\n"
          buffer << "endcodespacerange\n"
          buffer << "#{@mapping.length} beginbfchar\n"
          @mapping.each do |code, unicode|
            buffer << "<%04X> <%04X>\n" % [code, unicode]
          end
          buffer << "endbfchar\n"
          buffer << "endcmap\n"
          buffer << "CMapName currentdict /CMap defineresource pop\n"
          buffer << "end\n"
          buffer << "end\n"
          buffer.force_encoding(Encoding::BINARY)
        end
      end
    end
  end
end
