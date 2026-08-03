# frozen_string_literal: true

module Pdfrb
  module Color
    # ICC profile stream model. An ICCBased color space is a
    # [/ICCBased <stream-ref>] array where the stream carries the
    # raw ICC profile bytes and the dictionary declares /N (number
    # of components), /Alternate (fallback space), and /Range.
    #
    # This class parses the ICC header to extract metadata (version,
    # device class, color space, component count) and builds the
    # PDF stream dictionary.
    #
    # ICC spec: ISO 15076-1 / ICC.1:2010. PDF integration: ISO 32000-2 §8.6.5.5.
    class ICCProfile
      HEADER_SIZE = 128
      SIGNATURE_OFFSET = 36

      attr_reader :raw_data, :version, :device_class, :color_space,
                  :component_count, :alternate

      def initialize(raw_data, alternate: nil)
        @raw_data = raw_data.b
        parse_header
        @alternate = alternate || derive_alternate
      end

      def self.read(path)
        new(File.binread(path))
      end

      def pdf_color_space_array
        [:ICCBased, :__icc_stream_ref__]
      end

      def stream_dictionary_fields
        {
          N: @component_count,
          Alternate: @alternate,
        }.freeze
      end

      def valid?
        @raw_data.bytesize >= HEADER_SIZE && signature_valid?
      end

      private

      def parse_header
        return unless @raw_data.bytesize >= HEADER_SIZE

        major = @raw_data.getbyte(8)
        minor_bugfix = @raw_data.getbyte(9)
        @version = format("%d.%d.%d", major, (minor_bugfix >> 4) & 0x0F, minor_bugfix & 0x0F)
        @device_class = read_str(12, 4)
        @color_space = read_str(16, 4)
        @component_count = component_count_for(@color_space)
      end

      def signature_valid?
        read_str(SIGNATURE_OFFSET, 4) == "acsp"
      end

      def derive_alternate
        case @color_space
        when "CMYK" then :DeviceCMYK
        when "GRAY" then :DeviceGray
        when "LAB " then :Lab
        else :DeviceRGB # RGB and unknown fall back to DeviceRGB
        end
      end

      def component_count_for(cs)
        case cs
        when "CMYK" then 4
        when "GRAY" then 1
        else 3 # RGB, LAB, and unknown all use 3 components
        end
      end

      def read_u32(offset)
        @raw_data.byteslice(offset, 4)&.unpack1("N")
      end

      def read_str(offset, len)
        @raw_data.byteslice(offset, len)&.force_encoding(Encoding::US_ASCII) || ""
      end
    end
  end
end
