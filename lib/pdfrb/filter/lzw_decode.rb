# frozen_string_literal: true

module Pdfrb
  module Filter
    # LZWDecode (s7.4.4). LZW decompression with optional DeLZW
    # predictor handling (same PNG predictor as FlateDecode).
    class LZWDecode
      include Base

      register_as "LZWDecode"

      CLEAR_TABLE = 256
      EOD_MARKER  = 257
      INITIAL_DICT_SIZE = 258

      class << self
        def decoder(bytes, parms, _document)
          decoded = decompress(bytes)
          apply_predictor(decoded, parms)
        end

        def encoder(_bytes, _parms, _document)
          raise Pdfrb::FilterError.new(
            "LZWDecode encoder not implemented",
            filter_name: "LZWDecode"
          )
        end

        private

        def decompress(bytes)
          out = +""
          table = build_initial_table
          next_code = INITIAL_DICT_SIZE
          bit_width = 9
          early_change = 1 # default per spec
          bit_iter = BitReader.new(bytes)
          prev = nil

          while (code = bit_iter.read_bits(bit_width))
            break if code == EOD_MARKER

            if code == CLEAR_TABLE
              table = build_initial_table
              next_code = INITIAL_DICT_SIZE
              bit_width = 9
              prev = nil
              next
            end

            entry =
              if code < table.length
                table[code]
              elsif code == table.length && prev
                prev + prev.byteslice(0, 1)
              else
                raise Pdfrb::FilterError.new(
                  "LZWDecode bad code #{code}",
                  filter_name: "LZWDecode"
                )
              end
            out << entry
            if prev && next_code < 4096
              table << prev + entry.byteslice(0, 1)
              next_code += 1
              bit_width = compute_bit_width(next_code, early_change) if next_code > (1 << bit_width) - 1 - early_change + 1
            end
            prev = entry
          end
          out.force_encoding(Encoding::BINARY)
        end

        def build_initial_table
          (0..255).map(&:chr).map { |s| s.force_encoding(Encoding::BINARY) }
        end

        def compute_bit_width(next_code, early_change)
          w = 9
          w += 1 while next_code > (1 << w) - 1 - early_change
          w.clamp(9, 12)
        end

        def apply_predictor(bytes, parms)
          return bytes unless parms && parms.is_a?(::Hash)

          predictor = parms[:Predictor] || 1
          return bytes if predictor == 1

          Pdfrb::Filter::PNGPredictor.decode(
            bytes,
            predictor: predictor,
            columns: parms[:Columns] || 1,
            colors: parms[:Colors] || 1,
            bits_per_component: parms[:BitsPerComponent] || 8
          )
        end
      end

      # Pull-based bit reader for LZW bit-streams.
      class BitReader
        def initialize(bytes)
          @bytes = bytes.bytes
          @bit_pos = 0
        end

        def read_bits(width)
          result = 0
          bits_read = 0
          while bits_read < width
            byte_index = @bit_pos / 8
            return nil if byte_index >= @bytes.length

            bit_in_byte = 7 - (@bit_pos % 8)
            bit = (@bytes[byte_index] >> bit_in_byte) & 1
            result = (result << 1) | bit
            @bit_pos += 1
            bits_read += 1
          end
          result
        end
      end
      private_constant :BitReader
    end
  end
end
