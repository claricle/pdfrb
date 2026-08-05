# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # CID-keyed font (s9.7.3). Inner font of a /Type0 composite.
      # /Subtype /CIDFontType0 or /CIDFontType2.
      class CIDFont < Pdfrb::Model::Type::Font
        arlington_object "FontCIDType0"

        def cid_subtype; self[:Subtype]; end
        def base_font; self[:BaseFont]; end
        def cid_system_info; self[:CIDSystemInfo]; end
        def font_descriptor; self[:FontDescriptor]; end
        def dw; self[:DW]; end
        def w; self[:W]; end
        def dw2; self[:DW2]; end
        def w2; self[:W2]; end
        def cid_to_gid_map; self[:CIDToGIDMap]; end

        def type0?
          cid_subtype&.to_sym == :CIDFontType0
        end

        def type2?
          cid_subtype&.to_sym == :CIDFontType2
        end

        def default_width
          dw || 1000
        end

        def width_for_cid(cid)
          return default_width unless w

          entries = w.is_a?(Pdfrb::Model::PdfArray) ? w.to_a : w
          i = 0
          while i < entries.size
            first = entries[i]
            second = entries[i + 1]
            return nil unless first && second

            case second.to_s
            when /\A[\[\]]\z/
              array = entries[i + 2]
              return nil unless first.is_a?(Integer) && array.is_a?(Array)

              offset = cid - first
              return array[offset] if offset >= 0 && offset < array.size

            else
              value = entries[i + 2]
              return value if cid.between?(first, second)

            end
            i += 3
          end

          default_width
        end
      end
    end
  end
end
