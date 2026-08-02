# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # Type0 (composite) font (s9.7). Outer font that wraps a CIDFont.
      class FontType0 < Pdfrb::Model::Cos::Dictionary
        arlington_object "FontType0"
      end
    end
  end
end
