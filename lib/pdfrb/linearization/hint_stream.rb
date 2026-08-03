# frozen_string_literal: true

require "stringio"
require "zlib"

module Pdfrb
  module Linearization
    # Builds the page-offset hint stream (ISO 32000-2 Annex F).
    # The hint stream tells the viewer where each page's objects are
    # located without needing to parse the full xref.
    #
    # This implementation produces a minimal valid hint table:
    #   /S 16 (16 bits per entry field)
    #   One page-offset entry per page.
    class HintStream
      DEFAULT_ITEM_BITS = 16

      attr_reader :page_entries, :item_bits

      def initialize(item_bits: DEFAULT_ITEM_BITS)
        @item_bits = item_bits
        @page_entries = []
      end

      # Add a page entry.
      # @param offset_delta [Integer] offset relative to /O reference.
      # @param page_length [Integer] length in bytes.
      # @param num_objects [Integer] number of objects on this page.
      # @param page_obj_num [Integer] object number of the Page dict.
      def add_page(offset_delta:, page_length:, num_objects:, page_obj_num:)
        @page_entries << {
          offset_delta: offset_delta,
          page_length: page_length,
          num_objects: num_objects,
          page_obj_num: page_obj_num,
        }
      end

      # Encode the hint stream as PDF bytes (binary, ready for /Length).
      # @return [String] binary hint table data.
      def encode
        bits = []

        @page_entries.each do |entry|
          bits << [entry[:offset_delta], @item_bits]
          bits << [entry[:page_length], @item_bits]
          bits << [entry[:num_objects], @item_bits]
          bits << [entry[:page_obj_num], @item_bits]
        end

        packed = pack_bits(bits)
        packed.force_encoding(Encoding::BINARY)
      end

      # Dictionary fields for the hint stream object.
      def dictionary_fields(length)
        {
          S: @item_bits,
        }.tap do |h|
          h[:Length] = length
        end
      end

      private

      def pack_bits(bit_fields)
        bytes = +""
        buffer = 0
        bits_in_buffer = 0

        bit_fields.each do |value, width|
          width.times do |i|
            bit = (value >> (width - 1 - i)) & 1
            buffer = (buffer << 1) | bit
            bits_in_buffer += 1
            if bits_in_buffer == 8
              bytes << [buffer].pack("C")
              buffer = 0
              bits_in_buffer = 0
            end
          end
        end

        if bits_in_buffer.positive?
          buffer <<= (8 - bits_in_buffer)
          bytes << [buffer].pack("C")
        end

        bytes
      end
    end
  end
end
