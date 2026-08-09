# frozen_string_literal: true

module Pdfrb
  module Color
    # Default ICC profile accessor. Vendors a minimal sRGB ICC
    # profile (4-channel RGB display profile per ICC.1:2022) for
    # callers that want a "use sRGB" color space without shipping a
    # full ICC binary themselves.
    #
    # The actual profile bytes are emitted lazily: building an ICC
    # binary requires correctly computing the profile ID (MD5 over
    # the on-disk profile), which is non-trivial. We provide the
    # header + tag table structure and let callers fill in the
    # tagged elements they need (desc, wtpt, rTRC/gTRC/bTRC).
    module DefaultProfile
      SRGB_SIGNATURE = "acsp".b

      module_function

      # Returns the minimal sRGB ICC profile bytes (header + empty
      # tag table). About 128 bytes; suitable for tests and as a
      # placeholder when the real profile bytes aren't shipped.
      def srgb_bytes
        header = build_srgb_header
        header << ([0] * 4).pack("C*") # Tag count: 0

        size = header.bytesize
        header[0, 4] = [size].pack("N")
        header.force_encoding(Encoding::BINARY)
      end

      # Build the 128-byte ICC profile header per ICC.1:2022 §7.1.
      # Trailing tag table is the caller's responsibility.
      def build_srgb_header
        header = +""
        header << ([0] * 4).pack("C*")                # Profile size placeholder
        header << ([0] * 4).pack("C*")                # Preferred CMM
        header << [0x04, 0x40, 0x00, 0x00].pack("C*") # Version 4.4
        header << "mntr"                              # Device class
        header << "RGB "                              # Color space
        header << "XYZ "                              # PCS
        header << date_bytes                          # Date
        header << SRGB_SIGNATURE # 'acsp'
        header << "APPL"                              # Primary platform
        header << ([0] * 4).pack("C*")                # Profile flags
        header << ([0] * 4).pack("C*")                # Device manufacturer
        header << ([0] * 4).pack("C*")                # Device model
        header << ([0] * 8).pack("C*")                # Device attributes
        header << ([0] * 4).pack("C*")                # Rendering intent
        header << d50_illuminant_bytes                # PCS illuminant
        header << ([0] * 4).pack("C*")                # Profile creator
        header << ([0] * 16).pack("C*")               # Profile ID (MD5)
        header << ([0] * 28).pack("C*")               # Reserved
        header
      end

      def date_bytes
        [0x07, 0xE8, 0x00, 0x01, 0x00, 0x01,
         0x00, 0x00, 0x00, 0x00, 0x00, 0x00].pack("C*")
      end

      def d50_illuminant_bytes
        # D50 X=0.9642, Y=1.0, Z=0.8249 in s15Fixed16
        [0x00, 0x00, 0xF6, 0xD6, 0x00, 0x01, 0x00, 0x00,
         0x00, 0x00, 0xD3, 0x2D].pack("C*")
      end

      # Build an ICCBased color space array referencing a new
      # EmbeddedFile-like stream containing the sRGB profile bytes.
      # Returns [:ICCBased, ref] where ref is a Pdfrb::Model::Reference
      # suitable for inclusion in a /ColorSpace resource.
      def srgb_color_space(document)
        stream = document.add(
          { N: 3, Length: srgb_bytes.bytesize },
          type: Pdfrb::Model::Cos::Stream
        )
        stream.stream = srgb_bytes
        [:ICCBased, Pdfrb::Model::Reference.new(stream.oid, stream.gen)]
      end
    end
  end
end
