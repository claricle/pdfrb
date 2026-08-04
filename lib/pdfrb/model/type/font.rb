# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      class Font < Pdfrb::Model::Cos::Dictionary
        arlington_object "FontMap"

        def subtype; self[:Subtype]; end
        def base_font; self[:BaseFont]; end
        def encoding; self[:Encoding]; end
        def first_char; self[:FirstChar]; end
        def last_char; self[:LastChar]; end
        def widths; self[:Widths]; end
        def to_unicode; self[:ToUnicode]; end

        def font_descriptor
          ref = self[:FontDescriptor]
          return nil unless ref
          document ? document.object(ref) : ref
        end

        def embedded?
          fd = font_descriptor
          return false unless fd

          !!(fd.value[:FontFile] || fd.value[:FontFile2] || fd.value[:FontFile3])
        end

        def font_file
          fd = font_descriptor
          return nil unless fd

          fd.value[:FontFile2] || fd.value[:FontFile3] || fd.value[:FontFile]
        end

        def simple?
          [:Type1, :TrueType, :MMType1].include?(subtype&.to_sym)
        end

        def cid?
          subtype&.to_sym == :Type0
        end

        def type3?
          subtype&.to_sym == :Type3
        end

        def descendant_font
          return nil unless cid?

          ref = self[:DescendantFonts]
          return nil unless ref

          arr = ref.is_a?(Pdfrb::Model::Reference) && document ?
                  document.object(ref) : ref
          return nil unless arr.is_a?(Array) || arr.is_a?(Pdfrb::Model::PdfArray)

          first = arr.is_a?(Pdfrb::Model::PdfArray) ? arr[0] : arr[0]
          return nil unless first

          first.is_a?(Pdfrb::Model::Reference) && document ?
            document.object(first) : first
        end

        def glyph_width(char_code)
          return nil unless widths && first_char && last_char

          idx = char_code - first_char
          return nil if idx < 0 || idx >= widths.length

          widths.is_a?(Pdfrb::Model::PdfArray) ? widths[idx] : widths[idx]
        end
      end
    end
  end
end
