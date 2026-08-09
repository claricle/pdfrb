# frozen_string_literal: true

require "zlib"

module Pdfrb
  module ImageLoader
    # GIF image loader with full GIF-spec LZW decode. Supports:
    #
    #   * Format detection via the "GIF8" magic.
    #   * Logical screen descriptor + global color table parse.
    #   * Image descriptor (per-frame) for the first image frame.
    #   * GIF-LZW decompression (variable-width codes, dictionary
    #     rebuild on clear code, dict-reset semantics).
    #
    # Output: an Indexed PDF image XObject whose /ColorSpace is
    # [/Indexed /DeviceRGB <palette bytes>] and whose stream is the
    # decoded palette-index bytes (one byte per pixel), suitable for
    # /FlateDecode re-compression.
    module GIF
      module_function

      def call(document, data, **_opts)
        data = data.read if data.is_a?(IO) || data.is_a?(StringIO)
        info = parse_header(data)
        return nil if info.empty?

        palette = read_global_color_table(data, info)
        return nil unless palette

        frame = parse_first_image_descriptor(data, info)
        return nil unless frame

        lzw_min = data.getbyte(frame[:lzw_min_code_offset])
        compressed_start = frame[:lzw_min_code_offset] + 1
        compressed = extract_subblocks(data, compressed_start)
        return nil unless compressed

        indices = lzw_decode(compressed, lzw_min)
        return nil unless indices

        rgb_palette = palette.pack("C*")
        cs = [:Indexed, :DeviceRGB, (palette.length / 3) - 1, rgb_palette]
        compressed_indices = Zlib.deflate(indices)

        image = document.add(
          {
            Type: :XObject, Subtype: :Image,
            Width: frame[:width], Height: frame[:height],
            BitsPerComponent: 8,
            ColorSpace: cs,
            Filter: :FlateDecode,
            Length: compressed_indices.bytesize
          },
          type: Pdfrb::Model::Type::XObjectImage
        )
        image.stream = compressed_indices
        image
      end

      def parse_header(data)
        return {} unless data.is_a?(::String) && data.bytesize >= 13
        return {} unless data.start_with?("GIF87a", "GIF89a")

        width = (data.getbyte(7) << 8) | data.getbyte(6)
        height = (data.getbyte(9) << 8) | data.getbyte(8)
        packed = data.getbyte(10)
        global_ct_flag = packed.anybits?(0x80)
        global_ct_size = global_ct_flag ? (2**((packed & 0x07) + 1)) : 0
        bg_color = data.getbyte(11)
        aspect_ratio = data.getbyte(12)
        {
          width: width,
          height: height,
          global_ct_flag: global_ct_flag,
          global_ct_size: global_ct_size,
          bg_color: bg_color,
          aspect_ratio: aspect_ratio,
          global_ct_offset: 13,
        }
      end

      def read_global_color_table(data, info)
        return nil unless info[:global_ct_flag]

        n = info[:global_ct_size]
        offset = info[:global_ct_offset]
        return nil unless offset + (n * 3) <= data.bytesize

        (0...(n * 3)).map { |i| data.getbyte(offset + i) }
      end

      # Walk the GIF looking for the first image descriptor (0x2C).
      # Returns a Hash with image descriptor fields + the LZW min
      # code size offset within the data.
      def parse_first_image_descriptor(data, info)
        offset = info[:global_ct_offset] + (info[:global_ct_size] * 3)
        while offset < data.bytesize
          marker = data.getbyte(offset)
          case marker
          when 0x2C
            return parse_image_descriptor(data, offset + 1)
          when 0x21
            offset += 2
            while offset < data.bytesize
              block_size = data.getbyte(offset)
              offset += 1
              break if block_size.zero?

              offset += block_size
            end
          when 0x3B
            return nil
          else
            offset += 1
          end
        end
        nil
      end

      def parse_image_descriptor(data, offset)
        return nil if offset + 9 > data.bytesize

        left = (data.getbyte(offset + 1) << 8) | data.getbyte(offset)
        top = (data.getbyte(offset + 3) << 8) | data.getbyte(offset + 2)
        width = (data.getbyte(offset + 5) << 8) | data.getbyte(offset + 4)
        height = (data.getbyte(offset + 7) << 8) | data.getbyte(offset + 6)
        packed = data.getbyte(offset + 8)
        local_ct_flag = packed.anybits?(0x80)
        local_ct_size = local_ct_flag ? (2**((packed & 0x07) + 1)) : 0
        body_offset = offset + 9 + (local_ct_size * 3)
        {
          left: left, top: top, width: width, height: height,
          local_ct_flag: local_ct_flag, local_ct_size: local_ct_size,
          lzw_min_code_offset: body_offset
        }
      end

      # Collect sub-blocks (length-prefixed) starting at +offset+
      # until a zero-length terminator. Returns concatenated bytes.
      def extract_subblocks(data, offset)
        bytes = +"".b
        while offset < data.bytesize
          block_size = data.getbyte(offset)
          offset += 1
          break if block_size.zero?

          bytes << data.byteslice(offset, block_size)
          offset += block_size
        end
        bytes
      end

      # GIF-spec LZW decode. Variable-width codes starting at
      # min_code_size + 1 bits. Clear code = 2**min, end code =
      # 2**min + 1.
      def lzw_decode(compressed, min_code_size)
        clear_code = 1 << min_code_size
        end_code = clear_code + 1
        codes = unpack_lzw_codes(compressed, min_code_size + 1, clear_code)
        return nil unless codes

        out = +"".b
        dict = init_dictionary(min_code_size)
        prev = nil
        codes.each do |code|
          if code == clear_code
            dict = init_dictionary(min_code_size)
            prev = nil
            next
          end
          break if code == end_code

          entry =
            if dict.key?(code)
              dict[code]
            elsif prev && dict.key?(prev)
              dict[prev] + first_byte(dict[prev])
            else
              return nil
            end
          out << entry
          if prev && !dict.key?(code) && dict.length < 4096
            dict[code] = dict[prev] + first_byte(entry)
          end
          prev = code
        end
        out
      end

      def first_byte(str)
        str.getbyte(0)&.chr(Encoding::BINARY) || "".b
      end

      def init_dictionary(min_code_size)
        clear_code = 1 << min_code_size
        end_code = clear_code + 1
        dict = {}
        (0...clear_code).each { |i| dict[i] = first_byte_of_code(i) }
        dict[clear_code] = ""
        dict[end_code] = ""
        dict
      end

      def first_byte_of_code(i)
        i.chr(Encoding::BINARY)
      end

      # Unpack variable-width codes from the LZW-compressed byte
      # stream. GIF codes are packed LSB-first. Width starts at
      # initial_width and grows by 1 when the next-code threshold
      # reaches 2**width. Width caps at 12 bits.
      def unpack_lzw_codes(bytes, initial_width, clear_code)
        codes = []
        bit_buffer = 0
        bits_in_buffer = 0
        width = initial_width
        min_code_size = initial_width - 1
        next_code = (1 << min_code_size) + 2 # next free dict slot
        byte_index = 0

        while byte_index < bytes.bytesize
          bit_buffer |= (bytes.getbyte(byte_index) << bits_in_buffer)
          bits_in_buffer += 8
          byte_index += 1

          while bits_in_buffer >= width
            code = bit_buffer & ((1 << width) - 1)
            bit_buffer >>= width
            bits_in_buffer -= width
            codes << code
            if code == clear_code
              width = initial_width
              next_code = (1 << min_code_size) + 2
            else
              next_code += 1
              if width < 12 && next_code > (1 << width)
                width += 1
              end
            end
          end
        end
        codes
      end
    end
  end
end
