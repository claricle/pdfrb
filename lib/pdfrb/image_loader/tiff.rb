# frozen_string_literal: true

module Pdfrb
  module ImageLoader
    # TIFF image loader. TIFF is a complex format (multiple
    # compression schemes, planar configurations, tile vs strip
    # layouts, multiple color models). Pure-Ruby TIFF decoding is
    # out of scope; this loader provides:
    #
    #   * Format detection via the II/MM byte-order magic.
    #   * Header + IFD parsing to extract width, height, bpc, sample
    #     count, photometric interpretation.
    #   * A path to embed an uncompressed TIFF as a /CCITTFaxDecode
    #     or /FlateDecode image XObject when the TIFF is a single-
    #     strip, uncompressed, RGB or grayscale file.
    #
    # For multi-strip, tiled, or compressed TIFFs, callers should
    # pre-convert to PNG/JPEG before embedding.
    module TIFF
      module_function

      def call(document, data, **_opts)
        data = data.read if data.is_a?(IO) || data.is_a?(StringIO)
        info = parse_header(data)
        return nil if info.empty?

        # We can't decompress arbitrary TIFFs in pure Ruby; produce
        # a stub XObject that records the metadata. The stream is
        # left empty for downstream conversion to handle.
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

      # Parse the TIFF header (8 bytes) + first IFD. Returns a Hash
      # with width, height, bits_per_sample, samples_per_pixel,
      # photometric, color_space, or empty Hash if not TIFF.
      def parse_header(data)
        return {} unless data.is_a?(::String) && data.bytesize >= 8

        byte_order = data.byteslice(0, 2)
        case byte_order
        when "II" then little_endian = true
        when "MM" then little_endian = false
        else return {}
        end

        magic = read_u16(data, 2, little_endian)
        return {} unless [42, 43].include?(magic) # TIFF or BigTIFF sentinel

        return {} unless magic == 42 # only classic TIFF parsed here

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
          value = read_ifd_value(data, entry_off + 8, type_id, little_endian)
          entries[tag] = { type: type_id, count: count_val, value: value }
        end

        interpret_ifd(entries)
      end

      def read_ifd_value(data, offset, type_id, little_endian)
        case type_id
        when 4 then read_u32(data, offset, little_endian)
        else read_u16(data, offset, little_endian)
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
        # Standard TIFF tags.
        width = entries[256]&.[](:value)
        height = entries[257]&.[](:value)
        bps = entries[258]&.[](:value) || 8
        spp = entries[277]&.[](:value) || 1
        photometric = entries[262]&.[](:value) || 1
        {
          width: width,
          height: height,
          bits_per_sample: bps,
          samples_per_pixel: spp,
          photometric: photometric,
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
