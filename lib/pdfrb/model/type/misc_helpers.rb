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
        arlington_object "LabRangeArray"
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

      # Gamma array [r g b] inside the CalRGB dict (s8.6.3.3).
      class GammaArray < Pdfrb::Model::PdfArray
        arlington_object "GammaArray"

        def r; self[0]; end
        def g; self[1]; end
        def b; self[2]; end
      end

      # White point [X Y Z] inside Cal dicts (s8.6.3.1).
      class WhitepointArray < Pdfrb::Model::PdfArray
        arlington_object "WhitepointArray"

        def x; self[0]; end
        def y; self[1]; end
        def z; self[2]; end
      end

      # Trailer /ID array [id1 id2] (s7.5.5): two 16-byte strings.
      class TrailerIDArray < Pdfrb::Model::PdfArray
        arlington_object "TrailerIDArray"

        def id1; self[0]; end
        def id2; self[1]; end
      end

      # Visibility expression array (s8.11.4.6):
      # [operator operand*] with operators /And /Or /Not.
      class VisibilityExpressionArray < Pdfrb::Model::PdfArray
        arlington_object "VisibilityExpressionArray"

        def operator; self[0]; end

        def operands
          rest = self[1..] || []
          rest.is_a?(Pdfrb::Model::PdfArray) ? rest.to_a : rest
        end

        def and?; operator == :And; end
        def or?; operator == :Or; end
        def not?; operator == :Not; end
      end

      # FileSpec /RelatedFiles array (s7.11.3.2, deprecation era):
      # alternating file-name strings and file streams.
      class RelatedFilesArray < Pdfrb::Model::PdfArray
        arlington_object "RelatedFilesArray"

        def each_pair
          return enum_for(:each_pair) unless block_given?

          (0...size).step(2) do |i|
            yield self[i], self[i + 1]
          end
        end
      end

      # RichMediaExecute /CMD /A arguments array (s13.6.9.6).
      class RichMediaCommandArray < Pdfrb::Model::PdfArray
        arlington_object "RichMediaCommandArray"
      end

      # UR transform permission name arrays (s7.6.5.9): lists of
      # permitted operation names. One subclass per /Transform
      # parameter entry.
      class URTransformParamArray < Pdfrb::Model::PdfArray
        arlington_object "URTransformParamDocumentArray"
      end

      class URTransformParamAnnotsArray < URTransformParamArray
        arlington_object "URTransformParamAnnotsArray"
      end

      class URTransformParamEFArray < URTransformParamArray
        arlington_object "URTransformParamEFArray"
      end

      class URTransformParamFormArray < URTransformParamArray
        arlington_object "URTransformParamFormArray"
      end

      class URTransformParamSignatureArray < URTransformParamArray
        arlington_object "URTransformParamSignatureArray"
      end

      # Generic catch-all array (Arlington _UniversalArray): any
      # mix of PDF values.
      class UniversalArray < Pdfrb::Model::PdfArray
        arlington_object "_UniversalArray"
      end

      # Generic catch-all dictionary (Arlington _UniversalDictionary).
      class UniversalDictionary < Pdfrb::Model::Cos::Dictionary
        arlington_object "_UniversalDictionary"
      end

      # /OOAdditionalStms array [name stream]* (PDF 1.5 era
      # object-order additional streams).
      class OOAdditionalStmsArray < Pdfrb::Model::PdfArray
        arlington_object "OOAdditionalStmsArray"

        def each_pair
          return enum_for(:each_pair) unless block_given?

          (0...size).step(2) do |i|
            yield self[i], self[i + 1]
          end
        end
      end
    end
  end
end
