# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Base Font dict (s9.6.2). Concrete subclasses: FontType1,
      # FontTrueType, FontType0, CIDFont, FontType3.
      class Font < Pdfrb::Model::Cos::Dictionary
        arlington_object "FontMap"
      end
    end
  end
end
