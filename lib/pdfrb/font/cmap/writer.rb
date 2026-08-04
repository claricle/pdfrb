# frozen_string_literal: true

module Pdfrb
  module Font
    module CMap
      # Writes a CMap text file from a mapping of glyph codes to Unicode
      # strings. Used when embedding CID fonts with a subset of glyphs
      # to provide /ToUnicode CMap data.
      #
      # Supports both 1-byte and 2-byte codespaceranges, supplementary
      # Unicode planes (via UTF-16 surrogate pairs), and automatic
      # chunking of bfchar sections (max 100 entries per section per
      # the PDF spec).
      class Writer

        def self.write(mapping, name: "Adobe-Identity-UCS")
          str_mapping = mapping.transform_values { |cp| [cp].pack("U") }
          new(
            cmap_name: name,
            cid_system_info: { registry: "Adobe", ordering: "UCS", supplement: 0 },
            mapping: str_mapping,
            code_size: 1,
          ).to_s
        end
        MAX_BFCHAR_ENTRIES = 100

        attr_reader :cmap_name, :cid_system_info, :mapping

        # @param cmap_name [String, Symbol] e.g. "Adobe-Identity-UCS"
        # @param cid_system_info [Hash] with :registry, :ordering, :supplement
        # @param mapping [Hash<Integer => String>] glyph code → Unicode string
        # @param code_size [Integer] 1 or 2 (bytes per glyph code)
        def initialize(cmap_name:, cid_system_info:, mapping:, code_size: 2)
          @cmap_name = cmap_name.to_s
          @cid_system_info = cid_system_info
          @mapping = mapping
          @code_size = code_size
        end

        def to_s
          buffer = +""
          emit_header(buffer)
          emit_codespacerange(buffer)
          emit_bfchar(buffer)
          emit_footer(buffer)
          buffer.force_encoding(::Encoding::BINARY)
        end

        private

        def emit_header(buffer)
          buffer << "/CIDInit /ProcSet findresource begin\n"
          buffer << "12 dict begin\n"
          buffer << "begincmap\n"
          buffer << "/CIDSystemInfo <<\n"
          buffer << "  /Registry (#{@cid_system_info[:registry] || 'Adobe'})\n"
          buffer << "  /Ordering (#{@cid_system_info[:ordering] || 'Identity'})\n"
          buffer << "  /Supplement #{@cid_system_info[:supplement] || 0}\n"
          buffer << ">> def\n"
          buffer << "/CMapName /#{@cmap_name} def\n"
          buffer << "/CMapType 1 def\n"
        end

        def emit_codespacerange(buffer)
          lo, hi = codespacerange_bounds
          buffer << "1 begincodespacerange\n"
          buffer << "  <#{lo}> <#{hi}>\n"
          buffer << "endcodespacerange\n"
        end

        def codespacerange_bounds
          case @code_size
          when 1 then ["00", "FF"]
          else        ["0000", "FFFF"]
          end
        end

        def emit_bfchar(buffer)
          return if @mapping.empty?

          @mapping.each_slice(MAX_BFCHAR_ENTRIES) do |chunk|
            buffer << "#{chunk.length} beginbfchar\n"
            chunk.each do |code, unicode_str|
              code_hex = format_code(code)
              unicode_hex = encode_unicode(unicode_str)
              buffer << "<#{code_hex}> <#{unicode_hex}>\n"
            end
            buffer << "endbfchar\n"
          end
        end

        def format_code(code)
          case @code_size
          when 1 then "%02X" % code
          else        "%04X" % code
          end
        end

        # Encode a Unicode string as hex pairs suitable for CMap.
        # Characters above U+FFFF are emitted as UTF-16 surrogate pairs.
        def encode_unicode(str)
          str.to_s.codepoints.map do |cp|
            if cp <= 0xFFFF
              "%04X" % cp
            else
              # Surrogate pair
              adjusted = cp - 0x10000
              high = 0xD800 + (adjusted >> 10)
              low = 0xDC00 + (adjusted & 0x3FF)
              "%04X%04X" % [high, low]
            end
          end.join
        end

        def emit_footer(buffer)
          buffer << "endcmap\n"
          buffer << "CMapName currentdict /CMap defineresource pop\n"
          buffer << "end\n"
          buffer << "end\n"
        end
      end
    end
  end
end
