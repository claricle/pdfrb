# frozen_string_literal: true

require "zlib"

module Pdfrb
  module Image
    # Pure-Ruby nearest-neighbour downsampler for FlateDecode-encoded
    # image XObjects. JPEG (DCTDecode) and JPEG2000 (JPXDecode) streams
    # can't be re-encoded without native deps, so they're skipped.
    #
    # The decoder side uses Filter::FlateDecode and the existing
    # PNGPredictor for /DecodeParms row reconstruction. The encoder
    # re-deflates and writes predictor rows with filter byte 0 (None),
    # which the spec allows.
    module Downsampler
      module_function

      # Downsample +image+ by +factor+ (>=2) using nearest-neighbour.
      # Mutates the image's stream and /Width, /Height, /Length keys.
      # Returns the image if changes were made, nil otherwise.
      def downsample!(image, factor:)
        return nil unless factor && factor >= 2
        return nil unless eligible?(image)

        width = image.value[:Width]
        height = image.value[:Height]
        bpc = image.value[:BitsPerComponent] || 8
        channels = Audit.channels_for(image.value[:ColorSpace])
        bytes_per_pixel = (channels * bpc) / 8
        return nil unless bytes_per_pixel.positive?

        decoded = decode(image, width, height, bytes_per_pixel)
        return nil unless decoded

        new_w = width / factor
        new_h = height / factor
        return nil if new_w.zero? || new_h.zero?

        sampled = sample_nearest(decoded, width, new_w, new_h,
                                 bytes_per_pixel, factor)
        encoded = encode(image, sampled, new_w, new_h, bytes_per_pixel)
        return nil unless encoded

        image.stream = encoded
        image.value[:Width] = new_w
        image.value[:Height] = new_h
        image.value[:Length] = encoded.bytesize
        image
      end

      # Eligibility: FlateDecode (with or without PNG predictor),
      # 8 bpc, single-component (gray), RGB, or CMYK (not Indexed,
      # which has a palette that mustn't be re-sampled).
      def eligible?(image)
        return false unless image.is_a?(Pdfrb::Model::Cos::Stream)

        filter = image.value[:Filter]
        return false unless filter == :FlateDecode

        return false unless (image.value[:BitsPerComponent] || 8) == 8

        color_space = image.value[:ColorSpace]
        return false if color_space == :Indexed
        return false if color_space.is_a?(::Array) && color_space.first == :Indexed

        image.value[:Width] && image.value[:Height] && image.stream
      end

      # Decode the stream back to raw pixel bytes. Handles PNG
      # predictor rows when /DecodeParms is present.
      def decode(image, width, _height, bytes_per_pixel)
        inflated = Zlib::Inflate.inflate(image.stream)
        params = image.value[:DecodeParms]
        return inflated unless params

        predictor = params.is_a?(::Hash) ? params[:Predictor] : nil
        return inflated unless predictor && predictor >= 10

        columns = (params.is_a?(::Hash) ? params[:Columns] : nil) || width
        Pdfrb::Filter::PNGPredictor.decode(
          inflated,
          predictor: predictor,
          columns: columns,
          colors: (params[:Colors] if params.is_a?(::Hash)) ||
                  bytes_per_pixel,
          bits_per_component: (params[:BitsPerComponent] if params.is_a?(::Hash)) || 8
        )
      end

      # Nearest-neighbour sampling. Picks every factor-th pixel in
      # both dimensions.
      def sample_nearest(decoded, _orig_w, new_w, new_h, bytes_per_pixel, factor)
        out = +""
        new_h.times do |new_y|
          src_y = new_y * factor
          new_w.times do |new_x|
            src_x = new_x * factor
            offset = ((src_y * _orig_w) + src_x) * bytes_per_pixel
            out << decoded.byteslice(offset, bytes_per_pixel)
          end
        end
        out.force_encoding(Encoding::BINARY)
      end

      # Re-encode +pixels+ as FlateDecode, applying the same predictor
      # scheme the image originally used (or uncompressed if none).
      def encode(image, pixels, new_w, new_h, bytes_per_pixel)
        params = image.value[:DecodeParms]
        predictor = params.is_a?(::Hash) ? params[:Predictor] : nil
        if predictor && predictor >= 10
          row_len = new_w * bytes_per_pixel
          prefixed = +""
          new_h.times do |row|
            offset = row * row_len
            prefixed << "\x00".b
            prefixed << pixels.byteslice(offset, row_len)
          end
          pixels = prefixed
        end
        Zlib::Deflate.deflate(pixels)
      end
    end
  end
end
