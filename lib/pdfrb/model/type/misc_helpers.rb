# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Border array [horizontal_radius vertical_radius width_dash
      # ...]  Deprecated; use BorderStyling instead (s7.7.3.3).
      # Encapsulated as a thin struct.
      class BorderArray < Pdfrb::Model::PdfArray
        def horizontal_radius
          self[0] || 0
        end

        def vertical_radius
          self[1] || 0
        end

        def border_width
          self[2] || 1
        end

        def horizontal_style
          (self[3]&.to_s || :S).to_sym
        end
      end

      # Lab Range Array [a_min a_max b_min b_max]. Used inside the
      # Lab color space dict (s8.6.3.4).
      class LabRangeArray < Pdfrb::Model::PdfArray
        def a_min; self[0]; end
        def a_max; self[1]; end
        def b_min; self[2]; end
        def b_max; self[3]; end

        def default?
          a_min == -100 && a_max == 100 && b_min == -100 && b_max == 100
        end
      end

      # Dest Output Profile Ref (s7.9.6, optional indirect reference).
      # Used by PDF PostScript/XMP reference forms.
      class DestOutputProfileRef < Pdfrb::Model::Reference
        def resolved
          document&.object(self)
        end
      end

      # Output Intents array (s14.11.5). Container for the Catalog
      # /OutputIntents array — convenience wrapper that just forwards
      # to the type.
      class OutputIntentsContainer < Pdfrb::Model::Cos::Dictionary
        def intent_type; self[:S]; end

        def pdfx?
          intent_type&.to_sym == :GTS_PDFX
        end

        def pdfa?
          intent_type&.to_sym == :GTS_PDFA
        end
      end

      # CMapStream (s9.7.5.3). CMap stream definition embedded in a PDF.
      class CMapStream < Pdfrb::Model::Cos::Stream
        def type; self[:Type]; end
        def base_font; self[:BaseFont]; end
        def encoding; self[:Encoding]; end

        def cmap_data
          decoded_stream&.force_encoding(Encoding::BINARY)
        end
      end
    end
  end
end
