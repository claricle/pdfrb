# frozen_string_literal: true

module Pdfrb
  module Color
    # Validates an ICC profile binary against the structural rules in
    # ICC.1:2022 §7. The validator checks:
    #   * Profile size >= 128 (header) + 4 (tag count)
    #   * 'acsp' signature at offset 36
    #   * Profile version is 2.x, 4.x, or 5.x
    #   * Device class is one of the known classes
    #   * Color space is one of the known spaces
    #   * Tag table offsets don't exceed the file size
    #
    # Returns an Array of Violation strings (empty if valid).
    module ICCValidator
      VALID_VERSIONS = [(2.0..2.99), (4.0..4.99), (5.0..5.99)].freeze
      VALID_DEVICE_CLASSES = %w[
        scnr mntr prtr link spac abst nmcl nkpr
      ].freeze
      VALID_COLOR_SPACES = %w[
        XYZ Lab Luv YCbCr Yxy RGB GRAY HSV HLS CMYK CMY 2CLR 3CLR
        4CLR 5CLR 6CLR 7CLR 8CLR 9CLR ACLR BCLR CCLR DCLR ECLR FCLR
      ].freeze

      module_function

      def validate(profile_bytes)
        violations = []
        unless profile_bytes.is_a?(::String) && profile_bytes.bytesize >= 132
          violations << "ICC profile too small (need >= 132 bytes, got #{profile_bytes&.bytesize})"
          return violations
        end

        unless profile_bytes.byteslice(36, 4) == "acsp"
          violations << "ICC profile signature at offset 36 is not 'acsp'"
        end

        version_hi = profile_bytes.getbyte(8)
        version_lo = profile_bytes.getbyte(9)
        version = (version_hi * 1.0) + (version_lo / 16.0 / 10.0)
        unless VALID_VERSIONS.any? { |range| range.cover?(version) }
          violations << "ICC profile version #{version} not in 2.x/4.x/5.x"
        end

        device_class = profile_bytes.byteslice(12, 4).to_s.strip
        unless VALID_DEVICE_CLASSES.include?(device_class)
          violations << "ICC device class '#{device_class}' is not recognised"
        end

        color_space = profile_bytes.byteslice(16, 4).to_s.strip
        unless VALID_COLOR_SPACES.include?(color_space)
          violations << "ICC color space '#{color_space}' is not recognised"
        end

        # Tag table sanity check
        tag_count = profile_bytes.unpack1("N", offset: 128)
        if tag_count > 256
          violations << "ICC tag count #{tag_count} looks bogus (max 256)"
        end

        violations
      end

      def valid?(profile_bytes)
        validate(profile_bytes).empty?
      end
    end
  end
end
