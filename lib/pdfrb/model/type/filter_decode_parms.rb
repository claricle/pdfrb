# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # FlateDecode /DecodeParms dictionary (s7.4.4.3): predictor
      # settings shared with LZWDecode.
      class FlateDecodeParms < Pdfrb::Model::Cos::Dictionary
        arlington_object "FilterFlateDecode"

        def predictor; self[:Predictor] || 1; end
        def colors; self[:Colors] || 1; end
        def bits_per_component; self[:BitsPerComponent] || 8; end
        def columns; self[:Columns] || 1; end

        def png_predictor?; predictor >= 10; end
        def tiff_predictor?; predictor == 2; end
      end

      # LZWDecode /DecodeParms dictionary (s7.4.4.2): adds EarlyChange.
      class LZWDecodeParms < FlateDecodeParms
        arlington_object "FilterLZWDecode"

        def early_change; self[:EarlyChange] || 1; end
      end

      # DCTDecode /DecodeParms dictionary (s7.4.7): color transform.
      class DCTDecodeParms < Pdfrb::Model::Cos::Dictionary
        arlington_object "FilterDCTDecode"

        def color_transform; self[:ColorTransform]; end

        # /ColorTransform 0 = four-component YCCK/CMYK input; 1 (or
        # absent) = three-component YCbCr/RGB.
        def cmyk_input?
          !color_transform.nil? && color_transform.zero?
        end
      end

      # CCITTFaxDecode /DecodeParms dictionary (s7.4.6): Group 3/4
      # facsimile parameters.
      class CCITTFaxDecodeParms < Pdfrb::Model::Cos::Dictionary
        arlington_object "FilterCCITTFaxDecode"

        def k; self[:K]; end
        def end_of_line; self[:EndOfLine]; end
        def encoded_byte_align; self[:EncodedByteAlign]; end
        def columns; self[:Columns] || 1728; end
        def rows; self[:Rows]; end
        def end_of_block; self[:EndOfBlock]; end
        def black_is_one; self[:BlackIs1]; end
        def damaged_rows_before_error; self[:DamagedRowsBeforeError]; end

        def group4?; k&.negative?; end
        def group3_1d?; k&.zero?; end
        def group3_2d?; k&.positive?; end
      end

      # JBIG2Decode /DecodeParms dictionary (s7.4.7): global stream ref.
      class JBIG2DecodeParms < Pdfrb::Model::Cos::Dictionary
        arlington_object "FilterJBIG2Decode"

        def jbig2_globals; self[:JBIG2Globals]; end
      end

      # Crypt /DecodeParms dictionary (s7.6.5.5): names the crypt
      # filter applied to a stream.
      class CryptDecodeParms < Pdfrb::Model::Cos::Dictionary
        arlington_object "FilterCrypt"

        def type; self[:Type]; end
        def name; self[:Name] || :Identity; end
      end
    end
  end
end
