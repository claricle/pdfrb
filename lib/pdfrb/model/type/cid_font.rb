# frozen_string_literal: true

module Pdfrb
  module Model
    module Type
      # CID-keyed font (s9.7.3). Inner font of a /Type0 composite.
      # /Subtype /CIDFontType0 or /CIDFontType2.
      class CIDFont < Pdfrb::Model::Cos::Dictionary
        arlington_object "FontCIDType0"
      end
    end
  end
end
