# frozen_string_literal: true

require "digest"

module Pdfrb
  module Color
    # Default sRGB ICC profile accessor. Builds a usable sRGB v4
    # ICC profile (header + tag table + tagged elements) that real
    # PDF readers can consume for ICCBased color spaces. The profile
    # includes:
    #
    #   * desc  — profile description (sRGB by pdfrb)
    #   * wtpt  — D50 media white point
    #   * rXYZ, gXYZ, bXYZ — sRGB colorant matrix (D50-adapted)
    #   * rTRC, gTRC, bTRC — gamma 2.2 tone reproduction curves
    #
    # Tagged-element types follow ICC.1:2022 §10 (multiLocalizedUnicodeType
    # for desc, XYZType for colorants, curveType for TRCs).
    module DefaultProfile
      SRGB_SIGNATURE = "acsp".b
      ICC_VERSION_V4 = [0x04, 0x40, 0x00, 0x00].freeze

      module_function

      # Returns the sRGB ICC profile bytes (~ 600 bytes). Includes
      # the structural header + tag table + tagged elements needed
      # for a real ICCBased color space.
      def srgb_bytes
        tags = build_srgb_tags
        tag_table = build_tag_table(tags)
        header = build_srgb_header(tag_table.bytesize + tags_total_size(tags))
        profile = header + tag_table
        tags.each_value { |tag_bytes| profile << tag_bytes }
        # Compute MD5 ProfileID over the on-disk profile (sans the
        # existing ID slot, which we'll patch in). ICC.1:2022 §7.1.
        profile = patch_profile_id(profile)
        profile.force_encoding(Encoding::BINARY)
      end

      # Build an ICCBased color space array referencing a new stream
      # containing the sRGB profile bytes. Returns
      # [:ICCBased, ref] suitable for /ColorSpace resources.
      def srgb_color_space(document)
        bytes = srgb_bytes
        stream = document.add(
          { N: 3, Length: bytes.bytesize },
          type: Pdfrb::Model::Cos::Stream
        )
        stream.stream = bytes
        [:ICCBased, Pdfrb::Model::Reference.new(stream.oid, stream.gen)]
      end

      # ---- Header construction ----

      def build_srgb_header(tag_section_size)
        header = +""
        header << ([0] * 4).pack("C*")                # Profile size placeholder
        header << ([0] * 4).pack("C*")                # Preferred CMM
        header << ICC_VERSION_V4.pack("C*")           # Version 4.4
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
        header << ([0] * 4).pack("C*")                # Rendering intent (perceptual)
        header << d50_illuminant_bytes                # PCS illuminant (D50)
        header << ([0] * 4).pack("C*")                # Profile creator
        header << ([0] * 16).pack("C*")               # Profile ID (MD5, patched later)
        header << ([0] * 28).pack("C*")               # Reserved

        total_size = header.bytesize + tag_section_size
        header[0, 4] = [total_size].pack("N")
        header
      end

      def date_bytes
        [0x07, 0xE8, 0x00, 0x01, 0x00, 0x01,
         0x00, 0x00, 0x00, 0x00, 0x00, 0x00].pack("C*")
      end

      def d50_illuminant_bytes
        # D50 X=0.9642, Y=1.0, Z=0.8249 in s15Fixed16.
        [0x00, 0x00, 0xF6, 0xD6, 0x00, 0x01, 0x00, 0x00,
         0x00, 0x00, 0xD3, 0x2D].pack("C*")
      end

      # ---- Tag table + tagged elements ----

      # Returns a Hash of { tag_signature => tag_bytes } in the
      # order they should appear after the tag table.
      def build_srgb_tags
        {
          "desc" => desc_tag_bytes("sRGB by pdfrb"),
          "wtpt" => xyz_tag_bytes(d50_xyz),
          "rXYZ" => xyz_tag_bytes(srgb_r_xyz),
          "gXYZ" => xyz_tag_bytes(srgb_g_xyz),
          "bXYZ" => xyz_tag_bytes(srgb_b_xyz),
          "rTRC" => curve_tag_bytes,
          "gTRC" => curve_tag_bytes,
          "bTRC" => curve_tag_bytes,
        }
      end

      def build_tag_table(tags)
        out = +""
        count = tags.length
        out << [count].pack("N")

        # Compute offsets: tag table is 4 + count*12 bytes; each tag
        # element is appended after the table in order.
        offset = 4 + (count * 12)
        tags.each do |sig, bytes|
          out << sig
          out << [offset].pack("N")
          out << [bytes.bytesize].pack("N")
          offset += bytes.bytesize
        end
        out
      end

      def tags_total_size(tags)
        tags.values.sum(&:bytesize)
      end

      # ---- Tag element builders ----

      # multiLocalizedUnicodeType (mluc) for desc, per ICC.10.13.
      def desc_tag_bytes(text)
        utf16 = text.encode("UTF-16BE").bytes
        body = +""
        body << "mluc"                              # type signature
        body << ([0] * 4).pack("C*")                # reserved
        body << [1].pack("N")                        # number of records
        body << [12].pack("N")                       # record size in bytes
        body << "enUS" # language + country
        body << [utf16.length].pack("N")             # string length in bytes
        body << [28].pack("N")                       # string offset (from tag start)
        body << utf16.pack("C*")
        body
      end

      # XYZType for colorants and white points, per ICC.10.22.
      def xyz_tag_bytes(xyz_triplet)
        body = +""
        body << "XYZ "                              # type signature
        body << ([0] * 4).pack("C*")                # reserved
        xyz_triplet.each { |v| body << s15fixed16(v) }
        body
      end

      # curveType with a single gamma value, per ICC.10.16.
      # 2.2 is the canonical sRGB approximation (real sRGB uses a
      # piecewise curve, but a single 2.2 gamma is acceptable for
      # most rendering).
      def curve_tag_bytes
        body = +""
        body << "curv"                              # type signature
        body << ([0] * 4).pack("C*")                # reserved
        body << [0].pack("N") # count = 0 → gamma follows in u8Fixed8
        body << u8fixed8(2.2)
        body
      end

      # Encode a Float as ICC s15Fixed16 (signed 16.16).
      def s15fixed16(value)
        v = (value * 65536.0).round.to_i
        [v].pack("N")
      end

      # Encode a Float as ICC u8Fixed8 (unsigned 8.8).
      def u8fixed8(value)
        v = (value * 256.0).round.to_i
        [v].pack("n")
      end

      # ---- sRGB colorants (D50-adapted, per ICC.1:2022 Annex A) ----

      def d50_xyz
        [0.9642, 1.0000, 0.8249]
      end

      def srgb_r_xyz
        [0.4360, 0.2225, 0.0139]
      end

      def srgb_g_xyz
        [0.3851, 0.7169, 0.0971]
      end

      def srgb_b_xyz
        [0.1431, 0.0606, 0.7141]
      end

      # ---- Profile ID (MD5) ----

      # Patch the Profile ID (offset 84..99) with the MD5 of the
      # profile bytes computed with the ID slot zeroed (per ICC.1
      # §7.1.1).
      def patch_profile_id(profile)
        copy = profile.b
        copy[84, 16] = ([0] * 16).pack("C*")
        md5 = Digest::MD5.digest(copy)
        copy[84, 16] = md5
        copy
      end
    end
  end
end
