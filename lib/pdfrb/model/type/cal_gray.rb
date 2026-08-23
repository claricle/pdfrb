# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # CalGray color space dictionary (s8.6.3.2). Single-component
      # calibrated grayscale: [/CalGray <dict>].
      class CalGray < Pdfrb::Model::Cos::Dictionary
        arlington_object "CalGrayDict"
        def white_point; self[:WhitePoint]; end
        def black_point; self[:BlackPoint]; end
        def gamma; self[:Gamma] || 1.0; end

        def components; 1; end
      end
    end
  end
end
