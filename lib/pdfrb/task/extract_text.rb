# frozen_string_literal: true

module Pdfrb
  module Task
    # Extract plain text from a document by walking each page's
    # content stream. Decodes glyph codes back to Unicode using:
    #
    #   1. The font's /ToUnicode CMap (preferred — gives proper
    #      Unicode for CIDFont / embedded TTF fonts).
    #   2. The font's /Encoding + AdobeStandardEncoding glyph names
    #      (fallback for Type1 standard fonts).
    #   3. ASCII passthrough (last resort).
    #
    # Tracks the text matrix to insert line breaks at vertical moves
    # and approximate paragraph breaks.
    module ExtractText
      module_function

      def call(document)
        results = []
        document.pages.each do |page|
          extractor = TextCollector.new(document, page)
          begin
            extractor.process(page.decoded_content)
          rescue StandardError
            # Malformed content stream — best effort, skip.
          end
          text = extractor.text
          block_given? ? yield(page, text) : (results << text)
        end
        block_given? ? document : results
      end

      # Internal: collects bytes from +Tj+ / +TJ+ / +'+ / +"'.
      # Tracks text-matrix y to insert line breaks at vertical moves.
      # Resolves glyph codes to Unicode via the active font's
      # /ToUnicode CMap or /Encoding.
      class TextCollector < Pdfrb::Content::Processor
        attr_reader :text

        def initialize(document, page)
          super()
          @document = document
          @page = page
          @text = +""
          @last_y = nil
          @font_resolver = FontResolver.new(document, page)
        end

        def show_text(str)
          check_line_break
          @text << decode(str)
        end

        def show_text_array(arr)
          check_line_break
          arr.each do |e|
            case e
            when ::String then @text << decode(e)
            when Numeric then next # kerning adjustment; ignore
            end
          end
        end

        def move_text(tx, ty, **)
          super
          check_line_break
        end

        def update_text_state(**overrides)
          super
          @font_resolver.activate(graphics_state.text_state.font_name) if overrides.key?(:font_name)
        end

        private

        def check_line_break
          cur_y = graphics_state.text_state.text_matrix.f
          if @last_y && (cur_y - @last_y).abs > 0.001
            @text << "\n"
          end
          @last_y = cur_y
        end

        def decode(bytes)
          @font_resolver.decode(bytes)
        end
      end

      # Resolves glyph codes to Unicode strings for the active font.
      class FontResolver
        def initialize(document, page)
          @document = document
          @page = page
          @cache = {} # font_name -> decoder (CMap or Encoding)
          @active = nil
        end

        def activate(font_name)
          return if font_name.nil? || font_name == @active_name

          @active_name = font_name
          @active = loader_for(font_name)
        end

        def decode(bytes)
          return bytes.to_s.dup.force_encoding("UTF-8") unless @active

          @active.decode(bytes.to_s)
        end

        private

        def loader_for(font_name)
          return @cache[font_name] if @cache.key?(font_name)

          @cache[font_name] = build_decoder(font_name)
        end

        def build_decoder(font_name)
          font_dict = find_font(font_name)
          return IdentityDecoder.new unless font_dict

          ToUnicodeDecoder.new(font_dict) || EncodingDecoder.new(font_dict) || IdentityDecoder.new
        end

        def find_font(name)
          resources = @page[:Resources]
          return nil unless resources

          resources = @document.object(resources) if resources.is_a?(Pdfrb::Model::Reference)
          fonts = resources[:Font]
          return nil unless fonts

          fonts = @document.object(fonts) if fonts.is_a?(Pdfrb::Model::Reference)
          return nil unless fonts.is_a?(::Hash)

          entry = fonts[name] || fonts[name.to_sym] || fonts[name.to_s]
          entry.is_a?(Pdfrb::Model::Reference) ? @document.object(entry) : entry
        end
      end
      private_constant :FontResolver

      # Uses the font's /ToUnicode CMap to decode glyph codes.
      class ToUnicodeDecoder
        def initialize(font_dict)
          @font_dict = font_dict
          @cmap = parse_tounicode(font_dict[:ToUnicode])
        end

        def self.for(font_dict); new(font_dict); end

        def decode(bytes)
          return bytes unless @cmap

          bytes_to_unicode(bytes)
        end

        private

        def parse_tounicode(ref)
          return nil unless ref

          doc = @font_dict.is_a?(Pdfrb::Model::Cos::Dictionary) ? @font_dict.document : nil
          stream = if ref.is_a?(Pdfrb::Model::Reference) && doc
                     doc.object(ref)
                   else
                     ref
                   end
          return nil unless stream.is_a?(Pdfrb::Model::Cos::Stream)

          data = stream.decoded_stream
          Pdfrb::Font::CMap::Parser.parse(data)
        rescue StandardError
          nil
        end

        def bytes_to_unicode(bytes)
          result = +""
          i = 0
          while i < bytes.length
            # Try 2-byte code first (most CIDFonts use 2-byte codes).
            code2 = bytes.getbyte(i) * 256
            code2 += bytes.getbyte(i + 1) if i + 1 < bytes.length
            decoded = @cmap.decode(code2)
            if decoded
              result << decoded
              i += 2
              next
            end

            code1 = bytes.getbyte(i)
            decoded1 = @cmap.decode(code1)
            result << (decoded1 || fallback_char(code1))
            i += 1
          end
          result
        end

        def fallback_char(byte)
          byte < 128 ? byte.chr : "?"
        end
      end
      private_constant :ToUnicodeDecoder

      # Uses the font's /Encoding (WinAnsiEncoding etc.) to decode bytes.
      class EncodingDecoder
        def initialize(font_dict)
          @font_dict = font_dict
        end

        def decode(bytes)
          encoding_name = @font_dict[:Encoding]
          case encoding_name
          when Symbol, ::String
            Pdfrb::Font::Encoding.decode(encoding_name, bytes)
          else
            bytes
          end
        end
      end
      private_constant :EncodingDecoder

      # Identity passthrough — assumes bytes are already UTF-8 (or
      # just gives back raw bytes for the caller to handle).
      class IdentityDecoder
        def decode(bytes); bytes.to_s; end
      end
      private_constant :IdentityDecoder
    end
  end
end
