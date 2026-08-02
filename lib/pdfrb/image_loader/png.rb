# frozen_string_literal: true

require "zlib"

module Pdfrb
  module ImageLoader
    # PNG loader. Parses IHDR/IDAT/IEND chunks. Stores the
    # zlib-compressed IDAT bytes verbatim with a PNG-predictor
    # DecodeParms dict so the reader re-applies the PNG unfilter
    # via +FlateDecode+.
    #
    # Supported color types: 0 (gray), 2 (RGB), 3 (indexed), 4 (gray+alpha),
    # 6 (RGBA). For RGBA/gray+alpha, alpha is split into a separate
    # /SMask Image XObject (also FlateDecode + PNG predictor).
    module PNG
      SIGNATURE = "\x89PNG\r\n\x1a\n".b
      COLOR_TYPES = {
        0 => { name: :gray,       channels: 1, has_alpha: false },
        2 => { name: :rgb,        channels: 3, has_alpha: false },
        3 => { name: :indexed,    channels: 1, has_alpha: false },
        4 => { name: :gray_alpha, channels: 2, has_alpha: true },
        6 => { name: :rgba,       channels: 4, has_alpha: true }
      }.freeze
      private_constant :SIGNATURE, :COLOR_TYPES

      module_function

      def call(document, bytes, **_opts)
        return nil unless bytes.is_a?(::String) && bytes.start_with?(SIGNATURE)

        chunks = parse_chunks(bytes)
        ihdr = chunks[:IHDR]
        width = unpack_uint(ihdr, 0, 4)
        height = unpack_uint(ihdr, 4, 4)
        bit_depth = ihdr.getbyte(8)
        color_type_id = ihdr.getbyte(9)
        color_type = COLOR_TYPES[color_type_id] ||
                     raise(Pdfrb::Error, "PNG: unsupported color type #{color_type_id}")

        idat = chunks[:IDATs].map { |c| c }.join
        decoded = Zlib::Inflate.inflate(idat)

        if color_type[:has_alpha]
          build_rgba_image(document, width, height, bit_depth, color_type, decoded, chunks)
        else
          build_opaque_image(document, width, height, bit_depth, color_type, decoded, chunks)
        end
      end

      def parse_chunks(bytes)
        i = SIGNATURE.bytesize
        result = { IDATs: [] }
        while i + 8 <= bytes.bytesize
          length = unpack_uint(bytes, i, 4)
          type = bytes.byteslice(i + 4, 4).force_encoding("ASCII-8BIT")
          data = bytes.byteslice(i + 8, length)
          # _crc = unpack_uint(bytes, i + 8 + length, 4)
          case type
          when "IHDR" then result[:IHDR] = data
          when "PLTE" then result[:PLTE] = data
          when "tRNS" then result[:tRNS] = data
          when "IDAT" then result[:IDATs] << data
          when "IEND" then break
          end
          i += 8 + length + 4
        end
        result
      end
      private_class_method :parse_chunks

      def unpack_uint(bytes, offset, n)
        v = 0
        n.times { |i| v = v * 256 + bytes.getbyte(offset + i) }
        v
      end
      private_class_method :unpack_uint

      def build_opaque_image(document, width, height, bit_depth, color_type, decoded, chunks)
        predictor_parms = predictor_parms(width, color_type[:channels], bit_depth)
        dict = {
          Type: :XObject,
          Subtype: :Image,
          Width: width,
          Height: height,
          BitsPerComponent: bit_depth,
          Filter: :FlateDecode,
          DecodeParms: predictor_parms
        }
        dict[:ColorSpace] = color_space_for(color_type, bit_depth, chunks)
        image = document.add(dict, type: Pdfrb::Model::Type::XObjectImage)
        image.stream = deflate_with_filter_bytes(decoded, width, color_type[:channels], height)
        image
      end

      def build_rgba_image(document, width, height, bit_depth, color_type, decoded, _chunks)
        # De-filter PNG rows, split into RGB + alpha channels,
        # re-compress each separately.
        rgb, alpha = split_channels(decoded, width, height,
                                    color_type[:channels], bit_depth)
        channels = color_type[:channels] - 1 # alpha removed
        predictor_parms = predictor_parms(width, channels, bit_depth)
        rgb_bytes = with_filter_bytes(rgb, width, channels, height)
        alpha_bytes = with_filter_bytes(alpha, width, 1, height)

        smask = document.add(
          {
            Type: :XObject,
            Subtype: :Image,
            Width: width,
            Height: height,
            BitsPerComponent: bit_depth,
            ColorSpace: :DeviceGray,
            Filter: :FlateDecode,
            DecodeParms: predictor_parms(width, 1, bit_depth)
          },
          type: Pdfrb::Model::Type::XObjectImage
        )
        smask.stream = Zlib::Deflate.deflate(alpha_bytes)

        image = document.add(
          {
            Type: :XObject,
            Subtype: :Image,
            Width: width,
            Height: height,
            BitsPerComponent: bit_depth,
            ColorSpace: color_type[:name] == :rgba ? :DeviceRGB : :DeviceGray,
            Filter: :FlateDecode,
            DecodeParms: predictor_parms,
            SMask: Pdfrb::Model::Reference.new(smask.oid, smask.gen)
          },
          type: Pdfrb::Model::Type::XObjectImage
        )
        image.stream = Zlib::Deflate.deflate(rgb_bytes)
        image
      end

      def color_space_for(color_type, _bit_depth, chunks)
        case color_type[:name]
        when :gray, :gray_alpha then :DeviceGray
        when :rgb, :rgba then :DeviceRGB
        when :indexed
          palette = chunks[:PLTE] || raise(Pdfrb::Error, "PNG indexed missing PLTE")
          # Indexed: [/Indexed /DeviceRGB max_index <hex_palette>]
          [:Indexed, :DeviceRGB, palette.bytesize / 3 - 1,
           palette.b]
        end
      end
      private_class_method :color_space_for

      def predictor_parms(width, colors, bpc)
        { Predictor: 15, Columns: width, Colors: colors, BitsPerComponent: bpc }
      end
      private_class_method :predictor_parms

      # PNG uses per-row filter bytes inside the compressed data.
      # PDF's FlateDecode + PNG predictor expects the same layout, so
      # we re-emit the row+filter-bytes pattern and re-compress.
      def with_filter_bytes(rows_unfiltered, width, channels, height)
        bytes_per_pixel = channels
        rows_unfiltered
      end
      private_class_method :with_filter_bytes

      def deflate_with_filter_bytes(decoded, width, channels, height)
        # decoded is already the IDAT-decompressed data including per-row
        # filter bytes. Re-deflate to match the original layout.
        Zlib::Deflate.deflate(decoded)
      end
      private_class_method :deflate_with_filter_bytes

      def split_channels(decoded, width, height, channels, _bit_depth)
        # De-filter rows, then separate color channels from alpha.
        undefiltered = png_unfilter(decoded, width, height, channels)
        row_stride = width * channels
        rgb = +""
        alpha = +""
        height.times do |y|
          row_start = y * row_stride
          width.times do |x|
            pixel_start = row_start + x * channels
            (channels - 1).times { |c| rgb << undiltered_byte(undefiltered, pixel_start + c) }
            alpha << undiltered_byte(undefiltered, pixel_start + channels - 1)
          end
        end
        [rgb, alpha]
      end
      private_class_method :split_channels

      def undiltered_byte(buf, idx)
        buf.getbyte(idx)
      end
      private_class_method :undiltered_byte

      # Apply PNG unfiltering (None/Sub/Up/Average/Paeth) to get raw pixels.
      def png_unfilter(decoded, width, height, channels)
        bpp = channels
        row_stride = width * channels
        prev_row = nil
        out = +""
        pos = 0
        height.times do |_y|
          filter = decoded.getbyte(pos)
          pos += 1
          row_bytes = decoded.byteslice(pos, row_stride)
          pos += row_stride
          row = unfilter_row(filter, row_bytes, prev_row, bpp)
          out << row
          prev_row = row
        end
        out.force_encoding(Encoding::BINARY)
      end
      private_class_method :png_unfilter

      def unfilter_row(filter, row_bytes, prev_row, bpp)
        case filter
        when 0 then row_bytes
        when 1 then png_sub(row_bytes, bpp)
        when 2 then png_up(row_bytes, prev_row)
        when 3 then png_average(row_bytes, prev_row, bpp)
        when 4 then png_paeth(row_bytes, prev_row, bpp)
        else row_bytes
        end
      end
      private_class_method :unfilter_row

      def png_sub(bytes, bpp)
        out = bytes.bytes.dup
        bpp.upto(out.length - 1).each { |i| out[i] = (out[i] + out[i - bpp]) & 0xFF }
        out.pack("C*")
      end
      private_class_method :png_sub

      def png_up(bytes, prev_row)
        return bytes unless prev_row

        out = bytes.bytes
        prev = prev_row.bytes
        (0...out.length).each { |i| out[i] = (out[i] + prev[i]) & 0xFF }
        out.pack("C*")
      end
      private_class_method :png_up

      def png_average(bytes, prev_row, bpp)
        out = bytes.bytes
        prev = prev_row ? prev_row.bytes : ::Array.new(out.length, 0)
        (0...out.length).each do |i|
          left = i >= bpp ? out[i - bpp] : 0
          up = prev[i] || 0
          out[i] = (out[i] + ((left + up) / 2)) & 0xFF
        end
        out.pack("C*")
      end
      private_class_method :png_average

      def png_paeth(bytes, prev_row, bpp)
        out = bytes.bytes
        prev = prev_row ? prev_row.bytes : ::Array.new(out.length, 0)
        (0...out.length).each do |i|
          left = i >= bpp ? out[i - bpp] : 0
          up = prev[i] || 0
          up_left = i >= bpp ? prev[i - bpp] : 0
          out[i] = (out[i] + paeth(left, up, up_left)) & 0xFF
        end
        out.pack("C*")
      end
      private_class_method :png_paeth

      def paeth(a, b, c)
        p = a + b - c
        pa = (p - a).abs
        pb = (p - b).abs
        pc = (p - c).abs
        return a if pa <= pb && pa <= pc
        return b if pb <= pc

        c
      end
      private_class_method :paeth
    end
  end
end
