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

      attr_reader :document, :used_codepoints

      def initialize(document)
        @document = document
        @next_id = 1
        @registry = {}
        @encodings = {}
        @font_dicts = {}
        @used_codepoints = Hash.new { |h, k| h[k] = Set.new }
      end

      def add(name_or_io, **opts)
        name = font_name_for(name_or_io)
        cached = @registry[name]
        return cached if cached

        resource = next_resource_name
        font_dict = register_font(resource, name, **opts)
        @encodings[resource] = font_dict&.value&.[](:Encoding)
        @font_dicts[resource] = font_dict
        @registry[name] = resource
        resource
      end

      def [](name)
        @registry[name]
      end

      def each(&block)
        return enum_for(:each) unless block_given?

        @registry.each(&block)
        self
      end

      def encoding_for(resource)
        @encodings[resource]
      end

      def encode_text(text, resource)
        enc = @encodings[resource]
        return text.to_s.b unless enc

        Pdfrb::Font::Encoding.encode(enc, text.to_s)
      end

      def encodable?(text, resource)
        !encode_text(text, resource).include?("?")
      end

      def measure_text(text, font:, size:)
        return 0 unless text

        # TODO: use font metrics for per-glyph width lookup
        _font = font
        text.to_s.length * (size || 0).to_f * 0.5
      end

      def text_width(text, _resource, size)
        return 0 unless text

        text.to_s.length * (size || 0).to_f * 0.5
      end

      def glyph_width(_char, _resource)
        500
      end

      def glyph_widths(text, resource)
        text.to_s.each_char.map { glyph_width(_1, resource) }
      end

      def metrics_for(_resource)
        nil
      end

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

      class << self
        def loaders
          @loaders ||= []
        end

        def register_loader(loader)
          loaders.unshift(loader)
        end
      end

      register_loader ->(doc, name, **opts) {
        next nil unless STANDARDS.include?(name.to_s)
        next nil unless opts[:embedded].nil?

        doc.add(
          { Type: :Font, Subtype: :Type1, BaseFont: name.to_sym },
          type: Pdfrb::Model::Type::FontType1
        )
      }

      private

      def font_name_for(name_or_io)
        case name_or_io
        when Symbol, String then name_or_io.to_s
        when IO, StringIO then "EmbeddedFont-#{name_or_io.read.bytesize}"
        else
          raise ArgumentError, "font name must be a String, Symbol, or IO"
        end
      end

      def next_resource_name
        sym = :"F#{@next_id}"
        @next_id += 1
        sym
      end

      def register_font(resource, name, **opts)
        loader = self.class.loaders.find { |l| l.call(document, name, **opts) }
        font_dict = loader ? loader.call(document, name, **opts) : default_font(name)
        attach_to_resources(resource, font_dict)
        font_dict
      end

      def default_font(name)
        document.add(
          { Type: :Font, Subtype: :Type1, BaseFont: name.to_sym },
          type: Pdfrb::Model::Type::FontType1
        )
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
