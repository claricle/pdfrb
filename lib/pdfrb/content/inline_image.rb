# frozen_string_literal: true

module Pdfrb
  module Content
    # A BI ... ID ... EI inline image (s8.9.7). Carries the expanded
    # header keys (abbreviations resolved by the parser), the raw
    # encoded byte payload, and decodes on demand via the filter
    # pipeline.
    class InlineImage
      # Filter-name abbreviations permitted in inline images
      # (s8.9.7 Table 89).
      FILTER_ABBREVIATIONS = {
        AHx: :ASCIIHexDecode,
        A85: :ASCII85Decode,
        Fl: :FlateDecode,
        LZW: :LZWDecode,
        CCF: :CCITTFaxDecode,
        DCT: :DCTDecode,
        RL: :RunLengthDecode,
      }.freeze

      # Color-space-name abbreviations (s8.9.7 Table 89).
      COLOR_SPACE_ABBREVIATIONS = {
        G: :DeviceGray,
        RGB: :DeviceRGB,
        CMYK: :DeviceCMYK,
        I: :Indexed,
      }.freeze

      attr_reader :header, :data

      def initialize(header: {}, data: "")
        @header = header.dup.freeze
        @data = (data || "".b).dup.freeze
      end

      def width; header[:Width]; end
      def height; header[:Height]; end
      def bits_per_component; header[:BitsPerComponent]; end

      def image_mask?
        [true, 1].include?(header[:ImageMask])
      end

      def decode; header[:Decode]; end
      def interpolate?; header[:Interpolate] == true; end

      # /ColorSpace with the inline abbreviation expanded
      # (/G -> /DeviceGray etc.).
      def color_space
        cs = header[:ColorSpace]
        return nil unless cs.is_a?(::Symbol)

        COLOR_SPACE_ABBREVIATIONS.fetch(cs, cs)
      end

      # Decoded filter chain as an array of Symbols; nil when the
      # image data is stored raw.
      def filters
        f = header[:Filter]
        return [] if f.nil?

        arr = f.is_a?(::Array) ? f : [f]
        arr.map { |name| FILTER_ABBREVIATIONS.fetch(name.to_sym, name.to_sym) }
      end

      # Apply the filter chain to the raw payload. Returns the raw
      # data when no filter is declared.
      def decoded_data
        list = filters
        return @data if list.empty?

        Pdfrb::Filter.apply(
          @data, filters: list, parms: Array(header[:DecodeParms]),
                 direction: :decode
        )
      end

      # Number of colour components implied by /ColorSpace.
      def components
        case color_space
        when :DeviceGray, :Indexed then 1
        when :DeviceRGB then 3
        when :DeviceCMYK then 4
        end
      end

      # Expected decoded byte count: rows * width * components *
      # bits, packed per row.
      def expected_decoded_size
        return nil if width.nil? || height.nil? || bits_per_component.nil?
        return nil if image_mask?

        comps = components
        return nil if comps.nil?

        bits = width * comps * bits_per_component
        bytes_per_row = (bits + 7) / 8
        bytes_per_row * height
      end
    end
  end
end
