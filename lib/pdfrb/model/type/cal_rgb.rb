# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # CalRGB color space dictionary (s8.6.3.3). Calibrated RGB:
      # [/CalRGB <dict>].
      class CalRGB < Pdfrb::Model::Cos::Dictionary
        def white_point; self[:WhitePoint]; end
        def black_point; self[:BlackPoint]; end
        def gamma; self[:Gamma]; end
        def matrix; self[:Matrix]; end

        def components; 3; end

        def has_matrix?
          !!matrix
        end
      end
    end
  end
end
