# frozen_string_literal: true

module Pdfrb
  module Font
    module CFF
      # Parsed CFF table (TN5176). Exposes the pieces a subsetter
      # needs: header span, Name/String/Global-Subr INDEXes, Top DICT,
      # charset (format 0), CharStrings INDEX, Private DICT span, and
      # the Local Subr INDEX when present.
      class File
        attr_reader :data, :header_size, :name_index, :top_dict,
                    :string_index, :global_subrs, :charset_format,
                    :charset_sids, :charstrings, :private_span,
                    :local_subrs

        def initialize(data)
          @data = data.b
          parse
        end

        def num_glyphs
          charstrings&.size || 0
        end

        def charstring(gid)
          charstrings[gid] if charstrings
        end

        # Charset (format 0 only): gid -> SID, with .notdef implicit
        # at gid 0.
        def sid_for_gid(gid)
          return 0 if gid.zero?

          @charset_sids[gid - 1]
        end

        # Reverse charset: SID -> gid (first wins).
        def gid_for_sid(sid)
          @gid_by_sid ||= begin
            map = { 0 => 0 }
            @charset_sids.each_with_index { |s, i| map[s] ||= i + 1 }
            map
          end
          @gid_by_sid[sid]
        end

        private

        def parse
          @header_size = @data.getbyte(2)
          pos = @header_size

          @name_index, pos = Index.parse(@data, pos)
          top_index, pos = Index.parse(@data, pos)
          @top_dict = Dict.parse(top_index.items.first || "".b)
          @string_index, pos = Index.parse(@data, pos)
          @global_subrs, = Index.parse(@data, pos)

          # CharStrings first: the format-0 charset reader needs the
          # glyph count.
          parse_charstrings
          parse_charset
          parse_private
        end

        def parse_charset
          off = @top_dict.charset_offset
          @charset_sids = []
          if off.nil? || off.zero?
            @charset_format = :iso_glyph_order
            return
          end

          format = @data.getbyte(off)
          @charset_format = format
          case format
          when 0
            (@charstrings&.size || 0).times do |i|
              @charset_sids << @data.byteslice(off + 1 + (i * 2), 2).unpack1("n")
            end
          when 1, 2
            parse_range_charset(off, format)
          end
        end

        # Formats 1/2 (TN5176 s18): [first(n2) nLeft(C1|n2)]* ranges;
        # SIDs run consecutively from first for nLeft+1 entries.
        def parse_range_charset(off, format)
          pos = off + 1
          count = @charstrings&.size || 0
          while @charset_sids.size < count && pos < @data.bytesize
            first = @data.byteslice(pos, 2).unpack1("n")
            pos += 2
            n_left = format == 1 ? @data.getbyte(pos) : @data.byteslice(pos, 2).unpack1("n")
            pos += format == 1 ? 1 : 2
            (0..n_left).each do |i|
              @charset_sids << (first + i)
            end
          end
        end

        def parse_charstrings
          off = @top_dict.charstrings_offset
          return if off.nil? || off.zero?

          @charstrings, = Index.parse(@data, off)
        end

        def parse_private
          span = @top_dict.private_size_offset
          return if span.nil?

          size, offset = span
          @private_span = [offset, size]

          priv = Dict.parse(@data.byteslice(offset, size))
          subrs_entry = priv.entry_for(19)
          return unless subrs_entry

          subrs_off = subrs_entry.int_operand
          @local_subrs, = Index.parse(@data, offset + subrs_off) if subrs_off&.positive?
        end
      end
    end
  end
end
