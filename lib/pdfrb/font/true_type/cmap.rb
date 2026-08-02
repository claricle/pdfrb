# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      # `cmap` table parser. Resolves Unicode codepoints to glyph IDs
      # by picking the best available subtable and applying its
      # format-specific decoding.
      #
      # Supported subtable formats:
      #   * 0  — byte encoding (256 entries)
      #   * 4  — segment mapping (BMP)
      #   * 6  — trimmed table (range)
      #   * 12 — sparse coverage (full Unicode)
      #
      # Subtable selection prefers Unicode platforms:
      #   (3,10) Windows Unicode full > (0,* ) Unicode > (3,1) Windows BMP
      class Cmap
        attr_reader :subtable_offset, :platform_id, :encoding_id, :format

        PREFERRED_SUBTABLES = [
          [3, 12], # Windows Unicode full repertoire
          [0, 6],  # Unicode full (format 12-style)
          [0, 4],  # Unicode 2.0+ BMP
          [3, 1],  # Windows BMP
          [0, 0],  # Unicode 1.0
          [0, 1],  # Unicode 1.1
          [0, 2],  # Unicode 2.0 (no format declared)
          [0, 3], # Unicode 2.0+ BMP
        ].freeze
        private_constant :PREFERRED_SUBTABLES

        def initialize(data)
          @data = data
          @glyph_cache = {}
          return unless data && data.bytesize >= 4

          choose_subtable
        end

        # Unicode codepoint → glyph ID. Returns 0 (.notdef) if no
        # mapping exists.
        def glyph_id_for(unicode)
          return 0 if @format.nil?

          @glyph_cache[unicode] ||= lookup(unicode)
        end

        private

        def choose_subtable
          num_tables = u16(2)
          entries = []
          num_tables.times do |i|
            base = 4 + (i * 8)
            entries << {
              platform_id: u16(base),
              encoding_id: u16(base + 2),
              offset: u32(base + 4),
            }
          end
          pick = PREFERRED_SUBTABLES.each do |plat, enc|
            found = entries.find { |e| e[:platform_id] == plat && e[:encoding_id] == enc }
            break found if found
          end
          return unless pick.is_a?(::Hash)

          @platform_id = pick[:platform_id]
          @encoding_id = pick[:encoding_id]
          @subtable_offset = pick[:offset]
          read_format_header
        end

        def read_format_header
          @format = u16(@subtable_offset)
          case @format
          when 0 then parse_format_zero
          when 4 then parse_format_four
          when 6 then parse_format_six
          when 12 then parse_format_twelve
          else
            @format = nil
          end
        end

        def lookup(unicode)
          case @format
          when 0 then lookup_format_zero(unicode)
          when 4 then lookup_format_four(unicode)
          when 6 then lookup_format_six(unicode)
          when 12 then lookup_format_twelve(unicode)
          else 0
          end
        end

        # Format 0: 256-entry byte table.
        def parse_format_zero
          @f0_glyph_ids = (0..255).map { |i| u8(@subtable_offset + 6 + i) }
        end

        def lookup_format_zero(unicode)
          return 0 unless unicode < 256

          @f0_glyph_ids[unicode]
        end

        # Format 4: segment mapping. BMP only.
        def parse_format_four
          seg_count_x2 = u16(@subtable_offset + 6)
          seg_count = seg_count_x2 / 2
          end_codes_off = @subtable_offset + 14
          start_codes_off = end_codes_off + seg_count_x2 + 2
          id_deltas_off = start_codes_off + seg_count_x2
          id_range_offsets_off = id_deltas_off + seg_count_x2
          glyph_ids_off = id_range_offsets_off + seg_count_x2
          @f4 = {
            seg_count: seg_count,
            end_codes: read_u16s(end_codes_off, seg_count),
            start_codes: read_u16s(start_codes_off, seg_count),
            id_deltas: read_s16s(id_deltas_off, seg_count),
            id_range_offsets: read_u16s(id_range_offsets_off, seg_count),
            glyph_ids_off: glyph_ids_off,
          }
        end

        def lookup_format_four(unicode)
          return 0 unless @f4

          seg = @f4
          seg[:seg_count].times do |i|
            next if unicode > seg[:end_codes][i]

            return 0 if unicode < seg[:start_codes][i]

            delta = seg[:id_deltas][i]
            range_off = seg[:id_range_offsets][i]
            if range_off.zero?
              return (unicode + delta) & 0xFFFF
            end

            # Indirect: glyph_id_addr = id_range_offset + 2*(c - startCode) + addressof(idRangeOffsets[i])
            seg[:id_range_offsets_offset] + (i * 2) + range_off + ((unicode - seg[:start_codes][i]) * 2)
            abs_off = id_range_offset_abs(i, range_off, unicode, seg[:start_codes][i])
            gid = u16(abs_off)
            gid.zero? ? 0 : (gid + delta) & 0xFFFF
          end
          0
        end

        def id_range_offset_abs(i, range_off, unicode, start_code)
          seg = @f4
          base = seg[:id_range_offsets_offset] + (i * 2)
          base + range_off + ((unicode - start_code) * 2)
        end

        # Format 6: trimmed table.
        def parse_format_six
          first = u16(@subtable_offset + 6)
          count = u16(@subtable_offset + 8)
          @f6 = {
            first_code: first,
            count: count,
            glyph_ids: read_u16s(@subtable_offset + 10, count),
          }
        end

        def lookup_format_six(unicode)
          return 0 unless @f6

          idx = unicode - @f6[:first_code]
          return 0 unless idx >= 0 && idx < @f6[:count]

          @f6[:glyph_ids][idx]
        end

        # Format 12: sparse coverage, full Unicode.
        def parse_format_twelve
          num_groups = u32(@subtable_offset + 12)
          @f12 = []
          num_groups.times do |i|
            base = @subtable_offset + 16 + (i * 12)
            @f12 << {
              start_char: u32(base),
              end_char: u32(base + 4),
              start_gid: u32(base + 8),
            }
          end
        end

        def lookup_format_twelve(unicode)
          return 0 unless @f12

          # Binary search for the group covering this codepoint.
          lo = 0
          hi = @f12.length - 1
          while lo <= hi
            mid = (lo + hi) / 2
            g = @f12[mid]
            if unicode < g[:start_char]
              hi = mid - 1
            elsif unicode > g[:end_char]
              lo = mid + 1
            else
              return g[:start_gid] + (unicode - g[:start_char])
            end
          end
          0
        end

        def u8(off); @data.getbyte(off); end

        def u16(off)
          return 0 if off.nil? || off + 1 >= @data.bytesize

          (@data.getbyte(off) * 256) + @data.getbyte(off + 1)
        end

        def u32(off)
          return 0 if off.nil? || off + 3 >= @data.bytesize

          (((@data.getbyte(off) * 256) + @data.getbyte(off + 1)) * 65536) +
            ((@data.getbyte(off + 2) * 256) + @data.getbyte(off + 3))
        end

        def s16(off)
          v = u16(off)
          v >= 0x8000 ? v - 0x10000 : v
        end

        def read_u16s(off, count)
          Array.new(count) { |i| u16(off + (i * 2)) }
        end

        def read_s16s(off, count)
          Array.new(count) { |i| s16(off + (i * 2)) }
        end
      end
    end
  end
end
