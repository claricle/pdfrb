# frozen_string_literal: true

module Pdfrb
  # Image loaders: build a +Type::XObjectImage+ (or +Type::XObjectForm+
  # for PDF) from a JPEG, PNG, or PDF source. Each loader is a module
  # under +ImageLoader::*+ with a +call(document, io, **opts)+
  # class method that returns an image object or nil if it can't
  # handle the format.
  module ImageLoader
    autoload :JPEG, "pdfrb/image_loader/jpeg"
    autoload :PNG, "pdfrb/image_loader/png"
    autoload :PDF, "pdfrb/image_loader/pdf"
    autoload :TIFF, "pdfrb/image_loader/tiff"
    autoload :GIF, "pdfrb/image_loader/gif"

    @loaders = []

    class << self
      attr_reader :loaders

      # Register a loader. Loaders are tried in registration order;
      # first non-nil return wins.
      def register(loader)
        @loaders << loader
      end

      # Build an image XObject from +io+ (IO, file path, or bytes).
      # Iterates registered loaders until one matches.
      def load(document, io, **opts)
        bytes = read_bytes(io)
        @loaders.each do |loader|
          result = loader.call(document, bytes, **opts)
          return result if result
        end
        raise Pdfrb::Error,
              "no image loader matched (unknown or unrecognised format)"
      end

      def reset!
        @loaders.clear
      end

      private

      def read_bytes(io)
        case io
        when IO, StringIO then io.read
        when ::String
          looks_like_path?(io) ? File.binread(io) : io.b
        else
          io.to_s.b
        end
      end

      def looks_like_path?(s)
        return false if s.bytesize > 4096 || s.encoding == Encoding::BINARY
        return false if s.bytes.any? { |b| b == 0 || b < 9 || (b > 13 && b < 32) }

        File.exist?(s)
      end
    end

    register JPEG
    register PNG
  end
end
