# frozen_string_literal: true

require "zlib"

module Pdfrb
  module ImageLoader
    # TIFF image loader. Pure-Ruby support for:
    #
    #   * Format detection via the II/MM byte-order magic.
    #   * Header + IFD parsing to extract width, height, bpc, sample
    #     count, photometric interpretation, compression, strip
    #     offsets + byte counts.
    #   * Single-strip, uncompressed (compression == 1) RGB or
    #     grayscale pixel decode into raw image bytes suitable for
    #     embedding as a /FlateDecode image XObject.
    #
    # For multi-strip, tiled, YCbCr, or compressed TIFFs (LZW, PackBits,
    # CCITT, JPEG-in-TIFF), the loader emits a metadata-only stub
    # XObject. Callers should pre-convert those to PNG/JPEG.
    module TIFF
      COMPRESSION_NONE = 1
      COMPRESSION_CCITT_RLE = 2
      COMPRESSION_CCITT_FAX3 = 3
      COMPRESSION_CCITT_FAX4 = 4
      COMPRESSION_LZW = 5
      COMPRESSION_OJPEG = 6
      COMPRESSION_JPEG = 7
      COMPRESSION_DEFLATE = 8
      COMPRESSION_PACKBITS = 32773

      module_function

      def call(document, data, **_opts)
        data = data.read if data.is_a?(IO) || data.is_a?(StringIO)
        info = parse_header(data)
        return nil if info.empty?

        pixels = decode_pixels(data, info)
        if pixels
          build_compressed_image(document, info, pixels)
        else
          build_stub_image(document, info)
        end
      end

      # Parse the TIFF header (8 bytes) + first IFD. Returns a Hash
      # with width, height, bits_per_sample, samples_per_pixel,
      # photometric, compression, strip_offsets, strip_byte_counts,
      # rows_per_strip, color_space, or empty Hash if not TIFF.
      def parse_header(data)
        return {} unless data.is_a?(::String) && data.bytesize >= 8

        byte_order = data.byteslice(0, 2)
        case byte_order
        when "II" then little_endian = true
        when "MM" then little_endian = false
        else return {}
        end

        magic = read_u16(data, 2, little_endian)
        return {} unless [42, 43].include?(magic)
        return {} unless magic == 42

        ifd_offset = read_u32(data, 4, little_endian)
        parse_ifd(data, ifd_offset, little_endian)
      end

      def parse_ifd(data, offset, little_endian)
        return {} if offset.nil? || offset + 2 > data.bytesize

        count = read_u16(data, offset, little_endian)
        entries = {}
        count.times do |i|
          entry_off = offset + 2 + (i * 12)
          break if entry_off + 12 > data.bytesize

          tag = read_u16(data, entry_off, little_endian)
          type_id = read_u16(data, entry_off + 2, little_endian)
          count_val = read_u32(data, entry_off + 4, little_endian)
          value = read_ifd_value(data, entry_off + 8, type_id, count_val, little_endian)
          entries[tag] = { type: type_id, count: count_val, value: value }
        end

        interpret_ifd(entries)
      end

      # Decode pixel data when the TIFF is single-strip uncompressed
      # RGB or grayscale. Returns binary pixel bytes or nil if the
      # compression/photometric combo isn't supported here.
      def decode_pixels(data, info)
        return nil unless info[:compression] == COMPRESSION_NONE
        return nil unless info[:strip_offsets] && info[:strip_byte_counts]

        # Only handle 8-bit single-sample (gray) or 3-sample (RGB)
        # in photometric 0/1/2.
        return nil unless info[:bits_per_sample] == 8
        return nil unless [1, 3].include?(info[:samples_per_pixel])
        return nil unless [0, 1, 2].include?(info[:photometric])

        bytes = read_strips(data, info)
        return nil unless bytes

        # TIFF rows are padded to word boundaries; PDF image XObjects
        # don't need this padding. Strip per row.
        channels = info[:samples_per_pixel]
        row_bytes = info[:width] * channels
        return nil if row_bytes.zero?

        rows = info[:height]
        out = +"".b
        rows.times do |r|
          offset = r * row_bytes
          out << bytes.byteslice(offset, row_bytes)
        end
        out
      end

      # Read all strips concatenated. Single-strip case is most common
      # for small images; multi-strip is supported when present.
      def read_strips(data, info)
        offsets = Array(info[:strip_offsets])
        counts = Array(info[:strip_byte_counts])
        return nil if offsets.length != counts.length

        bytes = +"".b
        offsets.each_with_index do |off, i|
          n = counts[i]
          piece = data.byteslice(off, n)
          return nil unless piece && piece.bytesize == n

          bytes << piece
        end
        bytes
      end

      def build_compressed_image(document, info, pixels)
        compressed = Zlib.deflate(pixels)
        image = document.add(
          {
            Type: :XObject, Subtype: :Image,
            Width: info[:width], Height: info[:height],
            BitsPerComponent: 8,
            ColorSpace: info[:color_space],
            Filter: :FlateDecode,
            Length: compressed.bytesize
          },
          type: Pdfrb::Model::Type::XObjectImage
        )
        image.stream = compressed
        image
      end

      def build_stub_image(document, info)
        image = document.add(
          {
            Type: :XObject, Subtype: :Image,
            Width: info[:width], Height: info[:height],
            BitsPerComponent: info[:bits_per_sample] || 8,
            ColorSpace: info[:color_space] || :DeviceRGB,
            Length: 0
          },
          type: Pdfrb::Model::Type::XObjectImage
        )
        image.stream = +""
        image
      end

      def read_ifd_value(data, offset, type_id, count, little_endian)
        # For multi-value entries (count > 1 for SHORT/LONG), the
        # value field is a pointer to the actual data. For count <= 1
        # the value lives inline in the 4-byte value field.
        case type_id
        when 3 # SHORT
          count <= 1 ? read_u16(data, offset, little_endian) : read_short_array(data, offset, count, little_endian)
        when 4 # LONG
          count <= 1 ? read_u32(data, offset, little_endian) : read_long_array(data, offset, count, little_endian)
        else
          count <= 1 ? read_u16(data, offset, little_endian) : read_u32(data, offset, little_endian)
        end
      end

      def read_short_array(data, value_field_offset, count, little_endian)
        # If count * 2 <= 4, values live in the value field; otherwise
        # the field holds a pointer.
        if count * 2 <= 4
          (0...count).map { |i| read_u16(data, value_field_offset + (i * 2), little_endian) }
        else
          ptr = read_u32(data, value_field_offset, little_endian)
          (0...count).map { |i| read_u16(data, ptr + (i * 2), little_endian) }
        end
      end

      def read_long_array(data, value_field_offset, count, little_endian)
        if count * 4 <= 4
          (0...count).map { |i| read_u32(data, value_field_offset + (i * 4), little_endian) }
        else
          ptr = read_u32(data, value_field_offset, little_endian)
          (0...count).map { |i| read_u32(data, ptr + (i * 4), little_endian) }
        end
      end

      def read_u16(data, offset, little_endian)
        bytes = data.bytes[offset, 2]
        return 0 unless bytes && bytes.length == 2

        little_endian ? ((bytes[1] << 8) | bytes[0]) : ((bytes[0] << 8) | bytes[1])
      end

      def read_u32(data, offset, little_endian)
        bytes = data.bytes[offset, 4]
        return 0 unless bytes && bytes.length == 4

        if little_endian
          (bytes[3] << 24) | (bytes[2] << 16) | (bytes[1] << 8) | bytes[0]
        else
          (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3]
        end
      end

      def interpret_ifd(entries)
        width = entries[256]&.[](:value)
        height = entries[257]&.[](:value)
        bps = entries[258]&.[](:value) || 8
        bps = bps.first if bps.is_a?(::Array)
        spp = entries[277]&.[](:value) || 1
        spp = spp.first if spp.is_a?(::Array)
        photometric = entries[262]&.[](:value) || 1
        compression = entries[259]&.[](:value) || COMPRESSION_NONE
        strip_offsets = entries[273]&.[](:value)
        strip_byte_counts = entries[279]&.[](:value)
        rows_per_strip = entries[278]&.[](:value) || height
        {
          width: width,
          height: height,
          bits_per_sample: bps,
          samples_per_pixel: spp,
          photometric: photometric,
          compression: compression,
          strip_offsets: strip_offsets,
          strip_byte_counts: strip_byte_counts,
          rows_per_strip: rows_per_strip,
          color_space: color_space_for_photometric(photometric),
        }
      end

      def color_space_for_photometric(photometric)
        case photometric
        when 0, 1 then :DeviceGray
        when 5 then :DeviceCMYK
        # Default covers RGB (2), unknown photometric interpretations,
        # and nil photometric (which we treat as RGB by convention).
        else :DeviceRGB
        end
      end
    end
  end
end
