require "set"

# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      # Glyph subsetting for embedded TrueType fonts. Given a set of
      # used glyph IDs, produces a new TTF with only those glyphs.
      #
      # Rewrites: glyf, loca, cmap, hmtx, hhea, maxp, head.
      # Handles composite glyphs (diacritics) by recursively including
      # referenced component glyphs.
      #
      # Falls back to returning the full font if subsetting fails.
      class Subsetter
        NOTDEF_GID = 0
        SFNT_VERSION = [0x00010000].freeze

        attr_reader :ttf, :glyph_ids

        # @param ttf [Pdfrb::Font::TrueType::File] parsed TTF source.
        # @param glyph_ids [Array<Integer>] used glyph IDs.
        def initialize(ttf, glyph_ids)
          @ttf = ttf
          @glyph_ids = ([NOTDEF_GID] + glyph_ids).sort.uniq
        end

        # Returns the subset font bytes.
        def subset
          @subset ||= build_subset
        end

        # Returns the mapping old_gid → new_gid.
        def glyph_map
          @glyph_map ||= begin
            map = {}
            resolved_gids.each_with_index { |old_gid, new_gid| map[old_gid] = new_gid }
            map
          end
        end

        private

        def build_subset
          return @ttf.instance_variable_get(:@data) unless can_subset?

          @resolved = resolve_composites(@glyph_ids)

          new_glyf = build_glyf
          new_loca = build_loca(new_glyf)
          new_cmap = build_cmap
          new_hmtx = build_hmtx
          new_maxp = build_maxp

          tables = {}
          tables["glyf"] = new_glyf
          tables["loca"] = new_loca
          tables["cmap"] = new_cmap
          tables["hmtx"] = new_hmtx
          tables["maxp"] = new_maxp
          tables["head"] = build_head
          tables["hhea"] = build_hhea

          copy_remaining_tables(tables)
          assemble_ttf(tables)
        rescue StandardError
          @ttf.instance_variable_get(:@data)
        end

        def can_subset?
          glyf_table && loca_table && head_table && maxp_table
        end

        def glyf_table; @glyf_table ||= @ttf.glyf_table; end
        def loca_table; @loca_table ||= @ttf.loca_table; end
        def head_table; @head_table ||= @ttf.head_table; end
        def maxp_table; @maxp_table ||= @ttf.maxp_table; end
        def hmtx_table; @hmtx_table ||= @ttf.hmtx_table; end
        def cmap_table; @cmap_table ||= @ttf.cmap_table; end

        def resolved_gids
          @resolved
        end

        # Recursively include composite glyph components.
        def resolve_composites(gids, seen = Set.new)
          result = []
          queue = gids.dup
          until queue.empty?
            gid = queue.shift
            next if seen.include?(gid)
            next if gid >= num_glyphs

            seen << gid
            result << gid

            components = composite_components(gid)
            queue.concat(components) if components
          end
          result.sort.uniq
        end

        def num_glyphs
          @ttf.num_glyphs
        end

        def loca_format
          head_table.long_loca? ? :long : :short
        end

        # Get byte range [start, end) for a glyph in the glyf table.
        def glyph_range(gid)
          if loca_format == :long
            start_off = u32(loca_table, gid * 4)
            end_off = u32(loca_table, (gid + 1) * 4)
          else
            start_off = u16(loca_table, gid * 2) * 2
            end_off = u16(loca_table, (gid + 1) * 2) * 2
          end
          [start_off, end_off]
        end

        def glyph_data(gid)
          s, e = glyph_range(gid)
          return nil if s == e # empty glyph

          glyf_table.byteslice(s, e - s)
        end

        # Parse a composite glyph and return component GIDs.
        def composite_components(gid)
          data = glyph_data(gid)
          return nil unless data && data.bytesize >= 2

          num_contours = s16_raw(data, 0)
          return nil unless num_contours.negative? # composite flag

          components = []
          offset = 10 # skip bbox (4 × int16)
          loop do
            break if offset + 4 > data.bytesize

            flags = u16(data, offset)
            comp_gid = u16(data, offset + 2)
            components << comp_gid

            offset += 4
            offset += 2 if flags.anybits?(0x0001)   # ARG_1_AND_2_ARE_WORDS
            offset += 4 if flags.anybits?(0x0008)   # WE_HAVE_A_SCALE
            offset += 8 if flags.anybits?(0x0040)   # WE_HAVE_AN_X_AND_Y_SCALE
            offset += 8 if flags.anybits?(0x0080)   # WE_HAVE_A_TWO_BY_TWO
            offset += 4 if flags.anybits?(0x0020)   # WE_HAVE_INSTRUCTIONS (skip)
            break if flags.nobits?(0x0020) # MORE_COMPONENTS absent
          end
          components
        end

        def build_glyf
          data = +""
          @glyf_offsets = {}
          @resolved.each do |old_gid|
            @glyf_offsets[old_gid] = data.bytesize
            gd = glyph_data(old_gid)
            if gd
              data << remap_composite(gd) if composite?(gd)
              data << gd unless composite?(gd)
            end
            pad_to_even(data)
          end
          @glyf_end = data.bytesize
          data.force_encoding(Encoding::BINARY)
        end

        def composite?(glyph_data)
          glyph_data && glyph_data.bytesize >= 2 &&
            s16_raw(glyph_data, 0).negative?
        end

        # Remap component glyph IDs in a composite glyph.
        def remap_composite(data)
          remapped = data.dup
          offset = 10 # skip bbox
          loop do
            break if offset + 4 > remapped.bytesize

            flags = u16(remapped, offset)
            old_comp_gid = u16(remapped, offset + 2)
            new_comp_gid = glyph_map[old_comp_gid] || 0

            remapped.setbyte(offset + 2, (new_comp_gid >> 8) & 0xFF)
            remapped.setbyte(offset + 3, new_comp_gid & 0xFF)

            offset += 4
            offset += 2 if flags.anybits?(0x0001)
            offset += 4 if flags.anybits?(0x0008)
            offset += 8 if flags.anybits?(0x0040)
            offset += 8 if flags.anybits?(0x0080)
            offset += 4 if flags.anybits?(0x0020)
            break if flags.nobits?(0x0020)
          end
          remapped
        end

        def build_loca(_new_glyf)
          offsets = []
          @resolved.each do |old_gid|
            off = @glyf_offsets[old_gid] || 0
            offsets << off
          end
          offsets << @glyf_end

          data = +""
          if loca_format == :long
            offsets.each { |o| data << [o].pack("N") }
          else
            offsets.each { |o| data << [o / 2].pack("n") }
          end
          data.force_encoding(Encoding::BINARY)
        end

        def build_cmap
          # Build a simple format 4 cmap with used codepoints.
          # Map Unicode → new glyph IDs.
          pairs = {}
          @resolved.each do |old_gid|
            glyph_map[old_gid]
            # We don't have a reverse cmap (gid → unicode); skip for now.
            # A real impl would use the original cmap to build this.
          end

          # Emit a minimal format 4 cmap with just .notdef.
          build_format4_cmap(pairs)
        end

        def build_format4_cmap(_mapping)
          1
          search_range = 2
          entry_selector = 0
          range_shift = 0

          buf = +""
          buf << [0].pack("n")       # format 0 placeholder; we'll emit format 4
          buf = +""
          buf << [4, 0].pack("nn")   # format=4, length placeholder
          buf << [0].pack("n") # language
          seg_count = 1
          buf << [seg_count * 2].pack("n") # segCountX2
          buf << [search_range].pack("n")
          buf << [entry_selector].pack("n")
          buf << [range_shift].pack("n")
          buf << [0xFFFF].pack("n")   # endCode
          buf << [0].pack("n")        # reservedPad
          buf << [0xFFFF].pack("n")   # startCode
          buf << [0].pack("n")        # idDelta
          buf << [0].pack("n")        # idRangeOffset

          length = buf.bytesize
          buf[2, 2] = [length].pack("n")

          # Wrap in cmap table structure
          cmap = +""
          cmap << [0, 1, 1].pack("nnn") # version, numTables, platform=1
          cmap << [0].pack("n") # encoding=0
          cmap << [12].pack("N") # offset to subtable
          cmap << buf
          cmap.force_encoding(Encoding::BINARY)
        end

        def build_hmtx
          buf = +""
          @resolved.each do |old_gid|
            advance = @ttf.hmtx.advance_width(old_gid)
            lsb = @ttf.hmtx.lsb(old_gid)
            buf << [advance, lsb].pack("nn")
          end
          buf.force_encoding(Encoding::BINARY)
        end

        def build_maxp
          data = maxp_table.dup
          # Set numGlyphs at offset 4
          data.setbyte(4, (@resolved.length >> 8) & 0xFF)
          data.setbyte(5, @resolved.length & 0xFF)
          data
        end

        def build_head
          head_table.is_a?(::String) ? head_table.dup : "".b
        end

        def build_hhea
          data = @ttf.hhea_table ? @ttf.hhea_table.dup : "".b
          if data.bytesize >= 34
            data.setbyte(34, (@resolved.length >> 8) & 0xFF)
            data.setbyte(35, @resolved.length & 0xFF)
          end
          data
        end

        def copy_remaining_tables(tables)
          raw = @ttf.instance_variable_get(:@data)
          num_tables = (raw.getbyte(4) * 256) + raw.getbyte(5)
          num_tables.times do |i|
            base = 12 + (i * 16)
            tag = raw.byteslice(base, 4)
            next if tables.key?(tag)
            next if ["loca", "glyf", "cmap", "hmtx", "maxp", "head", "hhea"].include?(tag)

            offset = raw.byteslice(base + 8, 4).unpack1("N")
            length = raw.byteslice(base + 12, 4).unpack1("N")
            tables[tag] = raw.byteslice(offset, length)
          end
        end

        # rubocop:disable Metrics/MethodLength
        def assemble_ttf(tables)
          checksum_placeholder = [0].pack("N")
          num = tables.length
          search_range = power_of_2_floor(num) * 16
          entry_selector = Math.log2(search_range / 16).to_i
          range_shift = (num * 16) - search_range

          header_size = 12
          dir_size = num * 16
          data_offset = header_size + dir_size

          # Pad data_offset to 4 bytes
          data_offset = (data_offset + 3) & ~3

          out = +""
          out << SFNT_VERSION.pack("N") # sfnt version
          out << [num].pack("n")
          out << [search_range].pack("n")
          out << [entry_selector].pack("n")
          out << [range_shift].pack("n")

          # Sort tables by tag
          sorted = tables.sort_by { |tag, _| tag }

          # Calculate offsets
          current = data_offset
          offsets = {}
          sorted.each do |tag, data|
            offsets[tag] = current
            current += data.bytesize
            current = (current + 3) & ~3

            # Directory
            out << tag.to_s
            out << checksum_placeholder # checksum (skip)
            out << [offsets[tag]].pack("N")
            out << [data.bytesize].pack("N")
          end

          # Pad to data_offset
          while out.bytesize < data_offset
            out << "\x00"
          end

          # Table data
          sorted.each_value do |data|
            out << data
            while (out.bytesize % 4).nonzero?
              out << "\x00"
            end
          end

          out.force_encoding(Encoding::BINARY)
        end
        # rubocop:enable Metrics/MethodLength

        # rubocop:disable Naming/MethodName
        # ---- Binary helpers ----

        def u32(str, off)
          (((str.getbyte(off) * 256) + str.getbyte(off + 1)) * 65536) +
            ((str.getbyte(off + 2) * 256) + str.getbyte(off + 3))
        end

        def u16(str, off); (str.getbyte(off) * 256) + str.getbyte(off + 1); end

        def s16_raw(str, off)
          v = u16(str, off)
          v >= 0x8000 ? v - 0x10000 : v
        end

        def pad_to_even(str); str << "\x00" if (str.bytesize % 2).nonzero?; end

        # rubocop:enable Naming/MethodName
        def power_of_2_floor(n)
          p = 1
          while p * 2 <= n; p *= 2; end
          p
        end
      end
    end
  end
end
