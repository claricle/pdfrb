# frozen_string_literal: true

module Pdfrb
  module Font
    module TrueType
      # Minimal TrueType / OpenType font file reader. Parses the
      # sfnt header + table directory; lazy-loads individual tables
      # on access.
      class File
        attr_reader :tables, :num_tables

        def initialize(data)
          @data = data.b
          @tables = {}
          parse_directory
        end

        def self.read(path)
          new(::File.binread(path))
        end

        def table(tag)
          return @tables[tag][:data] if @tables[tag]

          entry = find_table_entry(tag)
          return nil unless entry

          offset = entry[:offset]
          length = entry[:length]
          @data.byteslice(offset, length).force_encoding(::Encoding::BINARY)
        end

        def cmap_table; table("cmap"); end
        def head_table; table("head"); end
        def hhea_table; table("hhea"); end
        def hmtx_table; table("hmtx"); end
        def name_table; table("name"); end
        def maxp_table; table("maxp"); end
        def post_table; table("post"); end
        def os2_table; table("OS/2"); end
        def glyf_table; table("glyf"); end
        def loca_table; table("loca"); end
      def kern_table; table("kern"); end

        # Parsed-table accessors. Lazy and memoised on the instance.
        def head; @head ||= Head.new(head_table); end

        def maxp; @maxp ||= Maxp.new(maxp_table); end
        def post; @post ||= Post.new(post_table); end
        def name_table_parsed; @name_parsed ||= Name.new(name_table); end
        def loca_parsed; @loca_parsed ||= Loca.new(loca_table, long_format: head.long_loca?, num_glyphs: maxp.num_glyphs); end
        def glyf_parsed; @glyf_parsed ||= Glyf.new(glyf_table, loca_parsed); end
        def kern_parsed; @kern_parsed ||= Kern.new(kern_table); end
        def hhea; @hhea ||= Hhea.new(hhea_table); end
        def os2; @os2 ||= OS2.new(os2_table); end
        def cmap; @cmap ||= Cmap.new(cmap_table); end

        def hmtx
          @hmtx ||= Hmtx.new(hmtx_table, number_of_hmetrics: hhea.number_of_hmetrics || 0)
        end

        def num_glyphs
          return 0 unless maxp_table

          maxp_table.getbyte(4) * 256 + maxp_table.getbyte(5)
        end

        private

        def parse_directory
          return if @data.bytesize < 12

          sfnt_version = @data.getbyte(0) * 256 + @data.getbyte(1)
          @num_tables = @data.getbyte(4) * 256 + @data.getbyte(5)
          @raw_entries = []
          @num_tables.times do |i|
            base = 12 + i * 16
            tag = @data.byteslice(base, 4)
            checksum = @data.byteslice(base + 4, 4).unpack1("N")
            offset = @data.byteslice(base + 8, 4).unpack1("N")
            length = @data.byteslice(base + 12, 4).unpack1("N")
            @raw_entries << { tag: tag, checksum: checksum,
                              offset: offset, length: length }
          end
        end

        def find_table_entry(tag)
          @raw_entries&.find { |e| e[:tag] == tag }
        end
      end
    end
  end
end
