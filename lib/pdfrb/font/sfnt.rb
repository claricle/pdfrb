# frozen_string_literal: true

module Pdfrb
  module Font
    # sfnt container (OpenType/TTF) table directory: the shared seam
    # for reading and rebuilding the wrapper around font outlines.
    # Both subsetters (TrueType glyf and CFF) rebuild the directory
    # around their subset tables; this module owns that format so
    # the two implementations cannot drift (they once disagreed even
    # on whether checksums are computed).
    module Sfnt
      Entry = Struct.new(:tag, :offset, :byte_length)

      module_function

      # Parse the table directory of an sfnt byte string.
      # Returns [sfnt_version, Array<Entry>].
      def parse_directory(sfnt)
        num_tables = (sfnt.getbyte(4) * 256) + sfnt.getbyte(5)
        version = sfnt.byteslice(0, 4)
        entries = (0...num_tables).map do |i|
          base = 12 + (i * 16)
          Entry.new(
            sfnt.byteslice(base, 4),
            sfnt.byteslice(base + 8, 4).unpack1("N"),
            sfnt.byteslice(base + 12, 4).unpack1("N")
          )
        end
        [version, entries]
      end

      # Raw bytes of +tag+'s table, or nil.
      def table_bytes(sfnt, tag)
        entry = parse_directory(sfnt)[1].find { |e| e.tag == tag }
        entry && sfnt.byteslice(entry.offset, entry.byte_length)
      end

      # Rebuild an sfnt wrapper: +sfnt_version+ is the 4-byte magic
      # (e.g. "\x00\x01\x00\x00" or "OTTO"), +tables+ an Array of
      # [tag, data] pairs. Checksums are computed per the sfnt spec
      # (sum of big-endian u32s over zero-padded data).
      def rebuild(sfnt_version, tables)
        num = tables.length
        search_range = (2**Math.log2(num).floor) * 16
        entry_selector = Math.log2(num).floor
        range_shift = (num * 16) - search_range

        out = +"".b
        out << sfnt_version.b
        out << [num, search_range, entry_selector, range_shift].pack("n4")

        sorted = tables.sort_by { |tag, _| tag }
        offset = 12 + (num * 16)
        sorted.each do |tag, data|
          out << tag.b << [checksum(data), offset, data.bytesize].pack("NNN")
          offset += (data.bytesize + 3) & ~3
        end
        sorted.to_h.each_value do |data|
          out << data.b
          out << ("\x00".b * ((4 - (out.bytesize % 4)) % 4))
        end
        out
      end

      def checksum(data)
        padded = data + ("\x00".b * ((4 - (data.bytesize % 4)) % 4))
        sum = 0
        padded.unpack("N*").each { |w| sum = (sum + w) & 0xFFFFFFFF }
        sum
      end
    end
  end
end
