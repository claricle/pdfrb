# frozen_string_literal: true

module Pdfrb
  # Image-related utilities. Image *loaders* (JPEG/PNG/PDF) live under
  # Pdfrb::ImageLoader; this module hosts higher-level operations on
  # already-embedded image XObjects: audit (metadata extraction) and
  # downsampling (pure-Ruby nearest-neighbour for FlateDecode-encoded
  # pixel data).
  module Image
    autoload :Audit, "pdfrb/image/audit"
    autoload :Downsampler, "pdfrb/image/downsampler"
  end
end
