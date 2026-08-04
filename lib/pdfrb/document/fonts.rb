# frozen_string_literal: true

require "stringio"

module Pdfrb
  class Document
    class Fonts
      STANDARDS = %w[
        Helvetica Helvetica-Bold Helvetica-Oblique Helvetica-BoldOblique
        Times-Roman Times-Bold Times-Italic Times-BoldItalic
        Courier Courier-Bold Courier-Oblique Courier-BoldOblique
        Symbol ZapfDingbats
      ].freeze

      NO_ENCODING_FONTS = %w[Symbol ZapfDingbats].freeze
      DEFAULT_WIDTH = 500

      attr_reader :document

      def initialize(document)
        @document = document
        @next_id = 1
        @registry = {}
        @encodings = {}
        @font_dicts = {}
        @afm_metrics = {}
        @used_codepoints = Hash.new { |h, k| h[k] = Set.new }
        @font_streams = {}
      end

      def add(name_or_io, **opts)
        name = font_name_for(name_or_io)
        cached = @registry[name]
        return cached if cached

        resource = next_resource_name
        font_dict = register_font(resource, name, **opts)
        @encodings[resource] = font_dict&.value&.[](:Encoding)
        @font_dicts[resource] = font_dict
        load_afm_metrics(resource, name)
        if @pending_io_data
          @font_streams[resource] = @pending_io_data
          @pending_io_data = nil
        end
        @registry[name] = resource
        resource
      end

      def [](name); @registry[name]; end

      def each(&block)
        return enum_for(:each) unless block_given?
        @registry.each(&block)
        self
      end

      def used_codepoints(resource); @used_codepoints[resource]; end
      def encoding_for(resource); @encodings[resource]; end

      def encode_text(text, resource)
        text.to_s.each_codepoint { |cp| @used_codepoints[resource] << cp }
        enc = @encodings[resource]
        return text.to_s.b unless enc
        Pdfrb::Font::Encoding.encode(enc, text.to_s)
      end

      def encodable?(text, resource); !encode_text(text, resource).include?("?"); end

      def measure_text(text, font:, size:)
        return 0 unless text && size
        metrics = @afm_metrics[font]
        return text.to_s.length * size.to_f * 0.5 unless metrics
        total = text.to_s.each_char.sum do |ch|
          byte = ch.bytes.first || 0
          metrics[:widths][byte] || DEFAULT_WIDTH
        end
        total * size.to_f / 1000.0
      end

      def text_width(text, _resource, size:)
        return 0 unless text && size
        metrics = _resource && @afm_metrics[_resource]
        return text.to_s.length * size.to_f * 0.5 unless metrics
        total = text.to_s.each_char.sum do |ch|
          byte = ch.bytes.first || 0
          metrics[:widths][byte] || DEFAULT_WIDTH
        end
        total * size.to_f / 1000.0
      end

      def glyph_width(char, resource)
        metrics = @afm_metrics[resource]
        return DEFAULT_WIDTH unless metrics
        byte = char.to_s.bytes.first || 0
        metrics[:widths][byte] || DEFAULT_WIDTH
      end

      def glyph_widths(text, resource); text.to_s.each_char.map { |c| glyph_width(c, resource) }; end
      def metrics_for(resource); @afm_metrics[resource]; end

      def valid_font_data?(data)
        return false unless data.respond_to?(:bytesize) && data.bytesize >= 4
        magic = data.byteslice(0, 4)
        ["ttcf".b, "\x00\x01\x00\x00".b, "OTTO".b, "true".b, "typ1".b].include?(magic)
      end

      def embedded?(resource)
        dict = @font_dicts[resource]
        return false unless dict
        desc = dict.value[:FontDescriptor]
        return false unless desc
        desc = document.object(desc) if desc.is_a?(Pdfrb::Model::Reference)
        desc&.value&.key?(:FontFile2)
      end

      def subset_fonts!
        @font_streams.each do |resource, data|
          next unless valid_font_data?(data)
          codepoints = @used_codepoints[resource]
          next if codepoints.empty?
          begin
            ttf = Pdfrb::Font::TrueType::File.new(data)
            subsetter = Pdfrb::Font::TrueType::Subsetter.new(ttf)
            subset = subsetter.subset(codepoints.to_a)
            dict = @font_dicts[resource]
            next unless dict
            desc_ref = dict.value[:FontDescriptor]
            next unless desc_ref
            desc = desc_ref.is_a?(Pdfrb::Model::Reference) ? document.object(desc_ref) : desc_ref
            next unless desc
            fd_stream = document.add({ Length: subset.bytesize }, type: Pdfrb::Model::Cos::Stream)
            fd_stream.stream = subset
            desc.value[:FontFile2] = Pdfrb::Model::Reference.new(fd_stream.oid, fd_stream.gen)
          rescue StandardError
            next
          end
        end
      end

      class << self
        def loaders; @loaders ||= []; end
        def register_loader(loader); loaders.unshift(loader); end
      end

      register_loader ->(doc, name, **opts) {
        next nil unless STANDARDS.include?(name.to_s)
        next nil unless opts[:embedded].nil?
        widths = Array.new(256, DEFAULT_WIDTH)
        tu_stream = build_tounicode(doc)
        tu_ref = Pdfrb::Model::Reference.new(tu_stream.oid, tu_stream.gen)
        fd = doc.add({
          Type: :FontDescriptor, FontName: name.to_sym, Flags: 32,
          FontBBox: [0, 0, 1000, 1000], ItalicAngle: 0,
          Ascent: 800, Descent: -200, CapHeight: 700, StemV: 80,
        }, type: Pdfrb::Model::Cos::Dictionary)
        fd_ref = Pdfrb::Model::Reference.new(fd.oid, fd.gen)
        font_hash = {
          Type: :Font, Subtype: :Type1, BaseFont: name.to_sym,
          FirstChar: 0, LastChar: 255, Widths: widths,
          FontDescriptor: fd_ref, ToUnicode: tu_ref,
        }
        font_hash[:Encoding] = :WinAnsiEncoding unless NO_ENCODING_FONTS.include?(name.to_s)
        doc.add(font_hash, type: Pdfrb::Model::Type::FontType1)
      }

      def self.build_tounicode(doc)
        cmap_body = build_tounicode_cmap
        stream = doc.add({ Length: cmap_body.bytesize }, type: Pdfrb::Model::Cos::Stream)
        stream.stream = cmap_body
        stream
      end

      def self.build_tounicode_cmap
        lines = []
        lines << "/CIDInit /ProcSet findresource begin"
        lines << "12 dict begin"
        lines << "begincmap"
        lines << "/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def"
        lines << "/CMapName /Adobe-Identity-UCS def"
        lines << "/CMapType 2 def"
        lines << "1 begincodespacerange"
        lines << "<00> <FF>"
        lines << "endcodespacerange"
        table = Pdfrb::Font::Encoding::WinAnsiEncoding::TABLE
        pairs = []
        table.each_with_index { |cp, byte| pairs << format("<%02X> <%04X>", byte, cp) if cp }
        pairs.each_slice(100) do |chunk|
          lines << "#{chunk.length} beginbfchar"
          lines.concat(chunk)
          lines << "endbfchar"
        end
        lines << "endcmap"
        lines << "CMapName currentdict /CMap defineresource pop"
        lines << "end"
        lines << "end"
        lines.join("\n") + "\n"
      end

      private

      def load_afm_metrics(resource, name)
        return unless STANDARDS.include?(name.to_s)
        afm_path = Pdfrb::DataDir.resolve("afm", "#{name}.afm")
        return unless File.exist?(afm_path)
        begin
          parser = Pdfrb::Font::AFMParser.from_file(afm_path)
          widths = build_winansi_widths(parser)
          @afm_metrics[resource] = {
            widths: widths,
            ascent: parser.ascender || 800,
            descent: parser.descender || -200,
            cap_height: parser.cap_height || 700,
            bbox: parser.bbox || [0, 0, 1000, 1000],
          }
        rescue StandardError
          nil
        end
      end

      def build_winansi_widths(parser)
        widths = Array.new(256, DEFAULT_WIDTH)
        (0..127).each do |byte|
          metric = parser.char_metrics[byte]
          widths[byte] = metric[:width].to_i if metric && metric[:width]
        end
        table = Pdfrb::Font::Encoding::WinAnsiEncoding::TABLE
        (128..255).each do |byte|
          cp = table[byte]
          next unless cp
          glyph_name = unicode_to_glyph_name(cp)
          next unless glyph_name
          metric = parser.char_metrics[glyph_name]
          widths[byte] = metric[:width].to_i if metric && metric[:width]
        end
        widths
      end

      def unicode_to_glyph_name(cp)
        return cp.chr if cp < 128
        {0x20AC=>"Euro",0x201A=>"quotesinglbase",0x0192=>"florin",0x201E=>"quotedblbase",
         0x2026=>"ellipsis",0x2020=>"dagger",0x2021=>"daggerdbl",0x02C6=>"circumflex",
         0x2030=>"perthousand",0x0160=>"Scaron",0x2039=>"guilsinglleft",0x0152=>"OE",
         0x017D=>"Zcaron",0x2018=>"quoteleft",0x2019=>"quoteright",0x201C=>"quotedblleft",
         0x201D=>"quotedblright",0x2022=>"bullet",0x2013=>"endash",0x2014=>"emdash",
         0x02DC=>"tilde",0x2122=>"trademark",0x0161=>"scaron",0x203A=>"guilsinglright",
         0x0153=>"oe",0x017E=>"zcaron",0x0178=>"Ydieresis",0x00A0=>"space",
         0x00A1=>"exclamdown",0x00A2=>"cent",0x00A3=>"sterling",0x00A4=>"currency",
         0x00A5=>"yen",0x00A6=>"brokenbar",0x00A7=>"section",0x00A8=>"dieresis",
         0x00A9=>"copyright",0x00AA=>"ordfeminine",0x00AB=>"guillemotleft",
         0x00AC=>"logicalnot",0x00AD=>"hyphen",0x00AE=>"registered",0x00AF=>"macron",
         0x00B0=>"degree",0x00B1=>"plusminus",0x00B2=>"twosuperior",0x00B3=>"threesuperior",
         0x00B4=>"acute",0x00B5=>"mu",0x00B6=>"paragraph",0x00B7=>"periodcentered",
         0x00B8=>"cedilla",0x00B9=>"onesuperior",0x00BA=>"ordmasculine",
         0x00BB=>"guillemotright",0x00BC=>"onequarter",0x00BD=>"onehalf",
         0x00BE=>"threequarters",0x00BF=>"questiondown",0x00C0=>"Agrave",
         0x00C1=>"Aacute",0x00C2=>"Acircumflex",0x00C3=>"Atilde",0x00C4=>"Adieresis",
         0x00C5=>"Aring",0x00C6=>"AE",0x00C7=>"Ccedilla",0x00C8=>"Egrave",
         0x00C9=>"Eacute",0x00CA=>"Ecircumflex",0x00CB=>"Edieresis",0x00CC=>"Igrave",
         0x00CD=>"Iacute",0x00CE=>"Icircumflex",0x00CF=>"Idieresis",0x00D0=>"Eth",
         0x00D1=>"Ntilde",0x00D2=>"Ograve",0x00D3=>"Oacute",0x00D4=>"Ocircumflex",
         0x00D5=>"Otilde",0x00D6=>"Odieresis",0x00D7=>"multiply",0x00D8=>"Oslash",
         0x00D9=>"Ugrave",0x00DA=>"Uacute",0x00DB=>"Ucircumflex",0x00DC=>"Udieresis",
         0x00DD=>"Yacute",0x00DE=>"Thorn",0x00DF=>"germandbls",0x00E0=>"agrave",
         0x00E1=>"aacute",0x00E2=>"acircumflex",0x00E3=>"atilde",0x00E4=>"adieresis",
         0x00E5=>"aring",0x00E6=>"ae",0x00E7=>"ccedilla",0x00E8=>"egrave",
         0x00E9=>"eacute",0x00EA=>"ecircumflex",0x00EB=>"edieresis",0x00EC=>"igrave",
         0x00ED=>"iacute",0x00EE=>"icircumflex",0x00EF=>"idieresis",0x00F0=>"eth",
         0x00F1=>"ntilde",0x00F2=>"ograve",0x00F3=>"oacute",0x00F4=>"ocircumflex",
         0x00F5=>"otilde",0x00F6=>"odieresis",0x00F7=>"divide",0x00F8=>"oslash",
         0x00F9=>"ugrave",0x00FA=>"uacute",0x00FB=>"ucircumflex",0x00FC=>"udieresis",
         0x00FD=>"yacute",0x00FE=>"thorn",0x00FF=>"ydieresis"}[cp]
      end

      def font_name_for(name_or_io)
        case name_or_io
        when Symbol, String then name_or_io.to_s
        when IO, StringIO
          @pending_io_data = name_or_io.read
          "EmbeddedFont-#{@pending_io_data.bytesize}"
        else
          raise ArgumentError, "font name must be a String, Symbol, or IO"
        end
      end

      def next_resource_name; sym = :"F#{@next_id}"; @next_id += 1; sym; end

      def register_font(resource, name, **opts)
        loader = self.class.loaders.find { |l| l.call(document, name, **opts) }
        font_dict = loader ? loader.call(document, name, **opts) : default_font(name)
        attach_to_resources(resource, font_dict)
        font_dict
      end

      def default_font(name)
        tu_stream = self.class.build_tounicode(document)
        tu_ref = Pdfrb::Model::Reference.new(tu_stream.oid, tu_stream.gen)
        document.add({
          Type: :Font, Subtype: :Type1, BaseFont: name.to_sym,
          Encoding: :WinAnsiEncoding, FirstChar: 0, LastChar: 255,
          Widths: Array.new(256, DEFAULT_WIDTH), ToUnicode: tu_ref,
        }, type: Pdfrb::Model::Type::FontType1)
      end

      def attach_to_resources(resource, font_dict)
        ref = Pdfrb::Model::Reference.new(font_dict.oid, font_dict.gen)
        catalog = document.catalog
        catalog.value[:Resources] ||= {}
        catalog.value[:Resources][:Font] ||= {}
        catalog.value[:Resources][:Font][resource] = ref
      end
    end
  end
end
