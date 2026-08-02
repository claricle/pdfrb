# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # TrueType font (s9.6.3). /Subtype /TrueType.
      class FontTrueType < Pdfrb::Model::Cos::Dictionary
        arlington_object "FontTrueType"
      end
    end
  end
end
